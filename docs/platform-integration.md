# Forecast integration on iOS 26 and watchOS 26

Built using Xcode 26.6, with iOS/iPadOS 26, watchOS 26 and Mac Catalyst 26 deployment targets unchanged. This work uses no iOS 27 APIs. Live Activities are intentionally excluded: a daily regional bulletin is better served by widgets and shortcuts.

## Forecast freshness and downloads

`ForecastRefreshPolicy` separates downloading a new bulletin from displaying already downloaded data. `ForecastTimeline` creates future entries for known validity changes, midnight changes to the “tomorrow” selection, and expiry. An expired bulletin never becomes the current warning just because it is the last response available. Historical warnings remain accessible in the app.

| Event | Behaviour |
| --- | --- |
| A provider advertises a future `NextWarningTime` | Request refresh one minute after the earliest outstanding publication deadline, bounded by expiry and the four-hour maximum cache age. |
| A deadline has passed and its next-day bulletin has not arrived | Retry in 15 minutes during the first hour after the deadline, then hourly, bounded by expiry; never schedule a time in the past. |
| A bulletin arrives before its advertised deadline | Treat that publication as received, avoiding an unnecessary 15-minute polling loop. |
| A known bulletin becomes valid | A prebuilt timeline entry selects it without needing another network response. |
| The displayed bulletin expires | A prebuilt entry displays an unavailable state if no replacement is known. |
| Network fails | Use the same region/language snapshot, retaining its original download time and showing “Saved forecast”; retry in 15 minutes. |
| The app activates | Resolve installed widget regions, reuse snapshots within their refresh deadline, download any due updates (at most three regions concurrently), then request widget reload. Watch also prepares its first five favourites for relevance suggestions. |
| The user pulls to refresh | Force widget-region downloads in a separate view-managed task after refreshing the app, so the spinner does not wait for widget downloads or their location lookup. Then request widget reload. |
| A detail screen successfully downloads warnings | Its repository writes the shared snapshot and requests a widget reload. |

The four-hour bound is a revalidation interval, not a claim that avalanche forecasts change every four hours. Passing a refresh deadline does not set the “Saved forecast” badge; that badge specifically indicates a failed download using a saved snapshot. Bulletin expiry independently produces the unavailable state. The API's advertised publication and validity times take precedence when earlier. WidgetKit controls execution and display timing; refresh dates and reload requests are not exact alarms. This is entirely client-side, with no server, push notifications or background polling service.

Norwegian publication deadlines must be examined across the response, including the preceding day's bulletin. A verified historical example for Trollheimen has the February 20, 2026 bulletin's `NextWarningTime` set to February 21 at 16:00, while the February 21 bulletin points to February 22 at 16:00. The API's offset-free times are parsed in `Europe/Oslo`, matching the official bulletin's displayed local publication time; summer/winter tests cover the UTC conversion. Existing local cache encoding retains its old UTC format, so cache metadata is not reinterpreted. Varsom’s inclusive 23:59:59 end is normalized to an exclusive midnight boundary for selection and timeline scheduling, avoiding a one-second unavailable entry. Sweden’s exclusive evening boundary is unchanged.

Swedish bulletins retain both their display day and their actual `validFrom`/`validTo` interval. Parsing uses `Europe/Stockholm`. The client fetches dated history and the active endpoint, which can contain tomorrow's bulletin after the evening changeover. Results stay within the requested history plus tomorrow, so a server-current bulletin cannot appear months away from a historical preview. Duplicate IDs are collapsed, preferring the latest revision.

Missing historical days are optional, but an active-endpoint failure fails the refresh. This lets the app and widgets retain their saved current bulletin and original download time, including when dated requests return only expired forecasts after the evening changeover.

Forecast day labels, accessibility descriptions, exported filenames and provider links use the region's calendar, even when the reader's device is in a different time zone. Download timestamps still describe an instant in the reader's local time.

References: [NVE API](https://api.nve.no/doc/snoeskredvarsel/), [verified example bulletin](https://www.varsom.no/snoskred/varsling/varsel/Trollheimen/2026-02-22), [WidgetKit refresh guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

## Shared storage

`SharedForecastStore` stores compact snapshots in the existing app group's `Library/Caches/Forecasts-v1` directory. Each key includes region and language. A snapshot records request start, download time and provider dates separately. The app and widget coordinate atomic file writes, rejecting results from older requests across instances/processes, even when their completed saves are queued out of order. Future-dated cache files are compared against the current clock inside the coordinated write so clock corrections can replace them. Corruption, clock reversal and absent files are cache misses; successful empty responses replace old data.

This cache is best-effort and can be evicted by the OS. It is not a user-managed offline download. App groups share data locally on each device; iPhone and Watch maintain independent caches. No coordinates or location history are saved. The app's existing detailed cache remains separate; only successful network responses are exported to the shared widget cache.

## Widgets, StandBy and Watch

The existing widget kind and region configuration remain stable. A new setting selects **Current forecast** or **Tomorrow**. “Current” means the currently valid provider interval; after Sweden's evening changeover its display day can be tomorrow. The small widget displays an explicit day/date and supports the existing StandBy, CarPlay and tinted appearances without relying on colour alone. Larger widgets show the download timestamp; saved and unavailable states have accessible descriptions. Each entry trims shared history to its own regional day minus three through plus two, so a wider app download cannot overflow the widget. Shorter Watch snapshots remain usable without inventing missing days.

The combined widget VoiceOver label includes the provider's forecast guidance and any active emergency warning. Placeholder emergency values are omitted; saved status and the original download time remain available.

The timeline provider supplies RelevanceKit morning intervals for up to five favourite regions when an already-published bulletin covers the morning. Suggestions stop at 10:00 or forecast expiry, whichever is earlier. A four-hour download deadline does not remove tomorrow’s suggestion from an evening download; unpublished and expired bulletins never create suggestions. Watch decides whether to surface a suggestion. Existing watch-face complications remain available; there is no replacement widget migration.

## Controls and Shortcuts

A configurable **Open avalanche forecast** control opens a chosen region, or uses the current position if no region is selected. It is available through the supported iOS/watchOS control surfaces; Catalyst excludes the ControlWidget type. The same `OpenRegionIntent` powers the local-forecast App Shortcut. Foreground navigation queues an intent until an active scene can claim it, preventing multiple windows from handling the same request and retaining interrupted requests across activation changes. Fixed-region navigation can use bundled region metadata while the catalog loads or is offline, then resolves against the live catalog when it arrives. Current-position navigation consumes its own location result, independently of concurrent presentation refreshes, and ignores cancelled or superseded navigation.

Region queries support names, IDs, case/accent-insensitive matching and embedded word breaks. Restoring a current-position entity does not request GPS permission; execution checks permission.

**Get Avalanche Warning** accepts the current/tomorrow setting and returns a structured `AvalancheForecastEntity` as well as a spoken response and snippet. Shortcuts can use its region, forecast date, danger level, text, validity, download time and saved status. An unknown danger level is absent, not level zero. There is no generated interpretation of provider text.

## Testing and remaining checks

Tests use Swift Testing, parameterized cases, injected clocks and providers, isolated temporary stores and deterministic errors. They exercise actual policy, selection, service and query code rather than reproducing it in tests. No test depends on live winter data or the user's cache, GPS or preferences. Existing XCTest UI tooling remains available; AppIntentsTesting requires the newer SDK and is deferred.

Verified on October 12, 2026 with Xcode 26.6 (17F113), Swift 6.3.3 and the bundled 26.5 SDKs:

- 118 tests in 17 suites pass on iPhone 17 Pro, iOS Simulator 26.5, and Mac Catalyst. Parameterized cases expand this to 158 individual executions per platform; no failures or skips. The latest review adds 13 tests and expands existing cases for concurrent cold-launch navigation, queued snapshot writes, regional day labels, widget history windows, morning suggestions, publication backoff, saved status and Norwegian/Swedish validity boundaries. Existing regressions cover VoiceOver guidance and preservation of the current Swedish snapshot after active-endpoint failures.
- The `SkredvarselWatch` scheme builds for Apple Watch Series 11 (46mm), watchOS Simulator 26.5. The final iOS and Catalyst Debug builds also pass. Signing was disabled. The Watch asset compiler reports a simulator device-trait warning; there are no Swift compiler errors.
- Before this review-fix pass, Release builds passed for iOS/iPadOS, the embedded watch app and both widget extensions, and Mac Catalyst with its widget. The earlier iPad mini test run also passed (105 tests / 130 parameterized executions).
- Project and all seven localizations pass plist validation; `git diff --check` passes.
- Winter-date app smoke checks cover Trollheimen and Abisko/Riksgränsfjällen using `SKREDVARSEL_PREVIEW_DATE=2026-02-21T12:00:00Z` and region deep links. The system date remains unchanged.

Physical-device checks remain appropriate for StandBy night rendering, Control Center/Action button invocation, Siri speech, Watch suggestion ranking, location permission prompts and distribution signing. A successful simulator build does not certify those OS-controlled behaviours. Shared snapshot persistence is tested with independent store instances and isolated directories; the unsigned simulator installation has no registered app-group container, so full app-to-extension sharing also needs a signed build.

[Apple's Swift Testing guidance](https://developer.apple.com/xcode/swift-testing/)

## Deferred SDK work

- iOS 27's extra-large portrait widget family.
- New Siri view annotations and AppIntentsTesting.
- Duo-specific layout/StandBy verification with the new SDK and device.
