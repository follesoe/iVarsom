import Foundation
import Testing

@testable import Skredvarsel

/// Siri and Shortcuts answers: the request's language (iOS 27) and voice-only wording.
struct ForecastAnswerTests {
    private func warning(danger: DangerLevel = .level3, emergency: String? = nil) -> AvalancheWarningSimple {
        var warning = Fixtures.warning(danger: danger).summary
        warning.MainText = "Avoid steep wind-loaded slopes."
        warning.EmergencyWarning = emergency
        return warning
    }

    private func dialog(
        _ warning: AvalancheWarningSimple, isCached: Bool = false, isVoiceOnly: Bool, locale: String = "en-US"
    ) -> String {
        ForecastAnswer.dialog(
            for: warning, downloadedAt: Fixtures.date, isCached: isCached, isVoiceOnly: isVoiceOnly,
            language: ForecastAnswerLanguage(requestLocale: Locale(identifier: locale)))
    }

    @Test func archiveSelectionPicksLatestPublishedBulletinForDay() {
        let day = Fixtures.date
        var first = Fixtures.warning(date: day).summary
        first.RegId = 1
        var revised = first
        revised.RegId = 2
        revised.PublishTime = day.addingTimeInterval(3600)
        var otherDay = first
        otherDay.RegId = 3
        otherDay.ValidFrom = day.addingTimeInterval(86400)
        var unpublished = revised
        unpublished.RegId = 4
        unpublished.PublishTime = day.addingTimeInterval(7200)
        let warnings = [first, revised, otherDay, unpublished]
        #expect(ForecastSelection.warning(in: warnings, on: day, at: day.addingTimeInterval(3600))?.RegId == 2)
        #expect(ForecastSelection.warning(in: warnings, on: day.addingTimeInterval(-86400), at: day) == nil)
    }

    @Test(arguments: ["nb-NO", "nb", "no", "sv-SE", "sv-FI"])
    func norwegianAndSwedishRequestsGetNativeBulletins(locale: String) {
        #expect(VarsomApiClient.language(for: Locale(identifier: locale)) == .norwegian)
    }

    @Test(arguments: ["en-US", "en-GB", "de-DE", "fi-FI"])
    func otherRequestsGetEnglishBulletins(locale: String) {
        #expect(VarsomApiClient.language(for: Locale(identifier: locale)) == .english)
    }

    @Test(arguments: [("nb-NO", "Lagret varsel"), ("sv-SE", "Sparad prognos"), ("en-US", "Saved forecast")])
    func wordingUsesRequestLanguage(locale: String, expected: String) {
        #expect(ForecastAnswerLanguage(requestLocale: Locale(identifier: locale)).string("Saved forecast") == expected)
    }

    @Test func screenAnswerKeepsSentenceAndForecastText() {
        let text = dialog(warning(), isCached: true, isVoiceOnly: false)
        #expect(text.hasPrefix("Saved forecast. The avalanche danger level in Test Region for "))
        #expect(text.contains("is Considerable."))
        #expect(text.hasSuffix("Avoid steep wind-loaded slopes."))
    }

    @Test func voiceOnlyAnswerSaysLevelNumberAndDownloadTime() {
        let text = dialog(warning(), isCached: true, isVoiceOnly: true)
        #expect(text.hasPrefix("Saved forecast from "))
        #expect(text.contains("The avalanche danger in Test Region for "))
        #expect(text.contains("is level 3, Considerable."))
        #expect(text.hasSuffix("Avoid steep wind-loaded slopes."))
    }

    @Test(arguments: [false, true])
    func emergencyWarningIsIncludedBeforeForecastText(isVoiceOnly: Bool) throws {
        let text = dialog(warning(emergency: "Large natural avalanches expected."), isVoiceOnly: isVoiceOnly)
        let emergency = try #require(text.range(of: "Emergency warning: Large natural avalanches expected."))
        let forecast = try #require(text.range(of: "Avoid steep wind-loaded slopes."))
        #expect(emergency.upperBound <= forecast.lowerBound)
    }

    @Test func inactiveEmergencyTextIsOmitted() {
        #expect(!dialog(warning(emergency: "Not given"), isVoiceOnly: true).contains("Emergency"))
    }

    @Test func voiceOnlySavedForecastSaysDownloadTimeWithoutARating() {
        let text = dialog(warning(danger: .unknown), isCached: true, isVoiceOnly: true)
        #expect(text.hasPrefix("Saved forecast from "))
        #expect(!dialog(warning(danger: .unknown), isCached: true, isVoiceOnly: false).contains("Saved forecast from"))
    }

    @Test func unassessedDangerAvoidsSpeakingAQuestionMark() {
        let text = dialog(warning(danger: .unknown), isVoiceOnly: true)
        #expect(!text.contains("?"))
        #expect(text.contains("Not assessed"))
    }

    @Test func spokenDateIncludesYearOnlyForDaysFarFromToday() {
        func spoken(now: Date) -> String {
            ForecastAnswer.dialog(
                for: warning(), downloadedAt: Fixtures.date, isCached: false, isVoiceOnly: true,
                language: ForecastAnswerLanguage(requestLocale: Locale(identifier: "en-US")), now: now)
        }
        let year = String(Calendar(identifier: .gregorian).component(.year, from: Fixtures.date))
        #expect(!spoken(now: Fixtures.date).contains(year))
        #expect(spoken(now: Fixtures.date.addingTimeInterval(400 * 86400)).contains(year))
    }

    @Test func norwegianVoiceAnswer() {
        let text = dialog(warning(), isVoiceOnly: true, locale: "nb-NO")
        #expect(text.contains("Skredfaren i Test Region for "))
        #expect(text.contains("er faregrad 3, Betydelig."))
    }
}

/// Choosing which bulletin Siri and Shortcuts answer with.
@MainActor
struct ForecastLookupTests {
    private let norway = StubNorwayClient()
    private let sweden = StubSwedenClient()
    private let directory = TemporaryDirectory()
    private let oslo = ForecastSelection.calendar(regionID: 3003)
    /// Saturday 21 February 2026, 12:00 in Oslo.
    private var saturday: Date { oslo.date(from: DateComponents(year: 2026, month: 2, day: 21, hour: 12))! }

    private func lookup(now: Date) -> (ForecastLookup, SharedForecastStore) {
        let store = SharedForecastStore(directory: directory.url, now: { now })
        let repository = WarningRepository(norway: norway, sweden: sweden, cache: nil, language: { .english }, now: { now })
        return (ForecastLookup(repository: repository, store: store, language: .english, now: { now }), store)
    }

    @Test(arguments: [
        (PastForecastDay.yesterday, 20), (.lastSaturday, 14), (.lastFriday, 20), (.lastSunday, 15), (.lastMonday, 16),
    ])
    func earlierDaysCountBackFromToday(day: PastForecastDay, expectedDay: Int) {
        let date = day.date(before: saturday, calendar: oslo)
        #expect(oslo.component(.day, from: date) == expectedDay)
        #expect(oslo.component(.hour, from: date) == 12)
    }

    @Test func shortcutsDateKeepsItsCalendarDayInRegionTimeZone() {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let midnightInTokyo = tokyo.date(from: DateComponents(year: 2026, month: 2, day: 21))!
        let day = ForecastLookup.regionDay(for: midnightInTokyo, regionID: 3003, timeZone: tokyo.timeZone)
        #expect(oslo.dateComponents([.year, .month, .day, .hour], from: day)
            == DateComponents(year: 2026, month: 2, day: 21, hour: 12))
    }

    /// After 18:00 Sweden's valid bulletin is tomorrow's; a date still gets its own day.
    @Test func swedishEveningDateAnswersWithThatDaysBulletin() async throws {
        let stockholm = ForecastSelection.calendar(regionID: 100001)
        func day(_ day: Int, hour: Int) -> Date {
            stockholm.date(from: DateComponents(year: 2026, month: 2, day: day, hour: hour))!
        }
        // Bulletins run 18:00 to 18:00 and are dated by their last day.
        func bulletin(_ id: Int, endingOn end: Int) -> AvalancheWarningDetailed {
            var warning = Fixtures.warning(100001, date: day(end, hour: 18))
            warning.RegId = id
            warning.ValidTo = day(end, hour: 18)
            warning.BulletinValidFrom = day(end - 1, hour: 18)
            warning.PublishTime = day(end - 1, hour: 16)
            return warning
        }
        sweden.detailed = { _ in [bulletin(1, endingOn: 21), bulletin(2, endingOn: 22)] }
        let now = day(21, hour: 19)
        let (lookup, store) = lookup(now: now)
        #expect(try await lookup.forecast(regionID: 100001, day: .today).warning.RegId == 2)
        let today = try await lookup.forecast(regionID: 100001, on: day(21, hour: 12))
        #expect(today.warning.RegId == 1)
        let tomorrow = try await lookup.forecast(regionID: 100001, on: day(22, hour: 12))
        #expect(tomorrow.warning.RegId == 2)
        #expect(tomorrow.archiveDay == nil)

        // Today's bulletin has expired, so Shortcuts must fetch it from the archive.
        sweden.archived = { _, _ in bulletin(1, endingOn: 21) }
        let query = AvalancheForecastEntity.Query(store: store, now: { now }) { _ in lookup.repository }
        for result in [today, tomorrow] {
            let entity = AvalancheForecastEntity(
                warning: result.warning, snapshot: result.snapshot, isCached: result.isCached,
                archiveDay: result.archiveDay)
            #expect(try await query.entities(for: [entity.id]).map(\.id) == [entity.id])
        }
    }

    @Test func pastDayComesFromArchiveWithoutReplacingSharedForecast() async throws {
        let (lookup, store) = lookup(now: saturday)
        let lastWeek = PastForecastDay.lastSaturday.date(before: saturday, calendar: oslo)
        norway.detailed = { _ in [Fixtures.warning(3003, date: lastWeek)] }
        let result = try await lookup.forecast(regionID: 3003, on: lastWeek)
        #expect(result.warning.ValidFrom == lastWeek)
        #expect(!result.isCached)
        let key = SharedForecastStore.languageKey(regionID: 3003, language: .english)
        #expect(await store.load(regionID: 3003, language: key, now: saturday) == nil)
    }

    @Test func todayUsesCurrentForecastAndSharedStore() async throws {
        let (lookup, store) = lookup(now: saturday)
        let morning = oslo.date(from: DateComponents(year: 2026, month: 2, day: 21))!
        norway.detailed = { _ in [Fixtures.warning(3003, date: morning)] }
        let result = try await lookup.forecast(regionID: 3003, on: saturday)
        #expect(result.warning.ValidFrom == morning)
        let key = SharedForecastStore.languageKey(regionID: 3003, language: .english)
        #expect(await store.load(regionID: 3003, language: key, now: saturday) != nil)
    }

    @Test func daysAfterTomorrowAreNotPublished() async {
        let (lookup, _) = lookup(now: saturday)
        await #expect(throws: ForecastError.noForecast) {
            try await lookup.forecast(regionID: 3003, on: saturday.addingTimeInterval(3 * 86400))
        }
    }

    @Test func archiveErrorsDistinguishMissingBulletinsFromConnectionFailures() async {
        let (lookup, _) = lookup(now: saturday)
        let lastYear = saturday.addingTimeInterval(-365 * 86400)
        norway.detailed = { _ in [] }
        await #expect(throws: ForecastError.noForecast) { try await lookup.forecast(regionID: 3003, on: lastYear) }
        norway.detailed = { _ in throw URLError(.notConnectedToInternet) }
        await #expect(throws: ForecastError.unavailable) { try await lookup.forecast(regionID: 3003, on: lastYear) }
        // A server error isn't a missing bulletin.
        norway.detailed = { _ in throw VarsomApiClient.VarsomError.requestError }
        await #expect(throws: ForecastError.unavailable) { try await lookup.forecast(regionID: 3003, on: lastYear) }
        norway.detailed = { _ in throw LavinprognoserApiClient.LavinError.notFound }
        await #expect(throws: ForecastError.noForecast) { try await lookup.forecast(regionID: 3003, on: lastYear) }
        // An unreadable response is a failure, not a day without a bulletin.
        norway.detailed = { _ in
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unexpected response"))
        }
        await #expect(throws: ForecastError.unavailable) { try await lookup.forecast(regionID: 3003, on: lastYear) }
    }

    @Test func favoritesWithoutForecastsDifferFromFailedFavorites() {
        #expect(ForecastError.combining([ForecastError.noForecast, ForecastError.noForecast]) == .noForecast)
        #expect(ForecastError.combining([ForecastError.noForecast, ForecastError.unavailable]) == .unavailable)
        #expect(ForecastError.combining([ForecastError.noForecast, URLError(.timedOut)]) == .unavailable)
        // Only a current position without a location fix: nothing was asked.
        #expect(ForecastError.combining([]) == .unavailable)
    }

    @Test func favoritesComeFirstInRegionSuggestions() {
        let options = RegionOption.aRegions + RegionOption.swedenRegions
        let favorites = [options[5].id, options[2].id]
        let ordered = RegionConfigOptionAppEntity.favoritesFirst(options, favorites: favorites)
        #expect(Array(ordered.prefix(2)).map(\.id) == favorites)
        #expect(ordered.count == options.count)
        #expect(ordered[2].id == options[0].id)
    }

    private func favorites(_ count: Int, cached: Set<Int> = []) -> [ForecastLookup.Result] {
        (0..<count).map { index in
            var warning = Fixtures.warning(3003 + index, date: saturday).summary
            warning.RegionName = "Region \(index)"
            let snapshot = ForecastSnapshot(
                regionID: warning.RegionId, language: "en", requestStartedAt: saturday,
                downloadedAt: saturday.addingTimeInterval(TimeInterval(index) * 3600), warnings: [warning])
            return ForecastLookup.Result(warning: warning, snapshot: snapshot, isCached: cached.contains(index))
        }
    }

    private func summary(
        _ results: [ForecastLookup.Result], failed: [String] = [], withoutForecast: [String] = [],
        isVoiceOnly: Bool = false
    ) -> String {
        ForecastAnswer.summary(
            for: results, failed: failed, withoutForecast: withoutForecast, isVoiceOnly: isVoiceOnly,
            language: ForecastAnswerLanguage(requestLocale: Locale(identifier: "en-US")), now: saturday)
    }

    @Test func favoritesSummarySaysDaysWhenRegionsDiffer() {
        var results = favorites(2)
        #expect(summary(results).hasPrefix("Region 0: level 3, Considerable. Region 1: level 3"))
        // Sweden's current forecast after 18:00 is tomorrow's.
        var tomorrow = results[1].warning
        tomorrow.ValidFrom = saturday.addingTimeInterval(86400)
        results[1] = ForecastLookup.Result(warning: tomorrow, snapshot: results[1].snapshot, isCached: false)
        #expect(summary(results).hasPrefix("Region 0 (today): level 3, Considerable. Region 1 (tomorrow): level 3"))
    }

    @Test func favoritesSummaryNamesRegionsWithoutAnAnswer() {
        let text = summary(favorites(1), failed: ["Lyngen", "Tromsø"], withoutForecast: ["Abisko"])
        #expect(text.hasPrefix(
            "Couldn't load the forecast for Lyngen and Tromsø. No forecast for Abisko. Region 0: level 3"))
    }

    @Test func favoritesSummaryListsEmergenciesFirstAndLimitsLength() {
        var results = favorites(6)
        var emergency = results[5].warning
        emergency.EmergencyWarning = "Large natural avalanches expected."
        results[5] = ForecastLookup.Result(warning: emergency, snapshot: results[5].snapshot, isCached: false)
        let text = summary(results)
        #expect(text.hasPrefix("Emergency warning: Region 5."))
        #expect(text.contains("Region 0: level 3, Considerable."))
        #expect(!text.contains("Region 4:"))
        #expect(!text.contains("Saved forecast"))
        #expect(text.hasSuffix("And 2 more."))
    }

    @Test func favoritesSummaryNamesSavedForecasts() {
        let some = favorites(3, cached: [1, 2])
        #expect(summary(some).hasPrefix("Saved forecast: Region 1 and Region 2. Region 0:"))
        // Without the snippet, say when: the oldest saved download, 13:00 in Oslo.
        let spoken = summary(some, isVoiceOnly: true)
        #expect(spoken.hasPrefix("Saved forecast from Saturday"))
        #expect(spoken.contains("1:00") || spoken.contains("13:00"))
        #expect(spoken.contains(": Region 1 and Region 2. Region 0:"))
        // When all are saved, the regions go without saying.
        let all = favorites(2, cached: [0, 1])
        #expect(summary(all).hasPrefix("Saved forecast. Region 0:"))
        #expect(summary(all, isVoiceOnly: true).hasPrefix("Saved forecast from Saturday"))
        #expect(!summary(all, isVoiceOnly: true).contains("Region 1 and"))
    }
}
