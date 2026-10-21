<img src="images/iVarsomIcon.png" alt="iVarsom icon" width="64" />

# Skredvarsel

The Skredvarsel (Avalanche warning) app is an iOS, iPadOS, and macOS application that provides daily avalanche warnings from the [Norwegian Avalanche Warning Service API](http://api.nve.no/doc/snoeskredvarsel/) and [Swedish Avalanche Warning Service (lavinprognoser.se)](https://www.lavinprognoser.se/).

The main feature of the app is a set of beautiful widgets that can be added to the home screen on iOS and iPadOS, or the notification center on macOS. It is not intended to replace the official [Varsom Regobs app](https://apps.apple.com/us/app/varsom-regobs/id1450501601), but rather complement it with an app taking full advantage of the Apple platforms. Hence the code name iVarsom.

The app is also a learning exercise for myself to learn how to build and distribute a SwiftUI app for iOS, iPadOS, watchOS, and macOS.

## Features

- Avalanche warnings for **Norway** and **Sweden**
- Interactive map view showing all regions colored by danger level (iOS and watchOS)
- Favorite regions with iCloud sync across devices
- Home screen and lock screen widgets
- watchOS app with complications
- Siri Shortcuts for voice-based danger queries
- Swedish language support

## iOS and iPadOS

<img src="images/iPhoneiPadDeviceScreenshot.webp" alt="App running on iPhone 13 and iPad Pro 12.9" />

<a href="https://apps.apple.com/app/skredvarsel/id1613060787">
    <img src="images/DownloadOnTheAppStore.svg" alt="Download on the App Store" />
</a>

## watchOS

<img src="images/watchOSDeviceScreenshot.webp" alt="App running on the Apple Watch" />

<a href="https://apps.apple.com/app/skredvarsel/id1613060787">
    <img src="images/DownloadOnTheAppStore.svg" alt="Download on the App Store" />
</a>

## macOS

<img src="images/macBookScreenshot.webp" alt="App running on macOS" />

<a href="https://apps.apple.com/app/skredvarsel/id1613060787">
    <img src="images/DownloadOnTheMacAppStore.svg" alt="Download on the Mac App Store" />
</a>

## Screenshots

### iOS

| | | | | | |
|:---:|:---:|:---:|:---:|:---:|:---:|
| <img src="images/iOS/region_list.webp" alt="Region list" width="160" /> | <img src="images/iOS/region_details.webp" alt="Region details" width="160" /> | <img src="images/iOS/map_overview.webp" alt="Map overview" width="160" /> | <img src="images/iOS/map_zoomed.webp" alt="Map zoomed" width="160" /> | <img src="images/iOS/small_and_medium_widget.webp" alt="Widgets" width="160" /> | <img src="images/iOS/large_widget.webp" alt="Large widget" width="160" /> |

### iPadOS

| | | |
|:---:|:---:|:---:|
| <img src="images/iPadOS/map_overview.webp" alt="Map overview" width="320" /> | <img src="images/iPadOS/region_details.webp" alt="Region details" width="320" /> | <img src="images/iPadOS/region_details.webp" alt="Region details 2" width="320" /> |
| <img src="images/iPadOS/map_details.webp" alt="Map details" width="320" /> | <img src="images/iPadOS/widgets.webp" alt="Widgets" width="320" /> | <img src="images/iPadOS/map_overview_dark.webp" alt="Map overview dark mode" width="320" /> |

### macOS

| | | |
|:---:|:---:|:---:|
| <img src="images/macOS/desktop_widgets.webp" alt="Desktop widgets" width="320" /> | <img src="images/macOS/screenshot_2.webp" alt="Region list dark mode" width="320" /> | <img src="images/macOS/screenshot_3.webp" alt="Region details dark mode" width="320" /> |
| <img src="images/macOS/screenshot_4.webp" alt="Region details dark mode 2" width="320" /> | <img src="images/macOS/screenshot_5.webp" alt="Region list light mode" width="320" /> | <img src="images/macOS/screenshot_6.webp" alt="Map overview light mode" width="320" /> |

## Siri Shortcuts

You can ask Siri for avalanche warnings using voice commands. The app supports both English and Norwegian phrases:

**English:**
- "Get avalanche warning in Skredvarsel"
- "Avalanche warning from Skredvarsel"
- "Get avalanche warning for Ofoten in Skredvarsel"
- "What is the avalanche danger in Tromsø with Skredvarsel"

**Norwegian:**
- "Hent varsel i Skredvarsel"
- "Varsel fra Skredvarsel"
- "Hent varsel for Ofoten i Skredvarsel"
- "Hva er skredfaren i Tromsø med Skredvarsel"

Siri will speak the danger level and warning text, and display a visual summary with the danger icon.

## Video Demo

[![Video Demo](https://img.youtube.com/vi/9gNlAR0sUzc/0.jpg)](https://www.youtube.com/watch?v=9gNlAR0sUzc)

## Beta testing

Join the [beta testing group on TestFlight](https://testflight.apple.com/join/8IeX64AS).

## Development

### Requirements

- Xcode 27.1 (iOS 27.1 SDK; verified locally; includes Swift 6.4)
- Swift 6 language mode
- iOS 26+ / macOS 26+ / watchOS 26+

### Building from Source

```bash
git clone https://github.com/follesoe/iVarsom.git
cd iVarsom
open Skredvarsel.xcodeproj
```

The app uses Apple frameworks only; no external packages need to be resolved. The macOS application uses Mac Catalyst.

### Running Tests

```bash
xcodebuild test -project Skredvarsel.xcodeproj -scheme Skredvarsel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

The same suite also runs on Mac Catalyst:

```bash
xcodebuild test -scheme Skredvarsel \
  -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGNING_ALLOWED=NO
```

The shared scheme runs deterministic Swift Testing tests and suppresses live app startup services in the unit-test host. Choose an installed simulator using `xcodebuild -showdestinations -scheme Skredvarsel` if the example device is unavailable. Tests use fixture responses, temporary caches and isolated preferences.

```bash
# iOS/iPadOS app, watch app, and embedded widgets
xcodebuild build -scheme Skredvarsel -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO

# macOS via Mac Catalyst, including its widget
xcodebuild build -scheme Skredvarsel -destination 'generic/platform=macOS,variant=Mac Catalyst' CODE_SIGNING_ALLOWED=NO

# watchOS app and complication extension
xcodebuild build -scheme SkredvarselWatch -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO
```

### Architecture

Each window owns a `RegionBrowserModel`, with separate observable models for warning details and location. Rendering views take values, bindings and focused actions. A `WarningRepository` actor routes requests to the Norwegian or Swedish provider and applies the caller's cache policy; widgets and Siri reuse this routing. Provider response mapping is independent of networking, and previews use the real models with fixture services.

View tasks own asynchronous loading and cancellation. Selection uses IDs, and loading states carry their results. See the [modernization review](docs/modernization.md) for decisions, test coverage and remaining device checks, and [CLAUDE.md](CLAUDE.md) for repository guidance.

### Platform integration

Widgets support current and tomorrow’s published forecasts, shared offline fallback, explicit validity and publication-driven refresh scheduling. Opening or refreshing the app updates the regions used by widgets. Configurable controls open regional forecasts, Shortcuts return structured forecast data, and watchOS receives contextual morning suggestions. See [platform integration](docs/platform-integration.md) for behaviour, testing and SDK limitations.

### iPhone Duo

The app fills both iPhone Duo displays with vertical bars on the outer display, keeps the selected forecast, map position and the map's forecast sheet when folding or unfolding, and lays wide forecasts out in two columns that meet at the fold. See [iPhone Duo](docs/iphone-duo.md) for design decisions and a pose checklist.

### Previewing a winter forecast

In the scheme's **Run → Arguments → Environment Variables**, set `SKREDVARSEL_PREVIEW_DATE` to an ISO 8601 timestamp such as `2026-02-21T12:00:00Z`. This affects the forecast clock in Debug builds only; remove the variable to return to today. It does not change the system clock. Swedish detailed forecasts support dated requests, while their overview endpoint still describes the live season.

### Xcode Cloud

`ci_scripts/ci_post_clone.sh` is an executable diagnostics-only hook. No dependency installation is needed. The shared `Skredvarsel` scheme includes the unit-test target and its isolated host configuration. The hosted workflow must have a Test action using that scheme, plus the desired build/archive actions and a compatible Xcode version (27.1 was verified locally; the iOS 27.1 SDK is required for the full iPhone Duo layout). Workflow selection and signing are configured in Xcode Cloud, outside this repository.

### Fastlane

Fastlane is used for managing App Store metadata. Metadata is split into platform-specific directories to avoid Apple's rejection for mentioning other platforms:

- `fastlane/metadata_ios/` - iOS/watchOS metadata
- `fastlane/metadata_osx/` - macOS metadata

Available lanes:

```bash
# Upload iOS metadata
fastlane ios upload_metadata

# Upload macOS metadata
fastlane ios upload_metadata_mac

# Upload to both platforms
fastlane ios upload_metadata_all

# Preview changes (dry run)
fastlane ios preview_metadata

# Download existing metadata from App Store Connect
fastlane ios download_metadata
```

## Privacy

The app collects no user data. Location is used only to find your local avalanche region (3km accuracy) and is not stored or transmitted beyond the initial API query. See [PRIVACY.md](PRIVACY.md) for the full privacy policy.

## License

[MIT License](LICENSE) © Jonas Follesø
