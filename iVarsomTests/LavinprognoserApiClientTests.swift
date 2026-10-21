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
            guard request.url?.query == nil || request.url?.query?.contains("2026-02-21") == true else { throw TestFailure.offline }
            return Data(#"{"content":{"forecast":{"id":123,"risk":3,"areaId":1,"validFrom":"Friday 20/02-2026 18:00","validTo":"Saturday 21/02-2026 18:00","publishedDate":"2026-02-20","location":"Abisko","assessmentContent":"<p>Wind &amp; snow</p><script>hidden</script>"}}}"#.utf8)
        }
        let warnings = try await LavinprognoserApiClient(transport: transport, now: { date })
            .loadWarningsDetailed(regionId: 100001, daysBefore: 2)
        #expect(warnings.count == 1)
        #expect(warnings.first?.MainText == "Wind & snow")
        #expect(warnings.first?.DangerLevel == .level3)
        #expect(await transport.requests.count == 4)
    }

    /// Siri can ask in a different language from the app's (iOS 27).
    @Test(arguments: [(VarsomApiClient.Language.english, "/en/current-avalanche-bulletins/"),
                      (.norwegian, "/oversikt-alla-omraden/")])
    func requestedLanguageSelectsBulletinEndpoint(lang: VarsomApiClient.Language, path: String) async throws {
        let date = Date(year: 2026, month: 2, day: 21, hour: 12)
        let transport = StubTransport { _ in
            Data(#"{"content":{"forecast":{"id":123,"risk":3,"areaId":1,"validFrom":"Friday 20/02-2026 18:00","validTo":"Saturday 21/02-2026 18:00","publishedDate":"2026-02-20","location":"Abisko","assessmentContent":"<p>Text</p>"}}}"#.utf8)
        }
        _ = try await LavinprognoserApiClient(transport: transport, now: { date })
            .loadWarningsDetailed(lang: lang, regionId: 100001, daysBefore: 0)
        let urls = await transport.requests.compactMap { $0.url?.absoluteString }
        #expect(!urls.isEmpty)
        #expect(urls.allSatisfy { $0.contains(path) })
    }

    @Test func cancellationIsNotConvertedToMissingForecast() async {
        let client = LavinprognoserApiClient(transport: StubTransport { _ in throw CancellationError() })
        await #expect(throws: CancellationError.self) { try await client.loadWarningsDetailed(regionId: 100001, daysBefore: 2) }
    }

    @Test func negativeHistoryDoesNotCreateInvalidRange() async {
        let transport = StubTransport { _ in throw TestFailure.offline }
        let client = LavinprognoserApiClient(transport: transport)
        await #expect(throws: TestFailure.offline) {
            try await client.loadWarningsDetailed(regionId: 100001, daysBefore: -3)
        }
        #expect(await transport.requests.count == 2)
    }

    @Test func activeForecastFailureIsNotHiddenBySuccessfulHistory() async {
        let date = ForecastSelection.calendar(regionID: 100001).date(from: DateComponents(year: 2026, month: 2, day: 21, hour: 19))!
        let transport = StubTransport { request in
            guard request.url?.query != nil else { throw TestFailure.offline }
            return Data(#"{"content":{"forecast":{"id":123,"risk":3,"areaId":1,"validFrom":"Friday 20/02-2026 18:00","validTo":"Saturday 21/02-2026 18:00","publishedDate":"2026-02-20","location":"Abisko"}}}"#.utf8)
        }
        let client = LavinprognoserApiClient(transport: transport, now: { date })
        await #expect(throws: TestFailure.offline) {
            try await client.loadWarningsDetailed(regionId: 100001, daysBefore: 2)
        }
    }

    @Test func eveningForecastIncludesTomorrowAndDeduplicatesCurrentDay() async throws {
        let date = ForecastSelection.calendar(regionID: 100001).date(from: DateComponents(year: 2026, month: 2, day: 21, hour: 19))!
        let transport = StubTransport { request in
            let tomorrow = request.url?.query == nil
            let id = tomorrow ? 124 : 123
            let from = tomorrow ? "Saturday 21/02-2026 18:00" : "Friday 20/02-2026 18:00"
            let to = tomorrow ? "Sunday 22/02-2026 18:00" : "Saturday 21/02-2026 18:00"
            return try JSONSerialization.data(withJSONObject: ["content": ["forecast": [
                "id": id, "risk": 3, "areaId": 1, "validFrom": from, "validTo": to,
                "publishedDate": "2026-02-21", "location": "Abisko"
            ]]])
        }
        let warnings = try await LavinprognoserApiClient(transport: transport, now: { date })
            .loadWarningsDetailed(regionId: 100001, daysBefore: 2)
        #expect(warnings.count == 2)
        #expect(ForecastSelection.warning(in: warnings.map(\.summary), day: .today, at: date)?.RegId == 100125)
        #expect(ForecastSelection.warning(in: warnings.map(\.summary), day: .tomorrow, at: date)?.RegId == 100125)
    }

    /// Days without a bulletin, such as before the archive starts, have a null forecast.
    @Test func dayWithoutBulletinIsNotFoundButChangedResponseIsAnError() async {
        let date = Date(year: 2015, month: 2, day: 1, hour: 12)
        let missing = LavinprognoserApiClient(transport: StubTransport { _ in
            Data(#"{"content":{"forecast":null,"missingForecast":{"title":"Missing forecast"}}}"#.utf8)
        })
        await #expect(throws: LavinprognoserApiClient.LavinError.notFound) {
            try await missing.loadWarningDetailed(lang: .english, regionId: 100001, date: date)
        }
        let changed = LavinprognoserApiClient(transport: StubTransport { _ in Data(#"{"content":{}}"#.utf8) })
        await #expect(throws: DecodingError.self) {
            try await changed.loadWarningDetailed(lang: .english, regionId: 100001, date: date)
        }
    }

    @Test func activeEndpointCannotIntroduceBulletinsOutsideTheRequestedWindow() async throws {
        let date = ForecastSelection.calendar(regionID: 100001).date(from: DateComponents(year: 2026, month: 2, day: 21, hour: 12))!
        let transport = StubTransport { request in
            let active = request.url?.query == nil
            let from = active ? "Thursday 29/10-2026 18:00" : "Friday 20/02-2026 18:00"
            let to = active ? "Friday 30/10-2026 18:00" : "Saturday 21/02-2026 18:00"
            return try JSONSerialization.data(withJSONObject: ["content": ["forecast": [
                "id": active ? 124 : 123, "risk": 3, "areaId": 1, "validFrom": from, "validTo": to,
                "publishedDate": active ? "2026-10-29" : "2026-02-20", "location": "Abisko"
            ]]])
        }
        let warnings = try await LavinprognoserApiClient(transport: transport, now: { date })
            .loadWarningsDetailed(regionId: 100001, daysBefore: 2)
        #expect(warnings.map(\.RegId) == [100124])
    }
}
