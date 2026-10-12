import Foundation
import Observation

@Observable
@MainActor
final class RegionLocationModel {
    private(set) var isAuthorized: Bool
    private(set) var coordinate: Location2D?
    private(set) var region: RegionSummary?
    private let manager: any LocationProviding
    private let repository: any WarningRepositoryProviding
    private let now: () -> Date
    @ObservationIgnored private var requestID = UUID()

    init(
        manager: any LocationProviding = LocationManager(), repository: any WarningRepositoryProviding,
        now: @escaping () -> Date = { Date.current }
    ) {
        self.manager = manager
        self.repository = repository
        self.now = now
        isAuthorized = manager.isAuthorized
    }

    /// Navigation consumes its own result. A concurrent presentation refresh
    /// must not supersede it or make it read another request's location state.
    func regionIDForNavigation() async throws -> Int {
        guard try await manager.requestPermission() else { throw ForecastError.locationRequired }
        try Task.checkCancellation()
        guard let coordinate = try await manager.updateLocation(),
              let feature = RegionGeoData.load()?.findNearestRegion(at: coordinate) else {
            throw ForecastError.locationUnavailable
        }
        try Task.checkCancellation()
        return feature.id
    }

    func refresh(regions: [RegionSummary], requestPermission: Bool = false) async {
        let request = UUID()
        requestID = request
        do {
            let authorized = try await (requestPermission ? manager.requestPermission() : manager.checkAuthorization())
            try Task.checkCancellation()
            guard requestID == request else { return }
            isAuthorized = authorized
            guard authorized else {
                coordinate = nil
                region = nil
                return
            }
            guard let location = try await manager.updateLocation() else { return }
            try Task.checkCancellation()
            guard requestID == request else { return }
            coordinate = location
            guard let feature = RegionGeoData.load()?.findNearestRegion(at: location) else { return }
            if let knownRegion = regions.first(where: { $0.id == feature.id }) {
                region = knownRegion
                return
            }
            let warnings = try await repository.loadSummaries(
                WarningRequest(regionID: feature.id, date: now(), daysBefore: 0, daysAfter: 2))
            try Task.checkCancellation()
            guard requestID == request else { return }
            region = RegionSummary(Id: feature.id, Name: feature.name, TypeName: "A", AvalancheWarningList: warnings)
        } catch { /* Optional location failures preserve the last known region. */  }
    }
}
