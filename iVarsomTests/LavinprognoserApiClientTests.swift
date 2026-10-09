import Foundation
import Testing
@testable import Skredvarsel

struct LavinprognoserApiClientTests {
    @Test func mapsOverviewAndIgnoresNonRegionLinks() async throws {
        let transport = StubTransport { _ in
            Data(#"{"content":{"areaPageLinksArea":{"areaPageLinks":[{"areaName":"Abisko","areaId":1,"risk":3,"url":"/abisko","riskText":"Warning"},{"areaName":"Other","areaId":0,"risk":0,"url":"/"}]}}}"#.utf8)
        }
        let regions = try await LavinprognoserApiClient(transport: transport).loadRegions()
        #expect(regions.count == 1)
        #expect(regions.first?.Id == Country.syntheticId(from: 1))
        #expect(regions.first?.AvalancheWarningList.first?.DangerLevel == .level3)
    }

    @Test func missingHistoricalDayDoesNotDiscardCurrentForecast() async throws {
        let date = Date(year: 2026, month: 2, day: 21, hour: 12)
        let transport = StubTransport { request in
            guard request.url?.query?.contains("2026-02-21") == true else { throw TestFailure.offline }
            return Data(#"{"content":{"forecast":{"id":123,"risk":3,"areaId":1,"validFrom":"Friday 20/02-2026 18:00","validTo":"Saturday 21/02-2026 18:00","publishedDate":"2026-02-20","location":"Abisko","assessmentContent":"<p>Wind &amp; snow</p><script>hidden</script>"}}}"#.utf8)
        }
        let warnings = try await LavinprognoserApiClient(transport: transport, now: { date })
            .loadWarningsDetailed(regionId: 100001, daysBefore: 2)
        #expect(warnings.count == 1)
        #expect(warnings.first?.MainText == "Wind & snow")
        #expect(warnings.first?.DangerLevel == .level3)
        #expect(await transport.requests.count == 3)
    }

    @Test func cancellationIsNotConvertedToMissingForecast() async {
        let client = LavinprognoserApiClient(transport: StubTransport { _ in throw CancellationError() })
        await #expect(throws: CancellationError.self) { try await client.loadWarningsDetailed(regionId: 100001, daysBefore: 2) }
    }

    @Test func negativeHistoryDoesNotCreateInvalidRange() async {
        let transport = StubTransport { _ in throw TestFailure.offline }
        let client = LavinprognoserApiClient(transport: transport)
        await #expect(throws: LavinprognoserApiClient.LavinError.requestError) {
            try await client.loadWarningsDetailed(regionId: 100001, daysBefore: -3)
        }
        #expect(await transport.requests.count == 1)
    }
}
