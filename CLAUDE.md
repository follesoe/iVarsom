# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iVarsom (App Store name: "Skredvarsel") is a SwiftUI app providing Norwegian and Swedish avalanche warnings for iOS, iPadOS, watchOS, and macOS. The main feature is home screen/notification center widgets displaying daily avalanche danger levels from the Norwegian Avalanche Warning Service API and Swedish lavinprognoser.se.

**Language**: Swift 6
**Framework**: SwiftUI
**Dependencies**: Apple frameworks only
**Toolchain**: Xcode 26.6 / Swift 6.3.3 compiler, Swift 6 language mode
**macOS**: Mac Catalyst

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild build -scheme Skredvarsel -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Build watch app
xcodebuild build -scheme SkredvarselWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)'

# Run tests
xcodebuild test -scheme Skredvarsel -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Xcode shortcuts**: Cmd+B (build), Cmd+U (test), Cmd+R (run)

## Architecture

The app uses focused observable presentation models with protocols at service boundaries. Rendering views receive values, bindings and actions; avoid a generic protocol spanning an entire screen hierarchy.

### Key Directories

- `iVarsom/` - Main iOS/iPadOS/macOS app
  - `Models/` - Data models (AvalancheWarning*, RegionSummary, DangerLevel, AvalancheProblem)
  - `Views/` - SwiftUI views
  - `ViewModels/` - RegionBrowserModel, WarningDetailModel, RegionLocationModel and WarningTranslationModel
  - `Services/` - WarningRepository, provider clients/mapping, caching, favorites and native location
- `iVarsomWidget/` - shared iOS/iPadOS/Catalyst and watchOS widget implementation
- `iVarsomWatch WatchKit Extension/` - watchOS app
- `iVarsomTests/` - deterministic Swift Testing tests (import the app module; do not add production files to this target)

### Core Services

**VarsomApiClient** (`Services/VarsomApiClient.swift`):
- Base URL: `https://api01.nve.no/hydrology/forecast/avalanche/v6.3.0/api`
- Actor isolated, uses async/await and an injectable HTTPTransport
- Methods: `loadRegions()`, `loadWarnings()`, `loadWarningsDetailed()`
- Custom date decoding: `.varsomDate` strategy

**LocationManager** (`Services/LocationManager.swift`):
- Native Core Location wrapper isolated entirely to MainActor
- Cancellation-aware permission/update operations; one-shot location requests time out after 20 seconds
- Construct and read authorization on MainActor, including in widgets and intents

**RegionBrowserModel** (`ViewModels/RegionBrowserModel.swift`):
- Per-window region catalog, search and selected region ID; shares FavoritesService
- Owns separate WarningDetailModel and RegionLocationModel instances
- Selection is resolved from the current catalog, with bundled metadata for cold-launch/offline deep links; never retain a stale region copy
- LoadState<Value> carries the result alongside its phase

**WarningDetailModel** (`ViewModels/WarningDetailModel.swift`):
- Owns warning loading, selected warning ID and a single loaded snapshot
- Runs in the caller's task and rejects obsolete results
- Receives a WarningRepositoryProviding dependency; no country-routing or disk logic

**WarningRepository** (`Services/WarningRepository.swift`):
- Actor shared by a window's models; widgets and Siri use the same implementation
- Preserves partial country results and last-known-data fallback for the app
- Widgets and Siri use ForecastService with provider-driven refresh deadlines and language-specific shared snapshots
- The live app repository exports successful detailed downloads to the app-group snapshot cache
- Older requests cannot overwrite newer cached data for the same region
- LavinprognoserResponse and LavinprognoserMapper separate wire data and pure conversion from HTTP

**Previews** (`ViewModels/PreviewModels.swift`):
- Use the real browser with fixture services and separate preview preferences
- Never start location or network services
- Debug-only `SKREDVARSEL_PREVIEW_DATE` sets the forecast date for manual winter-data checks

### Modernization notes

See [docs/modernization.md](docs/modernization.md) for architecture and [docs/platform-integration.md](docs/platform-integration.md) for forecast refresh rules, shared widget storage, controls and Shortcuts.

### Widget System

- Uses AppIntents (iOS 17+) via `SelectRegion` for configuration
- `VarsomTimelineProvider` manages timeline entries and update policy
- Supports: systemSmall/Medium/Large/ExtraLarge, accessory variants for lock screen/watch
- StandBy and CarPlay support via `widgetRenderingMode` and `showsWidgetContainerBackground` environment variables
- Uses `containerBackground(for: .widget)` for removable backgrounds

### Deep Linking

URL schemes:
- iOS: `no.follesoe.iVarsom://region?id={regionId}`
- watchOS: `no.follesoe.iVarsom.watchkitapp://region?id={regionId}`

## Localization

- English: `en.lproj/Localizable.strings`
- Norwegian: `nb.lproj/Localizable.strings`
- Swedish: `sv.lproj/Localizable.strings`
- Code defaults to Norwegian if system locale starts with "nb"
- New user-visible strings must be added to all three locale files

## Accessibility

When implementing new views or modifying existing ones, always include VoiceOver accessibility support:

- Add `.accessibilityLabel` to visual components (icons, charts, images) that convey information
- Use `.accessibilityElement(children: .ignore)` on composite views to provide a single combined label instead of letting VoiceOver read each child separately. Do NOT use `.accessibilityElement(children: .combine)` — it does not work with the speech language bridge
- Use `.accessibilityHidden(true)` on purely decorative elements (gradients, color bars, background shapes)
- Use `.accessibilityRemoveTraits(.isImage)` on images that serve as labeled diagram/icons (e.g. ExposedHeight) to avoid VoiceOver appending "image"
- Use `.accessibilityAddTraits(.isSelected)` for selectable items when selected
- Add localized accessibility strings to all three locale files (`en.lproj`, `nb.lproj`, `sv.lproj`)
- Use `DangerLevel.localizedName` for danger level names in accessibility labels (uses the app's locale automatically)
- Existing accessibility string keys: "Danger level %@, %@", compass directions, treeline descriptions, height descriptions

### VoiceOver Speech Language (`.speechLocale()`)

SwiftUI has no `.accessibilityLanguage()` modifier. The `.speechLocale(for: regionId)` modifier in `Country.swift` bridges this gap — it sets both the SwiftUI `.environment(\.locale)` (for rendered Text) AND UIKit `accessibilityLanguage` via a hidden `UIViewRepresentable` (for String-based accessibility labels).

**Placement rules — these are critical:**
- For views inside a NavigationLink, apply `.speechLocale()` on the **NavigationLink itself** in the parent view, not inside the child view. NavigationLink creates the UIKit accessibility element above the child content, so a bridge inside the child can't reach it.
- For standalone views (not in NavigationLink), apply `.speechLocale()` on the view that has `.accessibilityElement(children: .ignore)` or on its immediate parent.
- The bridge walks DOWN the UIKit subtree from its parent. Never walk up — shared ancestors in List/UICollectionView cause rows with different languages to overwrite each other.
- On watchOS there is no UIKit bridge; `.speechLocale()` only sets the environment locale (works for rendered Text only).
- Known limitation: UISearchBar (from `.searchable()`) is unreachable from the bridge.

## Git Workflow

- Do NOT commit changes unless explicitly asked to do so
- Do NOT push to remote unless explicitly asked to do so
- Wait for the user to review changes before committing
