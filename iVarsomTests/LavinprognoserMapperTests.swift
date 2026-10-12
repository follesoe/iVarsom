import Foundation
import Testing

@testable import Skredvarsel

struct LavinprognoserMapperTests {
    private func forecast(validTo: String = "Saturday 21/02-2026 18:00", published: String = "2026-02-20") throws
        -> LavinprognoserResponse.LavinForecast
    {
        let data = try JSONSerialization.data(withJSONObject: [
            "id": 123, "risk": 3, "areaId": 1,
            "validFrom": "Friday 20/02-2026 18:00", "validTo": validTo, "publishedDate": published,
            "location": "Abisko", "assessmentContent": "<p>Wind &amp; snow</p><!-- hidden --><script>hidden</script>",
        ])
        return try JSONDecoder().decode(LavinprognoserResponse.LavinForecast.self, from: data)
    }

    @Test(arguments: ["Saturday 21/02-2026 18:00", "lördag 21/02-2026 18:00", "lørdag 21/02-2026 18:00"])
    func localizedForecastDatesHaveSameDisplayDay(validTo: String) throws {
        let warning = LavinprognoserMapper(date: Fixtures.date, languageKey: 2)
            .warning(from: try forecast(validTo: validTo), regionId: 100001)
        #expect(Calendar.current.isDate(warning.ValidFrom, inSameDayAs: Date(year: 2026, month: 2, day: 21)))
        #expect(warning.MainText == "Wind & snow")
        #expect(warning.LangKey == 2)
    }

    @Test func invalidDatesUseInjectedClock() throws {
        let date = Date(year: 2026, month: 2, day: 21, hour: 12)
        let warning = LavinprognoserMapper(date: date, languageKey: 3)
            .warning(from: try forecast(validTo: "invalid", published: "invalid"), regionId: 100001)
        #expect(warning.PublishTime == date)
        #expect(warning.ValidFrom == Calendar.current.date(byAdding: .day, value: 1, to: date))
    }

    @Test func actualValidityIsPreservedSeparatelyFromDisplayDay() throws {
        let warning = LavinprognoserMapper(date: Fixtures.date, languageKey: 3)
            .warning(from: try forecast(), regionId: 100001)
        let expected = try #require(ISO8601DateFormatter().date(from: "2026-02-20T17:00:00Z"))
        #expect(warning.BulletinValidFrom == expected)
        #expect(warning.summary.validityStart == expected)
        #expect(warning.ValidFrom == warning.ValidTo)
    }
}
