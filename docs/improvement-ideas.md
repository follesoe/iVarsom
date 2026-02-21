# Improvement Ideas

## Quick Wins

### Push Notifications for High Danger Levels
Let users set a threshold (e.g., level 3+) and get notified when their favorited regions hit it. Could use background app refresh to check the API periodically.

### ~~Offline Caching~~ (Done)
Implemented in `CacheService.swift`. File-based JSON cache in the OS caches directory with a 4-hour freshness window. The app now loads cached data instantly on launch, skips the network when cache is fresh, and falls back to stale cache on network failure.

### ~~Siri / App Shortcuts Integration~~ (Done)
Fully implemented across `GetAvalancheWarningIntent.swift`, `AppShortcuts.swift`, `AvalancheWarningSnippetView.swift`, and `RegionConfigOptionAppEntity.swift`. Supports Norway, Sweden, and current-position queries with voice dialog, visual snippets, and localized Siri phrases in English, Norwegian, and Swedish.

### VoiceOver / Accessibility Improvements
Adding proper accessibility labels to the expositions compass, danger icons, and height visualizations would help visually impaired users.

## Medium Effort

### Trip Planning View
A multi-day, multi-region view where you pick a date range and a few regions to compare forecasts side-by-side. Useful when deciding where to go for a weekend.

### Live Activities / Dynamic Island
Show the current danger level as a Live Activity for a selected region during a trip day.

### Avalanche Problem Trend Indicators
Show whether danger is rising, falling, or stable compared to previous days. The data for this is already fetched by the app.

## Larger Features

### Share Warnings
Generate a shareable image or link of the current forecast, useful for group trip planning.

### Interactive Map Improvements
The map already shows colored polygons. Adding the ability to tap for a quick summary popup, or filtering by danger level, would add value.

### Apple Watch Complications with Multiple Regions
Currently the watch widget shows one region. A "stack" of favorites would be useful for people who travel between areas.

## Data Sources Investigated

### Finland (Ilmatieteenlaitos)
Investigated in February 2026. Finland has no open API for avalanche forecasts. All data is server-rendered PNG images. Revisit if FMI publishes an API.
