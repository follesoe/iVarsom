# Modernization review — October 2026

## Toolchain and project

The starting project builds with the installed Xcode 26.6 (17F113), whose compiler is Apple Swift 6.3.3. The minimum deployment targets remain iOS/iPadOS 26 and watchOS 26; the Mac application is **Mac Catalyst**, not a separate AppKit target. There is no need to raise deployment targets just to use this compiler.

This modernization starts the **6.0** release, advancing the marketing version from 5.3 across the main app, watch app and both widget extensions in Debug and Release configurations.

The project now explicitly selects Swift 6 language mode (`SWIFT_VERSION = 6.0`). This selects concurrency checking, not a particular compiler release. Networking and storage use explicit actors; a global MainActor default would obscure these boundaries and is intentionally not enabled.

The shared Skredvarsel scheme includes the test target. Production source files have been removed from test target membership: tests import the built app module with `@testable import Skredvarsel`. Previously the test bundle compiled duplicate model types, requiring module qualification and risking tests exercising the wrong implementation.

SwiftLocation 6.0.0 was the only external package. Its two operations are now implemented using Core Location, removing its unsafe concurrency workaround and the package-resolution step. The native wrapper keeps construction and delegates on MainActor, shares concurrent one-shot requests, supports cancellation, and bounds location requests to 20 seconds. Accuracy remains three kilometers. `@preconcurrency CLLocationManagerDelegate` bridges the Objective-C delegate protocol; the manager's main run loop provides the required isolation.

## State and task ownership

- Each iOS/iPadOS/Catalyst window owns a `@State` `RegionBrowserModel`. The app owns a shared `@Observable`, `@MainActor` favorites service. Selection and search in one window no longer affect another window.
- `@Bindable` is used where a view writes state. Warning arrays and selected region values passed to detail views are read-only. Only actual selection is a binding.
- `RegionBrowserModel` owns the catalog, search and selected region ID. `WarningDetailModel` owns warning loads and selection; `RegionLocationModel` owns authorization and local-region discovery. Private request bookkeeping is excluded from Observation.
- `LoadState<Value>` carries its result, avoiding separately mutable status/data properties. Region and warning selection use IDs and resolve against current snapshots, so refreshing a catalog cannot leave a selected region pointing at outdated data.
- The broad generic view-model protocol and separate design-time model are removed. Root views use a concrete browser, while maps and rendering components receive focused values, bindings and actions. Previews exercise the real presentation models with fixture services.
- A root `.task(id:)`, keyed by selection and active scene state, owns warning loading. Reactivation refreshes details and leaving the active scene cancels pending work. `WarningDetailModel.load` awaits the real work. Cancellation propagates into the transport; request identities also reject stale successes and failures from uncooperative services. Changing or clearing selection immediately invalidates old detail state.
- Region loading handles each country's success or cache fallback independently. A Norwegian outage no longer discards fresh Swedish data. Refresh eligibility uses the last complete network refresh, a four-hour interval and a calendar-day boundary.
- Watch activation refreshes location even when the catalog is still fresh. This updates the current-position favorite after travel or permission changes and retries location requests cancelled by an earlier scene transition without downloading the catalog again.
- `WarningTranslationModel` owns translation state. A SwiftUI `.translationTask` owns the session for both installed and downloadable languages. Selection changes, including revisions of the same warning, invalidate pending results; retries invalidate the configuration.
- Sharing uses a sheet attached to the originating view and a native `ShareLink`, removing global UIKit window lookup. Each preview owns a unique temporary PNG, cleaned up when the preview is released. The warning-day picker is a separate rendering component.

## Data and persistence

`WarningRepository`, `VarsomApiClient`, `LavinprognoserApiClient` and `CacheService` are actors. The repository centralizes country routing and cache fallback; app views, widgets and Siri retain their respective cache/refresh policies. Within a repository, request identities protect the cache from older responses overwriting newer ones.

`LavinprognoserResponse` defines provider wire formats; `LavinprognoserMapper` performs deterministic conversion, HTML cleanup and date parsing with an explicit reference date. The Swedish HTTP client now handles fetching and history concurrency. A shared detailed-to-summary conversion retains emergency bulletin text.

Decoding and synchronous disk I/O execute away from MainActor. The transport is an injectable Sendable protocol; live traffic uses URLSession. Warning value payloads are Sendable. Swedish history fetching uses a structured task group, preserving cancellation while tolerating missing historical days.

Favorites expose one observed array. Local mutations persist to the app group and cloud; cloud snapshots replace the local snapshot, including removals. The previous set union resurrected deleted favorites and lost ordering. The service owns and releases its notification registration. Widget recommendations read the persisted app-group snapshot without starting another cloud observer. Cloud key-value storage still uses Apple's last-writer-wins semantics; it is not an operation-based conflict resolution system.

Cache storage and time are injected. Tests use temporary directories and isolated defaults, never the user's app cache. Existing cache encoding and filenames remain compatible. Corrupt files are misses; freshness rejects future timestamps and expires exactly at four hours. Existing last-known-data fallback is preserved. A visible stale-data state and language/date-range cache keys remain useful product follow-ups before expanding offline behavior.

Empty coordinate responses now produce a typed error. Empty widget timelines and watch rows no longer subscript an empty array. Empty or failed watch details show a message instead of an indefinite loading indicator; app details also handle an empty response explicitly. Shared current-warning selection prefers today's warning and handles empty or unordered responses; widgets and Siri no longer accidentally select the first historical bulletin. Synthetic warning IDs avoid collisions with real IDs in the same response.

## Tests and verification

The test suite uses Swift Testing and deterministic fixtures. It covers transport status and malformed data, Norwegian decoding and ID generation, Swedish mapping and missing days, current-warning selection, both countries' partial failures, offline cache fallback, warning request races and cancellation, selection invalidation, refresh boundaries, cache persistence/corruption/expiry, favorites persistence/cloud deletion/Observation, and native location completion/cancellation/error delivery.

The suite does not assert on the current season or contact a live service for its test data. Native location tests substitute a manager that never starts GPS. The shared test scheme sets `SKREDVARSEL_UNIT_TESTS=1`, so the host displays an empty window and never constructs live app services. The test target supports both iOS Simulator and Mac Catalyst.

Use the commands in README to run tests and build the iOS, watchOS and Mac Catalyst products. Release builds should also be checked when changing compiler flags or shared model code. Physical-device checks remain necessary for iCloud synchronization across accounts/devices, OS location prompts, watch complications, downloaded translation packs, and distribution signing.

## Guidelines for the next season

Use these boundaries when adding or changing behavior:

| Change | Start here |
| --- | --- |
| Region search, favorites filtering or region selection | `RegionBrowserModel` |
| Warning loading, day selection or detail loading state | `WarningDetailModel` |
| Location permission and nearest-region discovery | `RegionLocationModel` |
| Country routing or app-versus-widget cache policy | `WarningRepository` |
| Swedish JSON fields, date parsing or forecast conversion | `LavinprognoserResponse` / `LavinprognoserMapper` |
| Screen layout | Value-based views such as `RegionDetail`, `WarningDayPicker` and `AvalancheMapView` |
| Translation or sharing presentation | `WarningTranslationModel` / `SharePreviewView` |

Keep UI state isolated to MainActor, pass values into rendering views, and use bindings only for intentional edits. Keep asynchronous work in the caller's task and test ordering/cancellation with continuations, rather than sleeps. Add fixture tests when either warning provider changes its schema. Introduce a shared Swift package when independent modules or consumers justify it; the current source-sharing arrangement does not require a larger architecture framework or SwiftData.

References: [Apple's Observation migration guide](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro), [Swift 6 migration guide](https://www.swift.org/migration/documentation/migrationguide/), [Swift Testing](https://developer.apple.com/xcode/swift-testing/), and [Core Location delegate delivery](https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate).

## Xcode Cloud review

The existing `ci_scripts/ci_post_clone.sh` has the correct path, Bash shebang and executable bit. Shell syntax validation and runs with missing/sample CI variables passed. It prints build metadata only, so the dependency removal requires no script change. The shared scheme includes the test target and isolated host environment variable. The actual hosted workflow's toolchain, Test action and signing configuration are not stored in this repository and have not been verified remotely. Changes must be committed and pushed after owner approval before Cloud can use them.

## Local verification record

The first modernization pass built all platforms with Xcode 26.6 and passed 43 tests on iPad Simulator and Mac Catalyst. The cleanup pass adds regression coverage for stable selection across refreshes, stale cache writes, provider routing, mapped date fallbacks, translation resets/retries and export lifetimes.

Final cleanup verification on October 9, 2026 with Xcode 26.6:

| Check | Result |
| --- | --- |
| iPad Simulator Swift Testing suite | 59 tests in 12 suites passed |
| Mac Catalyst Swift Testing suite | 59 tests in 12 suites passed |
| iOS/iPadOS Release build, including embedded watch app and both widget targets | Passed |
| Mac Catalyst Release build, including widget | Passed |
| Final compiler diagnostics | No compiler warnings or errors |
| Historical-data UI smoke on iPad | February 21, 2026 forecasts loaded; region navigation, warning details, assessment dialog and switching forecast days verified |
| Export regression tests | PNG creation, unique paths, slash-containing region names and cleanup verified |
| Project integrity | `git diff --check` and project plist validation passed |

The iPad smoke used the Debug-only date environment variable, without changing the system date. The system share sheet and downloaded translation packs still need manual UI checks. Build checks use signing disabled and do not certify distribution signing. Cross-device iCloud synchronization and watch complications require physical-device checks. Xcode Cloud was reviewed locally; no remote workflow was run.

Review follow-up verification: the watch activation fix adds three regression tests covering travel between regions, a cancelled initial location request, and revoked permission while the catalog remains fresh. All **62 tests in 12 suites passed on both iPad Simulator and Mac Catalyst**. The iPad test build also rebuilt the watch app and validated its embedded widgets. These checks use simulated location services; physical watch lifecycle testing remains a device check.
