import Foundation
import Testing

@testable import Skredvarsel

@MainActor
struct WarningRepositoryTests {
    private let norway = StubNorwayClient()
    private let sweden = StubSwedenClient()
    private let directory = TemporaryDirectory()
    private var query: WarningRequest {
        WarningRequest(regionID: 3003, date: Fixtures.date, daysBefore: 1, daysAfter: 2)
    }

    @Test func networkOnlyDoesNotReadOrOverwriteAppCache() async throws {
        let cache = CacheService(directory: directory.url)
        let cached = Fixtures.warning(danger: .level2)
        await cache.saveWarningsDetailed([cached], regionId: 3003)
        let repository = WarningRepository(norway: norway, sweden: sweden, cache: cache)
        let loaded = try await repository.loadWarnings(query, cachePolicy: .networkOnly)
        #expect(loaded.source == .network)
        #expect(await cache.loadWarningsDetailed(regionId: 3003)?.first?.DangerLevel == .level2)
        norway.detailed = { _ in throw TestFailure.offline }
        await #expect(throws: TestFailure.self) { try await repository.loadWarnings(query, cachePolicy: .networkOnly) }
    }

    @Test func olderSameRegionResponseCannotReplaceNewCache() async throws {
        let gate = WarningGate()
        norway.detailed = { _ in try await gate.load() }
        let cache = CacheService(directory: directory.url)
        let repository = WarningRepository(norway: norway, sweden: sweden, cache: cache)
        let first = Task { try await repository.loadWarnings(query) }
        await gate.waitUntilStarted()
        norway.detailed = { _ in [Fixtures.warning(danger: .level4)] }
        _ = try await repository.loadWarnings(query)
        gate.finish(.success([Fixtures.warning(danger: .level2)]))
        _ = try await first.value
        #expect(await cache.loadWarningsDetailed(regionId: 3003)?.first?.DangerLevel == .level4)
    }

    @Test(arguments: [3003, 100001]) func summaryRequestsRouteToCorrectProvider(regionID: Int) async throws {
        let repository = WarningRepository(norway: norway, sweden: sweden, cache: nil)
        let request = WarningRequest(regionID: regionID, date: Fixtures.date, daysBefore: 0, daysAfter: 0)
        let warnings = try await repository.loadSummaries(request)
        #expect(warnings.first?.RegionId == regionID)
        if regionID == 3003 {
            #expect(norway.summaryRegionID == regionID)
            #expect(sweden.summaryRegionID == nil)
        } else {
            #expect(sweden.summaryRegionID == regionID)
            #expect(sweden.requestedDaysBefore == 1)
            #expect(norway.summaryRegionID == nil)
        }
    }

    @Test func summaryConversionPreservesEmergencyWarning() {
        var warning = Fixtures.warning()
        warning.EmergencyWarning = "Emergency bulletin"
        let summary = warning.summary
        #expect(summary.EmergencyWarning == warning.EmergencyWarning)
        #expect(summary.ValidFrom == warning.ValidFrom)
        #expect(summary.RegId == warning.RegId)
    }

    @Test func historyUsesCalendarDaysAcrossDaylightSavingChange() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 12))!
        let request = WarningRequest(regionID: 100001, date: date, daysBefore: 3, daysAfter: 2)
        #expect(request.historyDays == 3)
        #expect(calendar.dateComponents([.day], from: request.from, to: request.to).day == 5)
    }
}
