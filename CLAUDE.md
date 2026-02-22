# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iVarsom (App Store name: "Skredvarsel") is a SwiftUI app providing Norwegian and Swedish avalanche warnings for iOS, iPadOS, watchOS, and macOS. The main feature is home screen/notification center widgets displaying daily avalanche danger levels from the Norwegian Avalanche Warning Service API and Swedish lavinprognoser.se.

**Language**: Swift 6
**Framework**: SwiftUI
**Dependency**: SwiftLocation v6.0.0 (via SPM)

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

The app follows MVVM with protocol-based abstractions for testability.

### Key Directories

- `iVarsom/` - Main iOS/iPadOS/macOS app
  - `Models/` - Data models (AvalancheWarning*, RegionSummary, DangerLevel, AvalancheProblem)
  - `Views/` - SwiftUI views
  - `ViewModels/` - RegionListViewModel with reactive state management
  - `Services/` - VarsomApiClient (API v6.3.0), LocationManager
  - `Abstractions/` - Protocols for testing/previews
- `iVarsomWidget/` - iOS/iPadOS widget extension
- `iVarsomWidgetWatch/` - watchOS widget extension
- `iVarsomWatch WatchKit Extension/` - watchOS app
- `iVarsomTests/` - XCTest unit tests

### Core Services

**VarsomApiClient** (`Services/VarsomApiClient.swift`):
- Base URL: `https://api01.nve.no/hydrology/forecast/avalanche/v6.3.0/api`
- Main actor isolated, uses async/await
- Methods: `loadRegions()`, `loadWarnings()`, `loadWarningsDetailed()`
- Custom date decoding: `.varsomDate` strategy

**LocationManager** (`Services/LocationManager.swift`):
- Thread-safe CoreLocation wrapper using SwiftLocation
- Main actor isolated for permission/update operations
- `isAuthorized` property safe to call from any thread

**RegionListViewModel** (`ViewModels/RegionListViewModel.swift`):
- Manages regions, warnings, favorites (UserDefaults persistence)
- LoadState enum: idle, loading, loaded, failed
- Implements `RegionListViewModelProtocol` for testability

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
