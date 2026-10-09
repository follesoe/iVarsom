import Foundation
import Testing
import CoreLocation
@testable import Skredvarsel

struct VarsomApiClientTests {
    @Test func decodesDetailedWarningsAndBuildsRequest() async throws {
        let body = try Fixtures.json([Fixtures.warning()])
        let transport = StubTransport { _ in body }
        let client = VarsomApiClient(transport: transport)
        let warnings = try await client.loadWarningsDetailed(lang: .english, regionId: 3003, from: Fixtures.date, to: Fixtures.date)
        #expect(warnings.count == 1)
        #expect(warnings.first?.DangerLevel == .level3)
        #expect(warnings.first?.ValidFrom == Fixtures.date)
        let request = try #require(await transport.requests.first)
        #expect(request.url?.path.contains("/AvalancheWarningByRegion/Detail/3003/2/") == true)
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test func synthesizesUniqueIDsWithoutCollidingWithRealIDs() async throws {
        var first = Fixtures.warning(); first.RegId = 0
        var second = Fixtures.warning(); second.RegId = 0
        var existing = Fixtures.warning(); existing.RegId = 3004
        let body = try Fixtures.json([first, second, existing])
        let client = VarsomApiClient(transport: StubTransport { _ in body })
        let warnings = try await client.loadWarningsDetailed(lang: .english, regionId: 3003, from: Fixtures.date, to: Fixtures.date)
        #expect(Set(warnings.map(\.RegId)).count == 3)
        #expect(warnings.last?.RegId == 3004)
        #expect(warnings.allSatisfy { $0.RegId > 0 })
    }

    @Test func emptyCoordinateResponseThrowsInsteadOfCrashing() async {
        let client = VarsomApiClient(transport: StubTransport { _ in Data("[]".utf8) })
        await #expect(throws: VarsomApiClient.VarsomError.noWarnings) {
            try await client.loadRegions(lang: .english, coordinate: CLLocationCoordinate2D(latitude: 69, longitude: 18))
        }
    }

    @Test(arguments: [404, 500, 503]) func httpErrors(status: Int) async {
        let client = VarsomApiClient(transport: StubTransport(status: status) { _ in Data("[]".utf8) })
        await #expect(throws: VarsomApiClient.VarsomError.requestError) { try await client.loadRegions(lang: .english) }
    }

    @Test func malformedJSONThrows() async {
        let client = VarsomApiClient(transport: StubTransport { _ in Data("not json".utf8) })
        await #expect(throws: DecodingError.self) { try await client.loadRegions(lang: .english) }
    }

    @Test func emptyForecastIsValid() async throws {
        let client = VarsomApiClient(transport: StubTransport { _ in Data("[]".utf8) })
        let warnings = try await client.loadWarnings(lang: .norwegian, regionId: 3003, from: Fixtures.date, to: Fixtures.date)
        #expect(warnings.isEmpty)
    }

    @Test(arguments: ["2026-10-09T12:00:00", "2026-10-09T12:00:00.123"])
    func acceptsVarsomDateFormats(value: String) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .varsomDate
        let date = try decoder.decode(Date.self, from: Data("\"\(value)\"".utf8))
        #expect(date.timeIntervalSince1970 > 0)
    }
}

struct WarningSelectionTests {
    @Test func emptyResponseHasNoCurrentWarning() {
        let warnings: [AvalancheWarningDetailed] = []
        #expect(warnings.currentWarningIndex(on: Fixtures.date) == nil)
    }

    @Test func prefersTodayOverFirstOrLatest() {
        let warnings = [Fixtures.warning(date: Fixtures.date.addingTimeInterval(-86400)),
                        Fixtures.warning(), Fixtures.warning(date: Fixtures.date.addingTimeInterval(86400))]
        #expect(warnings.currentWarningIndex(on: Fixtures.date) == 1)
    }

    @Test func latestFallbackDoesNotDependOnResponseOrder() {
        let warnings = [Fixtures.warning(date: Fixtures.date.addingTimeInterval(86400)),
                        Fixtures.warning(date: Fixtures.date.addingTimeInterval(-86400))]
        #expect(warnings.currentWarningIndex(on: Fixtures.date) == 0)
    }
}
