import CoreLocation
import Foundation

@testable import Skredvarsel

enum TestFailure: Error { case offline }

enum Fixtures {
    static let date = Date(timeIntervalSince1970: 1_791_504_000)

    static func region(_ id: Int = 3003, name: String = "Test Region") -> RegionSummary {
        RegionSummary(Id: id, Name: name, TypeName: "A", AvalancheWarningList: [])
    }

    static func warning(_ id: Int = 3003, date: Date = date, danger: DangerLevel = .level3) -> AvalancheWarningDetailed
    {
        AvalancheWarningDetailed(
            PreviousWarningRegId: nil, DangerLevelName: nil, UtmZone: 33, UtmEast: 0, UtmNorth: 0,
            Author: nil, AvalancheDanger: nil, EmergencyWarning: nil, SnowSurface: nil,
            CurrentWeaklayers: nil, LatestAvalancheActivity: nil, LatestObservations: nil,
            ExposedHeightFill: 0, ExposedHeight1: 0, AvalancheProblems: nil, AvalancheAdvices: nil,
            RegId: id, RegionId: id, RegionName: "Test Region", RegionTypeId: 10, RegionTypeName: "A",
            DangerLevel: danger, ValidFrom: date, ValidTo: date.addingTimeInterval(86400),
            NextWarningTime: date.addingTimeInterval(86400), PublishTime: date, MainText: "Test warning", LangKey: 1)
    }

    static func json<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Formatter.varsomDate)
        return try encoder.encode(value)
    }

    static func varsomAPIJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Formatter.varsomAPIDate)
        return try encoder.encode(value)
    }
}

final class TemporaryDirectory: Sendable {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    deinit { try? FileManager.default.removeItem(at: url) }
}

@MainActor
final class TestPreferences {
    let name = "iVarsom.tests.\(UUID().uuidString)"
    let defaults: UserDefaults
    init() { defaults = UserDefaults(suiteName: name)! }
    isolated deinit { defaults.removePersistentDomain(forName: name) }
    func favorites() -> FavoritesService {
        FavoritesService(defaults: defaults, cloudStore: nil, migrateLegacyDefaults: false)
    }
}

actor StubTransport: HTTPTransport {
    private(set) var requests: [URLRequest] = []
    let status: Int
    let body: @Sendable (URLRequest) throws -> Data

    init(status: Int = 200, body: @escaping @Sendable (URLRequest) throws -> Data) {
        self.status = status
        self.body = body
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        return (
            try body(request),
            HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        )
    }
}

@MainActor
final class StubNorwayClient: VarsomAPIProviding {
    var regions: Result<[RegionSummary], any Error> = .success([Fixtures.region()])
    var onLoadRegions: (() async throws -> [RegionSummary])?
    var detailed: (Int) async throws -> [AvalancheWarningDetailed] = { [Fixtures.warning($0)] }
    private(set) var regionRequests = 0
    func loadRegions(lang: VarsomApiClient.Language) async throws -> [RegionSummary] {
        regionRequests += 1
        if let onLoadRegions { return try await onLoadRegions() }
        return try regions.get()
    }
    private(set) var summaryRegionID: Int?
    func loadWarnings(lang: VarsomApiClient.Language, regionId: Int, from: Date, to: Date) async throws
        -> [AvalancheWarningSimple]
    {
        summaryRegionID = regionId
        return [Fixtures.warning(regionId).summary]
    }
    func loadWarningsDetailed(lang: VarsomApiClient.Language, regionId: Int, from: Date, to: Date) async throws
        -> [AvalancheWarningDetailed]
    {
        try await detailed(regionId)
    }
}

@MainActor
final class StubSwedenClient: LavinprognoserAPIProviding {
    var regions: Result<[RegionSummary], any Error> = .success([Fixtures.region(100001)])
    private(set) var requestedDaysBefore: Int?
    private(set) var regionRequests = 0
    func loadRegions() async throws -> [RegionSummary] {
        regionRequests += 1
        return try regions.get()
    }
    private(set) var summaryRegionID: Int?
    func loadWarnings(regionId: Int, daysBefore: Int) async throws -> [AvalancheWarningSimple] {
        summaryRegionID = regionId
        requestedDaysBefore = daysBefore
        return [Fixtures.warning(regionId).summary]
    }
    func loadWarningsDetailed(regionId: Int, daysBefore: Int) async throws -> [AvalancheWarningDetailed] {
        requestedDaysBefore = daysBefore
        return [Fixtures.warning(regionId)]
    }
}

@MainActor
final class StubLocation: LocationProviding {
    var isAuthorized = false
    var coordinate: Location2D?
    var onUpdateLocation: (() async throws -> Location2D?)?
    private(set) var locationRequests = 0
    func checkAuthorization() async throws -> Bool { isAuthorized }
    func requestPermission() async throws -> Bool { isAuthorized }
    func updateLocation() async throws -> Location2D? {
        locationRequests += 1
        if let onUpdateLocation { return try await onUpdateLocation() }
        return coordinate
    }
}

/// Deterministically suspend a request, including one that ignores cancellation.
@MainActor
final class WarningGate {
    private var started = false
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var continuation: CheckedContinuation<[AvalancheWarningDetailed], any Error>?

    func load() async throws -> [AvalancheWarningDetailed] {
        try await withCheckedThrowingContinuation {
            continuation = $0
            started = true
            startedContinuation?.resume()
            startedContinuation = nil
        }
    }
    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { startedContinuation = $0 }
    }
    func finish(_ result: Result<[AvalancheWarningDetailed], any Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
