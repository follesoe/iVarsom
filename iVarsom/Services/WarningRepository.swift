import Foundation

struct RegionCatalog: Sendable {
    let norway: [RegionSummary]
    let sweden: [RegionSummary]
    let isEntirelyFresh: Bool
    var allRegions: [RegionSummary] { norway + sweden }
}

enum WarningSource: Sendable { case network, cache }

struct LoadedWarnings: Sendable {
    let warnings: [AvalancheWarningDetailed]
    let source: WarningSource
}

enum WarningCachePolicy: Sendable { case networkOnly, fallback }

struct WarningRequest: Sendable {
    let regionID: Int
    let from: Date
    let to: Date
    let historyDays: Int

    init(regionID: Int, from: Date, to: Date, relativeTo date: Date) {
        self.regionID = regionID
        self.from = from
        self.to = to
        let calendar = ForecastSelection.calendar(regionID: regionID)
        historyDays = max(
            0,
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: date)
            ).day ?? 0)
    }

    init(regionID: Int, date: Date, daysBefore: Int, daysAfter: Int) {
        let calendar = ForecastSelection.calendar(regionID: regionID)
        self.init(
            regionID: regionID,
            from: calendar.date(byAdding: .day, value: -max(0, daysBefore), to: date)!,
            to: calendar.date(byAdding: .day, value: daysAfter, to: date)!, relativeTo: date)
    }
}

/// The app, widgets and intents share provider routing while choosing their own
/// cache policy. Presentation models never need to know which country owns an ID.
protocol WarningRepositoryProviding: Sendable {
    func loadRegions() async throws -> RegionCatalog
    func loadWarnings(_ request: WarningRequest, cachePolicy: WarningCachePolicy) async throws -> LoadedWarnings
    func loadSummaries(_ request: WarningRequest) async throws -> [AvalancheWarningSimple]
}

actor WarningRepository: WarningRepositoryProviding {
    private var warningRequests: [Int: UUID] = [:]
    private var regionRequests: [Country: UUID] = [:]
    private let norway: any VarsomAPIProviding
    private let sweden: any LavinprognoserAPIProviding
    private let cache: (any CacheServiceProtocol)?
    private let language: @Sendable () -> VarsomApiClient.Language
    private let sharedForecasts: SharedForecastStore?
    private let now: @Sendable () -> Date

    static func live() -> WarningRepository {
        WarningRepository(sharedForecasts: SharedForecastStore(reloadWidgets: true))
    }

    init(
        norway: any VarsomAPIProviding = VarsomApiClient(),
        sweden: any LavinprognoserAPIProviding = LavinprognoserApiClient(),
        cache: (any CacheServiceProtocol)? = CacheService(),
        language: @escaping @Sendable () -> VarsomApiClient.Language = VarsomApiClient.currentLang,
        sharedForecasts: SharedForecastStore? = nil,
        now: @escaping @Sendable () -> Date = { Date.current }
    ) {
        self.norway = norway
        self.sweden = sweden
        self.cache = cache
        self.language = language
        self.sharedForecasts = sharedForecasts
        self.now = now
    }

    func loadRegions() async throws -> RegionCatalog {
        try Task.checkCancellation()
        async let norwegian = loadRegions(country: .norway)
        async let swedish = loadRegions(country: .sweden)
        let (n, s) = try await (norwegian, swedish)
        try Task.checkCancellation()
        guard n.regions != nil || s.regions != nil else { throw RepositoryError.unavailable }
        return RegionCatalog(
            norway: n.regions ?? [], sweden: s.regions ?? [],
            isEntirelyFresh: n.fresh && s.fresh)
    }

    private func loadRegions(country: Country) async throws -> (regions: [RegionSummary]?, fresh: Bool) {
        let requestID = UUID()
        regionRequests[country] = requestID
        do {
            let regions: [RegionSummary]
            switch country {
            case .norway: regions = try await norway.loadRegions(lang: language()).filter { $0.TypeName == "A" }
            case .sweden: regions = try await sweden.loadRegions()
            }
            try Task.checkCancellation()
            if regionRequests[country] == requestID { await cache?.saveRegions(regions, country: country) }
            return (regions, true)
        } catch {
            try error.rethrowCancellation()
            let regions = await cache?.loadRegions(country: country)
            try Task.checkCancellation()
            return (regions, false)
        }
    }

    func loadWarnings(_ request: WarningRequest, cachePolicy: WarningCachePolicy = .fallback) async throws
        -> LoadedWarnings
    {
        try Task.checkCancellation()
        let requestID = UUID()
        warningRequests[request.regionID] = requestID
        let started = now()
        let requestLanguage = language()
        do {
            let warnings: [AvalancheWarningDetailed]
            switch Country.from(regionId: request.regionID) {
            case .norway:
                warnings = try await norway.loadWarningsDetailed(
                    lang: requestLanguage, regionId: request.regionID,
                    from: request.from, to: request.to)
            case .sweden:
                warnings = try await sweden.loadWarningsDetailed(
                    regionId: request.regionID, daysBefore: request.historyDays)
            }
            try Task.checkCancellation()
            if cachePolicy == .fallback, warningRequests[request.regionID] == requestID {
                await cache?.saveWarningsDetailed(warnings, regionId: request.regionID)
            }
            if warningRequests[request.regionID] == requestID {
                await sharedForecasts?.save(ForecastSnapshot(
                    regionID: request.regionID,
                    language: SharedForecastStore.languageKey(regionID: request.regionID, language: requestLanguage),
                    requestStartedAt: started, downloadedAt: now(), warnings: warnings.map(\.summary)))
            }
            return LoadedWarnings(warnings: warnings.sorted { $0.ValidFrom < $1.ValidFrom }, source: .network)
        } catch {
            try error.rethrowCancellation()
            if cachePolicy == .fallback,
                let warnings = await cache?.loadWarningsDetailed(regionId: request.regionID), !warnings.isEmpty
            {
                try Task.checkCancellation()
                return LoadedWarnings(warnings: warnings.sorted { $0.ValidFrom < $1.ValidFrom }, source: .cache)
            }
            throw error
        }
    }

    /// Lightweight summaries for Siri and local-region lookup. Widgets use detailed
    /// warnings so emergency text survives conversion to their compact display model.
    func loadSummaries(_ request: WarningRequest) async throws -> [AvalancheWarningSimple] {
        let warnings: [AvalancheWarningSimple]
        switch Country.from(regionId: request.regionID) {
        case .norway:
            warnings = try await norway.loadWarnings(
                lang: language(), regionId: request.regionID,
                from: request.from, to: request.to)
        case .sweden:
            warnings = try await sweden.loadWarnings(
                regionId: request.regionID, daysBefore: max(1, request.historyDays))
        }
        try Task.checkCancellation()
        return warnings.sorted { $0.ValidFrom < $1.ValidFrom }
    }

    enum RepositoryError: Error { case unavailable }
}

extension Error {
    func rethrowCancellation() throws {
        try Task.checkCancellation()
        if self is CancellationError || (self as? URLError)?.code == .cancelled { throw CancellationError() }
    }
}
