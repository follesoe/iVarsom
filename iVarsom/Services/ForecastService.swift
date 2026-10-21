import Foundation

enum ForecastError: Error, LocalizedError {
    case invalidRegion, locationRequired, locationUnavailable, unavailable, noForecast, noFavorites

    /// The `Localizable.strings` key of the description.
    var key: String {
        switch self {
        case .invalidRegion: "Region unavailable"
        case .locationRequired: "Location access required"
        case .locationUnavailable: "Location unavailable"
        case .unavailable: "Service unavailable"
        case .noForecast: "No forecast available for this day"
        case .noFavorites: "Add a favorite region in the app first."
        }
    }

    var errorDescription: String? { Bundle.main.localizedString(forKey: key, value: nil, table: nil) }
}

struct LoadedForecast: Sendable {
    let snapshot: ForecastSnapshot
    let isCached: Bool
}

/// Shared by widgets and Shortcuts. Never falls back to a different region or
/// language, and leaves validity selection to the consumer.
actor ForecastService {
    private let repository: any WarningRepositoryProviding
    private let store: SharedForecastStore
    private let now: @Sendable () -> Date
    private let language: @Sendable () -> VarsomApiClient.Language

    init(repository: any WarningRepositoryProviding = WarningRepository(cache: nil),
         store: SharedForecastStore = SharedForecastStore(),
         now: @escaping @Sendable () -> Date = { Date.current },
         language: @escaping @Sendable () -> VarsomApiClient.Language = VarsomApiClient.currentLang) {
        self.repository = repository
        self.store = store
        self.now = now
        self.language = language
    }

    func load(regionID: Int, forceRefresh: Bool = false) async throws -> LoadedForecast {
        try Task.checkCancellation()
        guard (RegionOption.aRegions + RegionOption.swedenRegions).contains(where: { $0.id == regionID }) else {
            throw ForecastError.invalidRegion
        }
        let started = now()
        let key = SharedForecastStore.languageKey(regionID: regionID, language: language())
        if !forceRefresh, let snapshot = await store.load(regionID: regionID, language: key, now: started),
           started < ForecastRefreshPolicy.nextRefresh(warnings: snapshot.warnings, downloadedAt: snapshot.downloadedAt) {
            try Task.checkCancellation()
            return LoadedForecast(snapshot: snapshot, isCached: false)
        }
        do {
            let request = WarningRequest(regionID: regionID, date: started, daysBefore: 3, daysAfter: 2)
            let loaded = try await repository.loadWarnings(request, cachePolicy: .networkOnly)
            try Task.checkCancellation()
            let snapshot = ForecastSnapshot(regionID: regionID, language: key, requestStartedAt: started,
                downloadedAt: now(), warnings: loaded.warnings.map(\.summary))
            let accepted = await store.save(snapshot)
            return LoadedForecast(snapshot: accepted, isCached: false)
        } catch {
            try error.rethrowCancellation()
            if let snapshot = await store.load(regionID: regionID, language: key, now: now()) {
                try Task.checkCancellation()
                return LoadedForecast(snapshot: snapshot, isCached: true)
            }
            throw ForecastError.unavailable
        }
    }
}

enum ForecastRegionResolver {
    @MainActor
    static func resolve(_ regionID: Int, requestPermission: Bool = false) async throws -> Int {
        guard regionID == RegionOption.currentPositionOption.id else {
            guard (RegionOption.aRegions + RegionOption.swedenRegions).contains(where: { $0.id == regionID }) else {
                throw ForecastError.invalidRegion
            }
            return regionID
        }
        let manager = LocationManager()
        let authorized = try await (requestPermission ? manager.checkAuthorization() : manager.checkWidgetAuthorization())
        guard authorized else { throw ForecastError.locationRequired }
        guard let location = try await manager.updateLocation(),
              let feature = RegionGeoData.load()?.findNearestRegion(at: location) else {
            throw ForecastError.locationUnavailable
        }
        return feature.id
    }
}
