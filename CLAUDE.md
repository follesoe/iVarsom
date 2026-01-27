# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iVarsom (App Store name: "Skredvarsel") is a SwiftUI app providing Norwegian avalanche warnings for iOS, iPadOS, watchOS, and macOS. The main feature is home screen/notification center widgets displaying daily avalanche danger levels from the Norwegian Avalanche Warning Service API.

**Language**: Swift 6
**Framework**: SwiftUI
**Dependency**: SwiftLocation v6.0.0 (via SPM)

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild build -scheme Skredvarsel -destination 'platform=iOS Simulator,name=iPhone 16'

# Build watch app
xcodebuild build -scheme SkredvarselWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'

# Run tests
xcodebuild test -scheme Skredvarsel -destination 'platform=iOS Simulator,name=iPhone 16'
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

### Deep Linking

URL schemes:
- iOS: `no.follesoe.iVarsom://region?id={regionId}`
- watchOS: `no.follesoe.iVarsom.watchkitapp://region?id={regionId}`

## Localization

- English: `en.lproj/Localizable.strings`
- Norwegian: `nb.lproj/Localizable.strings`
- Code defaults to Norwegian if system locale starts with "nb"
