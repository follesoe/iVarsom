import AppIntents
import Foundation
import Testing
@testable import Skredvarsel

private enum ForecastFixtures {
    static let calendar = ForecastSelection.calendar(regionID: 3003)
    static func date(_ day: Int = 21, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 2, day: day, hour: hour))!
    }
    static func warning(day: Int = 21, danger: DangerLevel = .level3) -> AvalancheWarningSimple {
        var warning = Fixtures.warning(date: date(day, 0), danger: danger).summary
        warning.RegId = day
        warning.ValidTo = date(day + 1, 0)
        warning.PublishTime = date(day - 1, 15)
        warning.NextWarningTime = date(day + 1, 16)
        return warning
    }
    static func snapshot(warnings: [AvalancheWarningSimple] = [warning()],
                         downloaded: Date = date(), started: Date? = nil,
                         language: String = "norway-1") -> ForecastSnapshot {
        ForecastSnapshot(regionID: 3003, language: language, requestStartedAt: started ?? downloaded,
                         downloadedAt: downloaded, warnings: warnings)
    }
}

@Suite("Forecast validity and widget timelines")
struct ForecastPlatformTests {
    @Test("Map selection uses the actual interval even when Oslo midnight is the previous UTC day")
    func mapSelectionAcrossTimeZones() {
        let now = ForecastFixtures.date(21, 12)
        let warnings = [ForecastFixtures.warning(day: 20), ForecastFixtures.warning(), ForecastFixtures.warning(day: 22)]
        #expect(ForecastSelection.warning(in: warnings, day: .today, at: now)?.RegId == 21)
        #expect(ForecastSelection.warning(in: warnings, day: .today, at: ForecastFixtures.date(22, 0))?.RegId == 22)
    }

    @Test("Watch day labels compare regional days near midnight", arguments: [-2, -1, 0, 1, 2])
    func watchDayLabels(offset: Int) {
        let now = ForecastFixtures.date(21, 0).addingTimeInterval(30 * 60)
        let date = ForecastFixtures.date(21 + offset, 0)
        let expected = [-2: "Thursday", -1: "Yesterday", 0: "Today", 1: "Tomorrow", 2: "Monday"]
        #expect(ForecastSelection.dayLabel(date, regionID: 3003, now: now, locale: Locale(identifier: "en_GB")) == expected[offset])
    }

    @Test("Widgets trim shared app history and retain shorter Watch snapshots", arguments: [-5, -1])
    func widgetHistoryWindow(firstDayOffset: Int) throws {
        let now = ForecastFixtures.date(21, 20)
        let warnings = (firstDayOffset...2).map { offset in
            var warning = ForecastFixtures.warning(day: 21 + offset)
            warning.PublishTime = ForecastFixtures.date(20, 15)
            return warning
        }
        let snapshot = ForecastFixtures.snapshot(warnings: warnings, downloaded: now)
        let plan = ForecastTimeline(loaded: LoadedForecast(snapshot: snapshot, isCached: false), day: .today, now: now)
        #expect(plan.entries.first?.warnings.map(\.RegId) == Array(max(18, 21 + firstDayOffset)...23))
        let tomorrow = try #require(plan.entries.first { $0.date == ForecastFixtures.date(22, 0) })
        #expect(tomorrow.warnings.map(\.RegId) == Array(max(19, 21 + firstDayOffset)...23))
        #expect(plan.entries.allSatisfy { $0.warnings.count <= 6 })
    }

    @Test("The widget history omits unpublished forecasts")
    func widgetHistoryPublication() {
        let warnings = [ForecastFixtures.warning(), ForecastFixtures.warning(day: 22)]
        #expect(ForecastSelection.widgetWarnings(in: warnings, at: ForecastFixtures.date(), regionID: 3003).map(\.RegId) == [21])
    }

    @Test("Norwegian end-of-day bulletins remain valid through the final second", arguments: [false, true])
    func norwegianMidnight(hasReplacement: Bool) throws {
        let midnight = ForecastFixtures.date(22, 0)
        var warning = ForecastFixtures.warning()
        warning.ValidTo = midnight.addingTimeInterval(-1)
        let warnings = hasReplacement ? [warning, ForecastFixtures.warning(day: 22)] : [warning]
        let now = ForecastFixtures.date(21, 20)
        let snapshot = ForecastFixtures.snapshot(warnings: warnings, downloaded: now)
        let plan = ForecastTimeline(loaded: LoadedForecast(snapshot: snapshot, isCached: false), day: .today, now: now)
        #expect(ForecastSelection.warning(in: warnings, day: .today, at: midnight.addingTimeInterval(-0.5))?.RegId == 21)
        #expect(!plan.entries.contains { $0.date == warning.ValidTo })
        let changeover = try #require(plan.entries.first { $0.date == midnight })
        #expect(changeover.warning?.RegId == (hasReplacement ? 22 : nil))
        #expect(plan.entries.filter { $0.date < midnight }.allSatisfy { $0.warning != nil })
    }

    @Test("Swedish expiry and replacement still happen at the exact provider boundary")
    func swedishChangeover() throws {
        let boundary = ForecastFixtures.date(21, 18)
        var previous = ForecastFixtures.warning()
        previous.RegionId = 100001
        previous.BulletinValidFrom = ForecastFixtures.date(20, 18)
        previous.ValidFrom = boundary
        previous.ValidTo = boundary
        var next = previous
        next.RegId = 22
        next.BulletinValidFrom = boundary
        next.ValidFrom = ForecastFixtures.date(22, 18)
        next.ValidTo = next.ValidFrom
        let dates = ForecastSelection.transitionDates(in: [previous, next], after: boundary.addingTimeInterval(-3600), regionID: 100001)
        #expect(dates.contains(boundary))
        #expect(!dates.contains(boundary.addingTimeInterval(1)))
        #expect(ForecastSelection.warning(in: [previous], day: .today, at: boundary) == nil)
        #expect(ForecastSelection.warning(in: [previous, next], day: .today, at: boundary)?.RegId == 22)
    }
    @Test("Bulletin dates and links keep their regional day when the reader is abroad",
          arguments: [3003, 100001], ["America/Los_Angeles", "Pacific/Auckland"])
    func regionalDisplayDates(regionID: Int, viewerTimeZone: String) {
        var warning = ForecastFixtures.warning()
        warning.RegionId = regionID
        if regionID == 100001 { warning.ValidFrom = ForecastFixtures.date(21, 18) }
        let style = Date.FormatStyle(date: .numeric, time: .omitted,
            locale: Locale(identifier: "en_GB"), timeZone: TimeZone(identifier: viewerTimeZone)!)
        #expect(warning.formattedForecastDate(style) == "21/02/2026")
        #expect(warning.forecastDateIdentifier == "2026-02-21")
        #expect(warning.VarsomUrl.absoluteString.contains("2026-02-21"))
    }

    @Test("Expired or future bulletins never substitute for the current forecast")
    func onlyCurrentInterval() {
        let now = ForecastFixtures.date()
        let warnings = [ForecastFixtures.warning(day: 20), ForecastFixtures.warning(day: 22)]
        #expect(ForecastSelection.warning(in: warnings, day: .today, at: now) == nil)
        #expect(ForecastSelection.warning(in: warnings, day: .tomorrow, at: now) == nil) // Not published yet.
    }

    @Test("Tomorrow uses a published bulletin for the requested day")
    func tomorrow() {
        let now = ForecastFixtures.date(21, 17)
        let warnings = [ForecastFixtures.warning(), ForecastFixtures.warning(day: 22)]
        #expect(ForecastSelection.warning(in: warnings, day: .today, at: now)?.RegId == 21)
        #expect(ForecastSelection.warning(in: warnings, day: .tomorrow, at: now)?.RegId == 22)
    }

    @Test("A Swedish bulletin is current before its display-day timestamp")
    func swedishValidity() {
        var warning = ForecastFixtures.warning(day: 22)
        warning.RegionId = 100001
        warning.ValidFrom = ForecastFixtures.date(22, 18)
        warning.ValidTo = warning.ValidFrom
        warning.BulletinValidFrom = ForecastFixtures.date(21, 18)
        #expect(ForecastSelection.warning(in: [warning], day: .today, at: ForecastFixtures.date(21, 19))?.RegId == 22)
        #expect(ForecastSelection.warning(in: [warning], day: .today, at: ForecastFixtures.date(22, 18)) == nil)
        var previous = warning
        previous.RegId = 21
        previous.BulletinValidFrom = ForecastFixtures.date(20, 18)
        previous.ValidFrom = ForecastFixtures.date(21, 18)
        previous.ValidTo = previous.ValidFrom
        #expect([previous, warning].currentWarningIndex(on: ForecastFixtures.date(21, 19)) == 1)
    }

    @Test("Known future forecasts and expiry are queued even without another download")
    func timelineTransitions() throws {
        let now = ForecastFixtures.date(21, 17)
        let snapshot = ForecastFixtures.snapshot(warnings: [ForecastFixtures.warning(), ForecastFixtures.warning(day: 22)], downloaded: now)
        let plan = ForecastTimeline(loaded: LoadedForecast(snapshot: snapshot, isCached: false), day: .today, now: now)
        #expect(plan.entries.first?.date == now)
        #expect(plan.entries.first?.warning?.RegId == 21)
        let nextDay = try #require(plan.entries.first { $0.date == ForecastFixtures.date(22, 0) })
        #expect(nextDay.warning?.RegId == 22)
        let expiry = try #require(plan.entries.first { $0.date == ForecastFixtures.date(23, 0) })
        #expect(expiry.warning == nil)
        #expect(!expiry.isCached)
        #expect(plan.entries.map(\.date) == Array(Set(plan.entries.map(\.date))).sorted())
    }

    @Test("Tomorrow's configuration advances at midnight instead of reusing yesterday's choice")
    func tomorrowAdvances() throws {
        let now = ForecastFixtures.date(21, 17)
        let snapshot = ForecastFixtures.snapshot(warnings: [ForecastFixtures.warning(day: 22)], downloaded: now)
        let plan = ForecastTimeline(loaded: LoadedForecast(snapshot: snapshot, isCached: false), day: .tomorrow, now: now)
        #expect(plan.entries.first?.warning?.RegId == 22)
        #expect(try #require(plan.entries.first { $0.date == ForecastFixtures.date(22, 0) }).warning == nil)
    }

    @Test("Empty and expired snapshots still yield a usable unavailable timeline", arguments: [true, false])
    func unavailableTimeline(empty: Bool) {
        let now = ForecastFixtures.date()
        let snapshot = ForecastFixtures.snapshot(warnings: empty ? [] : [ForecastFixtures.warning(day: 20)])
        let plan = ForecastTimeline(loaded: LoadedForecast(snapshot: snapshot, isCached: true), day: .today, now: now)
        #expect(!plan.entries.isEmpty)
        #expect(plan.entries.allSatisfy { $0.warning == nil })
        #expect(plan.refreshAfter == now.addingTimeInterval(15 * 60))
    }

    @Test("Use the newest published revision, irrespective of response ordering")
    func revisions() {
        var revised = ForecastFixtures.warning(danger: .level4)
        revised.PublishTime = ForecastFixtures.date(21, 10)
        #expect(ForecastSelection.warning(in: [revised, ForecastFixtures.warning()], day: .today,
                                         at: ForecastFixtures.date())?.DangerLevel == .level4)
    }

    @Test("Calendar transitions handle 23 and 25 hour days", arguments: [29, 25])
    func daylightSaving(day: Int) {
        let calendar = ForecastFixtures.calendar
        let month = day == 29 ? 3 : 10
        let now = calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 0))!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let dates = ForecastSelection.transitionDates(in: [], after: now, regionID: 3003)
        #expect(dates.contains(tomorrow))
        #expect(tomorrow.timeIntervalSince(now) == Double(day == 29 ? 23 : 25) * 3600)
    }
}

@Suite("Provider-driven refresh scheduling")
struct RefreshPlatformTests {
    @Test("Yesterday's NextWarningTime schedules today's publication")
    func previousBulletinDeadline() {
        let now = ForecastFixtures.date(21, 14)
        let warnings = [ForecastFixtures.warning(day: 20), ForecastFixtures.warning()]
        #expect(ForecastRefreshPolicy.nextRefresh(warnings: warnings, downloadedAt: now) == ForecastFixtures.date(21, 16).addingTimeInterval(60))
    }

    @Test("Late publication retries back off after the first hour", arguments: [0, 15, 59, 60, 120, 360])
    func latePublication(minutesLate: Int) {
        let now = ForecastFixtures.date(21, 16).addingTimeInterval(Double(minutesLate) * 60)
        let warnings = [ForecastFixtures.warning(day: 20), ForecastFixtures.warning()]
        let retry: TimeInterval = minutesLate < 60 ? 15 * 60 : 60 * 60
        #expect(ForecastRefreshPolicy.nextRefresh(warnings: warnings, downloadedAt: now) == now.addingTimeInterval(retry))
    }

    @Test("Already received publications don't create a short polling loop")
    func publicationReceived() {
        let now = ForecastFixtures.date(21, 17)
        var tomorrow = ForecastFixtures.warning(day: 22)
        tomorrow.PublishTime = ForecastFixtures.date(21, 16).addingTimeInterval(30)
        let warnings = [ForecastFixtures.warning(day: 20), ForecastFixtures.warning(), tomorrow]
        #expect(ForecastRefreshPolicy.nextRefresh(warnings: warnings, downloadedAt: now) == now.addingTimeInterval(4 * 3600))
    }

    @Test("A bulletin published before the advertised deadline also satisfies that deadline")
    func earlyPublicationReceived() {
        let now = ForecastFixtures.date(21, 17)
        let warnings = [ForecastFixtures.warning(day: 20), ForecastFixtures.warning(), ForecastFixtures.warning(day: 22)]
        #expect(ForecastRefreshPolicy.nextRefresh(warnings: warnings, downloadedAt: now) == now.addingTimeInterval(4 * 3600))
    }

    @Test("A fresh bulletin in one region must not hide a late update in another")
    func independentRegions() {
        let now = ForecastFixtures.date(21, 17)
        var otherRegion = ForecastFixtures.warning(day: 22)
        otherRegion.RegionId = 3006
        otherRegion.PublishTime = ForecastFixtures.date(21, 16).addingTimeInterval(30)
        let warnings = [ForecastFixtures.warning(day: 20), ForecastFixtures.warning(), otherRegion]
        #expect(ForecastRefreshPolicy.nextRefresh(warnings: warnings, downloadedAt: now) == now.addingTimeInterval(60 * 60))
    }

    @Test("Expiry can require a refresh before the next publication")
    func expiry() {
        let now = ForecastFixtures.date(21, 23)
        #expect(ForecastRefreshPolicy.nextRefresh(warnings: [ForecastFixtures.warning()], downloadedAt: now)
                == ForecastFixtures.date(22, 0))
    }

    @Test("Old timestamps never schedule a refresh in the past")
    func oldMetadata() {
        let now = ForecastFixtures.date(25, 12)
        #expect(ForecastRefreshPolicy.nextRefresh(warnings: [ForecastFixtures.warning(day: 20)], downloadedAt: now) > now)
    }

    @Test("A revalidation deadline does not turn a current bulletin into an offline fallback", arguments: [false, true])
    func savedStatusRequiresFallback(isCached: Bool) throws {
        let now = ForecastFixtures.date(21, 20)
        let snapshot = ForecastFixtures.snapshot(warnings: [ForecastFixtures.warning(), ForecastFixtures.warning(day: 22)], downloaded: now)
        let plan = ForecastTimeline(loaded: LoadedForecast(snapshot: snapshot, isCached: isCached), day: .today, now: now)
        let tomorrow = try #require(plan.entries.first { $0.date == ForecastFixtures.date(22, 0) })
        #expect(tomorrow.warning?.RegId == 22)
        #expect(plan.entries.allSatisfy { $0.isCached == isCached })
    }

    @Test("Expiry takes precedence over late-publication backoff")
    func lateExpiry() {
        let now = ForecastFixtures.date(21, 23).addingTimeInterval(45 * 60)
        var warning = ForecastFixtures.warning()
        warning.ValidTo = ForecastFixtures.date(22, 0).addingTimeInterval(-1)
        let warnings = [ForecastFixtures.warning(day: 20), warning]
        #expect(ForecastRefreshPolicy.nextRefresh(warnings: warnings, downloadedAt: now) == ForecastFixtures.date(22, 0))
    }

}

@Suite("Shared forecast snapshots")
struct SnapshotPlatformTests {
    let directory = TemporaryDirectory()

    @Test("A completed response queued for saving cannot overwrite a later request that also completed later")
    func outOfOrderSaves() async throws {
        let start = ForecastFixtures.date()
        let saveTime = start.addingTimeInterval(4)
        let app = SharedForecastStore(directory: directory.url, now: { saveTime })
        let widget = SharedForecastStore(directory: directory.url, now: { saveTime })
        await app.save(ForecastFixtures.snapshot(warnings: [ForecastFixtures.warning(danger: .level4)],
            downloaded: start.addingTimeInterval(3), started: start.addingTimeInterval(1)))
        let accepted = await widget.save(ForecastFixtures.snapshot(downloaded: start.addingTimeInterval(2), started: start))
        #expect(accepted.warnings.first?.DangerLevel == .level4)
        #expect(await widget.load(regionID: 3003, language: "norway-1", now: saveTime)?.downloadedAt == start.addingTimeInterval(3))
    }

    @Test("Separate app and extension instances read the same persisted data")
    func crossProcessStore() async throws {
        let app = SharedForecastStore(directory: directory.url)
        let widget = SharedForecastStore(directory: directory.url)
        await app.save(ForecastFixtures.snapshot())
        let loaded = try #require(await widget.load(regionID: 3003, language: "norway-1", now: ForecastFixtures.date()))
        #expect(loaded.warnings.first?.DangerLevel == .level3)
        #expect(loaded.downloadedAt == ForecastFixtures.date())
    }

    @Test("Slow older requests cannot overwrite a newer snapshot from another store")
    func olderResponse() async throws {
        let app = SharedForecastStore(directory: directory.url)
        let widget = SharedForecastStore(directory: directory.url)
        let now = ForecastFixtures.date()
        await app.save(ForecastFixtures.snapshot(warnings: [ForecastFixtures.warning(danger: .level4)], downloaded: now))
        let accepted = await widget.save(ForecastFixtures.snapshot(downloaded: now.addingTimeInterval(10), started: now.addingTimeInterval(-10)))
        #expect(accepted.warnings.first?.DangerLevel == .level4)
        #expect(await widget.load(regionID: 3003, language: "norway-1", now: now.addingTimeInterval(10))?.warnings.first?.DangerLevel == .level4)
    }

    @Test("Language, region, and future-clock snapshots cannot leak into a fallback")
    func isolation() async {
        let store = SharedForecastStore(directory: directory.url)
        await store.save(ForecastFixtures.snapshot())
        #expect(await store.load(regionID: 3006, language: "norway-1", now: ForecastFixtures.date()) == nil)
        #expect(await store.load(regionID: 3003, language: "norway-2", now: ForecastFixtures.date()) == nil)
        #expect(await store.load(regionID: 3003, language: "norway-1", now: ForecastFixtures.date(20)) == nil)
    }

    @Test("A successful empty response invalidates previously cached warnings")
    func emptyReplacesOldData() async {
        let store = SharedForecastStore(directory: directory.url)
        await store.save(ForecastFixtures.snapshot())
        await store.save(ForecastFixtures.snapshot(warnings: [], downloaded: ForecastFixtures.date(21, 13)))
        #expect(await store.load(regionID: 3003, language: "norway-1", now: ForecastFixtures.date(21, 13))?.warnings.isEmpty == true)
    }

    @Test("Corruption is a cache miss")
    func corruption() async throws {
        let store = SharedForecastStore(directory: directory.url)
        await store.save(ForecastFixtures.snapshot())
        try Data("broken".utf8).write(to: directory.url.appendingPathComponent("3003-norway-1.json"))
        #expect(await store.load(regionID: 3003, language: "norway-1", now: ForecastFixtures.date()) == nil)
    }

    @Test("A clock correction does not let a future-dated file block fresh downloads")
    func clockCorrection() async {
        let store = SharedForecastStore(directory: directory.url, now: { ForecastFixtures.date() })
        await store.save(ForecastFixtures.snapshot(downloaded: ForecastFixtures.date(22)))
        let accepted = await store.save(ForecastFixtures.snapshot())
        #expect(accepted.downloadedAt == ForecastFixtures.date())
        #expect(await store.load(regionID: 3003, language: "norway-1", now: ForecastFixtures.date()) != nil)
    }
}

@Suite("Forecast service and app-to-widget refresh")
@MainActor
struct ServicePlatformTests {
    let directory = TemporaryDirectory()
    let norway = StubNorwayClient()
    let sweden = StubSwedenClient()
    let now = ForecastFixtures.date()

    @Test("A widget consumes a newly downloaded app snapshot without another network call")
    func appSharesDownload() async throws {
        let store = SharedForecastStore(directory: directory.url)
        let now = now
        let repository = WarningRepository(norway: norway, sweden: sweden, cache: nil,
            language: { .norwegian }, sharedForecasts: store, now: { now })
        _ = try await repository.loadWarnings(WarningRequest(regionID: 3003, date: now, daysBefore: 1, daysAfter: 2), cachePolicy: .networkOnly)
        norway.detailed = { _ in Issue.record("A fresh shared snapshot should avoid a duplicate fetch"); throw TestFailure.offline }
        let service = ForecastService(repository: repository, store: store, now: { now }, language: { .norwegian })
        let loaded = try await service.load(regionID: 3003)
        #expect(!loaded.isCached)
        #expect(loaded.snapshot.warnings.count == 1)
    }

    @Test("Explicit foreground reload bypasses the shared snapshot")
    func forcedRefresh() async throws {
        let store = SharedForecastStore(directory: directory.url)
        await store.save(ForecastFixtures.snapshot())
        norway.detailed = { _ in [Fixtures.warning(danger: .level5)] }
        let now = now
        let service = ForecastService(repository: WarningRepository(norway: norway, sweden: sweden, cache: nil),
            store: store, now: { now }, language: { .norwegian })
        #expect(try await service.load(regionID: 3003, forceRefresh: true).snapshot.warnings.first?.DangerLevel == .level5)
    }

    @Test("Offline fallback preserves original download time and marks the result saved")
    func offline() async throws {
        let store = SharedForecastStore(directory: directory.url)
        await store.save(ForecastFixtures.snapshot())
        norway.detailed = { _ in throw TestFailure.offline }
        let originalDownload = now
        let retryTime = now.addingTimeInterval(3600)
        let service = ForecastService(repository: WarningRepository(norway: norway, sweden: sweden, cache: nil),
            store: store, now: { retryTime }, language: { .norwegian })
        let loaded = try await service.load(regionID: 3003, forceRefresh: true)
        #expect(loaded.isCached)
        #expect(loaded.snapshot.downloadedAt == originalDownload)
    }

    @Test("A failed Swedish active request preserves the cached current bulletin after the evening changeover",
          arguments: [false, true])
    func swedishPartialFailurePreservesSnapshot(malformedActiveResponse: Bool) async throws {
        let current = ForecastFixtures.date(21, 19)
        let downloaded = current.addingTimeInterval(-1800)
        var warning = ForecastFixtures.warning(day: 22, danger: .level4)
        warning.RegionId = 100001
        warning.BulletinValidFrom = ForecastFixtures.date(21, 18)
        warning.ValidFrom = ForecastFixtures.date(22, 18)
        warning.ValidTo = warning.ValidFrom
        let store = SharedForecastStore(directory: directory.url)
        await store.save(ForecastSnapshot(regionID: 100001, language: "sweden-1",
            requestStartedAt: downloaded, downloadedAt: downloaded, warnings: [warning]))
        let transport = StubTransport { request in
            if request.url?.query == nil {
                if malformedActiveResponse { return Data("invalid JSON".utf8) }
                throw TestFailure.offline
            }
            // Dated requests succeed, but this bulletin expired an hour ago.
            return Data(#"{"content":{"forecast":{"id":123,"risk":3,"areaId":1,"validFrom":"Friday 20/02-2026 18:00","validTo":"Saturday 21/02-2026 18:00","publishedDate":"2026-02-20","location":"Abisko"}}}"#.utf8)
        }
        let client = LavinprognoserApiClient(transport: transport, now: { current })
        let repository = WarningRepository(norway: norway, sweden: client, cache: nil,
            language: { .norwegian }, sharedForecasts: store, now: { current })
        let service = ForecastService(repository: repository, store: store, now: { current }, language: { .norwegian })
        let loaded = try await service.load(regionID: 100001, forceRefresh: true)
        #expect(loaded.isCached)
        #expect(loaded.snapshot.downloadedAt == downloaded)
        #expect(ForecastSelection.warning(in: loaded.snapshot.warnings, day: .today, at: current)?.DangerLevel == .level4)
        let persisted = try #require(await store.load(regionID: 100001, language: "sweden-1", now: current))
        #expect(persisted.downloadedAt == downloaded)
        #expect(persisted.warnings.map(\.RegId) == [warning.RegId])
    }

    @Test("Cancellation does not turn into an apparently successful cached result")
    func cancellation() async {
        let store = SharedForecastStore(directory: directory.url)
        await store.save(ForecastFixtures.snapshot())
        norway.detailed = { _ in throw CancellationError() }
        let now = now
        let service = ForecastService(repository: WarningRepository(norway: norway, sweden: sweden, cache: nil),
            store: store, now: { now }, language: { .norwegian })
        await #expect(throws: CancellationError.self) { try await service.load(regionID: 3003, forceRefresh: true) }
    }

    @Test("Unknown regions fail without substituting a default region")
    func invalidRegion() async {
        let now = now
        let service = ForecastService(store: SharedForecastStore(directory: directory.url), now: { now })
        await #expect(throws: ForecastError.invalidRegion) { try await service.load(regionID: -999) }
    }
}

@Suite("Shortcuts and Watch relevance")
struct IntentPlatformTests {
    @Test("An evening download can recommend tomorrow's already-published forecast")
    func eveningRelevance() {
        let now = ForecastFixtures.date(21, 20)
        let snapshot = ForecastFixtures.snapshot(warnings: [ForecastFixtures.warning(), ForecastFixtures.warning(day: 22)], downloaded: now)
        #expect(ForecastRelevance.morningWindows(snapshot: snapshot, now: now) == [
            DateInterval(start: ForecastFixtures.date(22, 6), end: ForecastFixtures.date(22, 10))
        ])
    }

    @Test("Morning recommendations respect validity and exclude unpublished bulletins", arguments: [false, true])
    func relevanceBoundaries(unpublished: Bool) {
        let now = ForecastFixtures.date(21, 20)
        var warning = ForecastFixtures.warning(day: 22)
        warning.ValidTo = ForecastFixtures.date(22, 8)
        if unpublished { warning.PublishTime = ForecastFixtures.date(22, 5) }
        let snapshot = ForecastFixtures.snapshot(warnings: [warning], downloaded: now)
        let windows = ForecastRelevance.morningWindows(snapshot: snapshot, now: now)
        #expect(windows == (unpublished ? [] : [DateInterval(start: ForecastFixtures.date(22, 6), end: ForecastFixtures.date(22, 8))]))
    }
    @Test("Region search ignores accents, case and embedded soft breaks", arguments: ["TROMSO", "trollheimen", "vindelfjallen"])
    func regionSearch(query: String) {
        let results = RegionConfigOptionAppEntity.RegionConfigOptionAppEntityQuery.matching(query, in: RegionOption.allOptions)
        #expect(results.count == 1)
    }

    @Test("Stable identifier lookup preserves order and the current-position choice without requesting permission")
    func identifiers() async throws {
        let results = try await RegionConfigOptionAppEntity.defaultQuery.entities(for: ["100001", "1", "missing", "3003"])
        #expect(results.map(\.id) == ["100001", "1", "3003"])
    }

    @Test("Unknown danger is represented as missing data rather than danger level zero")
    func entityValues() {
        let warning = ForecastFixtures.warning(danger: .unknown)
        let entity = AvalancheForecastEntity(warning: warning, snapshot: ForecastFixtures.snapshot(), isCached: true)
        #expect(entity.dangerLevel == nil)
        #expect(entity.validUntil == warning.ValidTo)
        #expect(entity.isCached)
    }

    @Test("Watch suggestions require a published, valid morning forecast")
    func relevance() {
        let morning = ForecastFixtures.date(21, 7)
        let snapshot = ForecastFixtures.snapshot(downloaded: morning)
        let windows = ForecastRelevance.morningWindows(snapshot: snapshot, now: morning)
        #expect(windows == [DateInterval(start: morning, end: ForecastFixtures.date(21, 10))])
        #expect(ForecastRelevance.morningWindows(snapshot: snapshot, now: ForecastFixtures.date(21, 12)).isEmpty)
        #expect(ForecastRelevance.morningWindows(snapshot: snapshot, now: ForecastFixtures.date(22, 7)).isEmpty)
    }

    @MainActor @Test("Only one scene claims an intent navigation request")
    func navigation() throws {
        let navigation = ForecastNavigation()
        navigation.open(regionID: 3003)
        let first = try #require(navigation.claimRequest())
        #expect(navigation.claimRequest() == nil)
        navigation.open(regionID: 100001)
        navigation.finish(first)
        #expect(navigation.claimRequest()?.regionID == 100001)
    }

    @MainActor @Test("An interrupted navigation can be retried after reactivation")
    func releaseNavigation() throws {
        let navigation = ForecastNavigation()
        navigation.open(regionID: 3003)
        let pending = try #require(navigation.claimRequest())
        navigation.release(pending)
        #expect(navigation.claimRequest() == pending)
    }

    @MainActor @Test("The open intent passes the selected region to foreground navigation")
    func openIntent() async throws {
        let intent = OpenRegionIntent(region: RegionConfigOptionAppEntity(RegionOption.swedenRegions[0]))
        _ = try await intent.perform()
        let pending = try #require(ForecastNavigation.shared.claimRequest())
        defer { ForecastNavigation.shared.finish(pending) }
        #expect(pending.regionID == 100001)
    }
}
