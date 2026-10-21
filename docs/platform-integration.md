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

On watchOS 26 the provider returns an empty `recommendations()` array so WidgetKit presents direct region/day configuration, as described in [Apple's watchOS 26 session](https://developer.apple.com/videos/play/wwdc2025/334/). This is independent of RelevanceKit suggestions; the widget kind and saved configurations stay unchanged.

## Forecast reading and accessibility

The app and shared forecast images use `ForecastSummaryCard`: an official-colour danger header followed by full-width text on a system background. The detail screen already names the region in its navigation title, so it omits the repeated card title. Fixed-size widgets retain their existing summary layout.

The day picker names each day, retains its full spoken date, and scrolls toward the selected day without animation when Reduce Motion is enabled. Region rows label their danger badges with weekdays and stack below the region name at accessibility text sizes. The badge group itself switches to vertical day/level rows when its scaled content cannot fit horizontally, including narrow split-view sidebars at the largest text setting. At accessibility text sizes, source attribution scrolls with the list instead of reducing the reading area.

Watch summaries scroll, use semantic fonts and retain readable body contrast across danger levels. Add Region is a native button, and toolbar buttons use the system's glass treatment. No Live Activity or custom double-tap behaviour is introduced.

Opening the app, returning to it, browsing fixed regions and displaying the map only check existing location authorization. Permission prompts belong to explicit current-location actions, including map location, local-region navigation and current-position shortcuts. Already-authorized locations still refresh on activation.

The local-warnings section uses a full-row native button with its explanation in the section footer. Undecided permission offers **Use current location**; a saved denial offers **Open Settings**, because iOS does not repeat a denied permission prompt. Restricted access is explained without offering an ineffective request. A pending lookup shows progress, and an authorized lookup that produces no region retains the button so it can be retried. Authorization is checked again on activation after returning from Settings. This follows [Apple's location authorization behaviour](https://developer.apple.com/documentation/corelocation/cllocationmanager/requestwheninuseauthorization()) and uses the [supported app Settings URL](https://developer.apple.com/documentation/uikit/uiapplication/opensettingsurlstring).

## Controls and Shortcuts

A configurable **Open avalanche forecast** control opens a chosen region, or uses the current position if no region is selected. It is available through the supported iOS/watchOS control surfaces; Catalyst excludes the ControlWidget type. The same `OpenRegionIntent` powers the local-forecast App Shortcut. Foreground navigation queues an intent until an active scene can claim it, preventing multiple windows from handling the same request and retaining interrupted requests across activation changes. Fixed-region navigation can use bundled region metadata while the catalog loads or is offline, then resolves against the live catalog when it arrives. Current-position navigation consumes its own location result, independently of concurrent presentation refreshes, and ignores cancelled or superseded navigation.

Region queries support names, IDs, case/accent-insensitive matching and embedded word breaks. Restoring a current-position entity does not request GPS permission; execution checks permission.

**Get Avalanche Warning** accepts the current/tomorrow setting and returns a structured `AvalancheForecastEntity` as well as a spoken response and snippet. Shortcuts can use its region, forecast date, danger level, text, validity, download time and saved status. An unknown danger level is absent, not level zero. There is no generated interpretation of provider text.

## iOS 27 widget and Siri updates (October 2026)

Built with Xcode 27.1; deployment targets stay at iOS/watchOS 26, so each API below is availability-gated.

- **Tall extra-large widget** (`systemExtraLargePortrait`, iOS/Mac Catalyst 27): today's summary, download state and emergency banner, the next two days' forecast text, and the day strip. Widget entries only carry summary bulletins, so it shows forecast text rather than avalanche problems. Its VoiceOver label also reads the coming days. The family is added conditionally in `iVarsomWidget.families`; the system decides where the size is offered.
- **Background execution**: `GetAvalancheWarningIntent` declares `supportedModes = .background` instead of the deprecated `openAppWhenRun`.
- **Answers in the request's language** (iOS 27 `IntentSystemContext.locale`): provider text can't be localized afterwards, so the intent requests the Norwegian/Swedish bulletin for Norwegian or Swedish requests and English otherwise, and words the answer with the matching app localization. The shared store keeps one snapshot per language, so this never replaces the widgets' forecast. Earlier systems use the app's language. Errors Siri reads, such as having no favorites, use the same language.
- **Voice-only answers** (iOS 27 `IntentSystemContext.isVoiceOnly`): without the snippet, the answer gives a spoken date, the danger level number with its name, and when a saved forecast was downloaded. Every answer now includes an active emergency warning before the forecast text.
- The Swedish client takes the bulletin language as a parameter, like the Norwegian client, instead of reading the device language, so a repository's injected language applies to both countries.
- Shortcuts shows the region parameter type as "Avalanche region" (localized) instead of "Region Config Option".

### Asking about favorites and other days

- **Get Favorite Avalanche Warnings** answers for every favorite region (current or tomorrow's forecast), naming regions with an active emergency warning first and reading at most four regions aloud. It returns one `AvalancheForecastEntity` per region. A current-position favorite is skipped if no location is available, rather than failing the answer. Regions answered from a saved forecast are named, and the snippet shows each one's download time; a voice-only answer says when the oldest was downloaded. Favorites that couldn't be loaded or have no bulletin for the day are named rather than left out, since a missing region could hide an emergency warning. When the regions' forecasts are for different days, as after Sweden's 18:00 changeover, the answer says each region's day; snippet rows always show it. If no favorite has a forecast, the answer is "No forecast available for this day" only when every region lacks a bulletin; otherwise the service is unavailable.
- **Get Avalanche Warning for Date** answers for any day: Shortcuts passes a date (`kind: .date`), and Siri phrases pass an "earlier day" (`PastForecastDay`: yesterday or last Monday to Sunday, meaning the most recent such day before today). With neither, it asks which day. Shortcuts dates keep their calendar day in the region's time zone, read in the Gregorian calendar whatever calendar the person uses.
- `ForecastLookup` routes both: today and the next two days use the current forecast with its offline fallback (the day after tomorrow is answered once Norway publishes it early), choosing the bulletin dated that day (after 18:00, Sweden's valid bulletin is already tomorrow's). If today's bulletin is missing or the current forecast fails, it is asked for by date, since Sweden loads it with a request of its own that can succeed or fail separately; earlier days come from the provider's archive through `WarningRepository.loadWarnings(on:regionID:)` (Norway by date range, Sweden by `forecast_date`) and are never stored, so they can't replace the app's or widgets' forecast. Later days are never published. A day without a bulletin answers "No forecast available for this day": Norway returns an empty list and Sweden returns `forecast: null`, which the client reports as not found. Out of season, both may instead publish a bulletin without a danger rating, which is answered as unrated. Connection failures, server errors and responses the app can't read report the service as unavailable. Current entities resolve from the shared store while their bulletin is valid. Entities for earlier days, and for an expired bulletin asked for by date (such as Sweden's today after 18:00), add the day to their ID, so the entity query fetches them from the archive again.
- New App Shortcut phrases (in all seven languages): tomorrow in a region, my favorites, yesterday in a region, an earlier day, and an earlier warning for a region. Six of the ten allowed App Shortcuts are used. The existing intent, its `region`/`day` parameters and all shipped phrases are unchanged.
- When Siri asks for a region, favorites are suggested first, and spoken names no longer contain the zero-width spaces the app uses as line-break hints.

### Siri AI (iOS 27) and what it can't do here

App Shortcut phrases can hold one parameter, which must be an app entity or enum, so a phrase can't contain a free-form date; "earlier day" covers the common spoken cases. Siri AI only runs intents and finds entities that conform to an App Schema, and no schema domain fits avalanche forecasts (there is no weather domain; only `.system.open`/`.system.searchInApp` could apply). Siri AI is also English-only and unavailable on iPhone and Apple Watch in the EU, so most Norwegian and Swedish users get classic Siri with App Shortcuts, which still work with Siri AI. Device checks remain for how classic Siri parses spoken dates in Norwegian and Swedish when it asks "Which day?", and for phrase matching with a preset day.

Worthwhile follow-ups: an interactive snippet with previous/next-day buttons (`SnippetIntent`, iOS 26), donating forecasts viewed in the app so Siri can suggest them (`IntentDonationManager`), region synonyms (`DisplayRepresentation(synonyms:)`), and Spotlight-indexed regions (`IndexedEntity`).

`ForecastAnswerTests` cover the language mapping, localized wording, voice-only phrasing, emergency text and unassessed danger levels; repository and client tests cover the Swedish language plumbing.

## Testing and remaining checks

Tests use Swift Testing, parameterized cases, injected clocks and providers, isolated temporary stores and deterministic errors. They exercise actual policy, selection, service and query code rather than reproducing it in tests. No test depends on live winter data or the user's cache, GPS or preferences. Existing XCTest UI tooling remains available; AppIntentsTesting requires the newer SDK and is deferred.

Verified on October 12, 2026 with Xcode 26.6 (17F113), Swift 6.3.3 and the bundled 26.5 SDKs:

- 120 tests in 17 suites pass on iPhone 17 Pro, iOS Simulator 26.5, and Mac Catalyst. Parameterized cases expand this to 162 individual executions per platform; no failures or skips. Coverage includes concurrent cold-launch navigation, queued snapshot writes, regional day labels, widget history windows, morning suggestions, publication backoff, saved status and Norwegian/Swedish validity boundaries. The polish pass adds regression tests proving activation/fixed-region browsing never requests location permission, while explicit current-position actions do. Existing regressions cover VoiceOver guidance and preservation of the current Swedish snapshot after active-endpoint failures.
- The `SkredvarselWatch` scheme builds for Apple Watch Series 11 (46mm), watchOS Simulator 26.5. The final iOS and Catalyst Debug builds also pass. Signing was disabled. The Watch asset compiler reports a simulator device-trait warning; there are no Swift compiler errors.
- Before this review-fix pass, Release builds passed for iOS/iPadOS, the embedded watch app and both widget extensions, and Mac Catalyst with its widget. The earlier iPad mini test run also passed (105 tests / 130 parameterized executions).
- Project and all seven localizations pass plist validation; `git diff --check` passes.
- Winter-date app smoke checks cover Trollheimen and Abisko/Riksgränsfjällen using `SKREDVARSEL_PREVIEW_DATE=2026-02-21T12:00:00Z` and region deep links. The system date remains unchanged.
- The polish pass checks Lyngen on iPhone in light/dark modes, accessibility-extra-large text, adaptive region rows, named forecast days and the generated share preview. After resetting simulator location permission, launching and browsing the map show no prompt; the explicit Locate button does. The prompt was declined and normal text size/light appearance restored after verification.
- The iPad Pro 11-inch split view was checked with Lyngen and its loaded region sidebar. Watch Series 11 (46mm) checks cover the native Add Region button, a long favourite-region name, the forecast summary, page navigation and the details sheet. The Watch simulator rejects dynamic-text overrides, so larger Watch text, configurable widgets and Always On still need on-device verification.
- The badge-overflow review fix builds on iOS and Mac Catalyst. At the largest accessibility setting, all three day/level rows fit the iPad sidebar without clipping; normal-size text retains the horizontal badge layout. A narrow `.accessibility5` preview covers this layout for future manual checks. No policy or service logic changed, so the full unit suite was not rerun for this layout-only fix.
- The local-location follow-up passes 124 tests / 172 parameterized executions on iPad Pro 11-inch (M5), iOS Simulator 26.5. New tests cover the initial permission request, saved denials/restrictions, presentation of each authorization state, and retrying a failed or empty location lookup. Cancellation also clears the progress state. The simulator's saved permission was verified as **Never**; resetting only this app's permission restored the first-use prompt, and declining it changed the row to **Open Settings**. The Settings action was checked manually.

Physical-device checks remain appropriate for StandBy night rendering, Control Center/Action button invocation, Siri speech, Watch suggestion ranking, location permission prompts and distribution signing. A successful simulator build does not certify those OS-controlled behaviours. Shared snapshot persistence is tested with independent store instances and isolated directories; the unsigned simulator installation has no registered app-group container, so full app-to-extension sharing also needs a signed build.

[Apple's Swift Testing guidance](https://developer.apple.com/xcode/swift-testing/)

## Deferred SDK work

- New Siri view annotations and AppIntentsTesting.
- StandBy verification with the new SDK on a device. iPhone Duo layout is covered in [iPhone Duo](iphone-duo.md).
