# iPhone Duo and resizable layouts — October 2026

Built with Xcode 27.1 and the iOS 27.1 SDK. Apps built with earlier SDKs run letterboxed on iPhone Duo; the 27.1 SDK fills both displays and moves navigation bars, toolbars and tab bars into a vertical bar on the side. Deployment targets stay at iOS 26: newer APIs are availability-gated, and iOS 27.1 APIs are compiled for iOS only because the Mac Catalyst 27.0 SDK doesn't contain them.

Sources: [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo), [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo), the iPhone Duo tech talks (111461–111466) and Xcode 27.1's `app-resizability` and `swiftui-whats-new-27` skills.

## How the app adapts

| Pose | Width | Layout |
| --- | --- | --- |
| Closed (outer display), portrait or landscape | Compact | Regions and Map tabs; vertical bars on the right |
| Open (inner display) | Regular | Region list beside the map or a forecast, like iPad |
| Partially open, book or laptop | Regular | Same; the split view goes 50/50 and sheets move clear of the fold |

The hierarchy is the same on both displays, as the HIG asks: the inner display adds the list beside the content instead of rearranging it.

### State survives folding and unfolding

Folding switches between the compact `TabView` and the regular `NavigationSplitView`. `AdaptiveBrowserState` (in `ViewModels`) holds what must carry across, and `ContentView` applies it when the size class changes:

- **Map camera**: one camera position shared by both maps. The map stores its camera when a pan ends, so the other map opens at the same place. The map centers on the person's location once per launch; after that it keeps the position they chose, through activations and folds.
- **Map forecast**: a forecast chosen on the map is a sheet presented from the root, so it stays over the map through a fold. In regular width it uses `presentationPlacement(.leading)` (iOS 27) to keep the map visible; the system keeps sheets out of the fold, giving map-beside-forecast in book pose and map-above-forecast in laptop pose. Before iOS 27, and on the Mac, a map selection in regular width fills the detail column as before.
- **Tab after folding**: a forecast in the detail column continues in the Regions tab; the map, with or without its sheet, continues in the Map tab. Unfolding from the map shows the map rather than an earlier forecast.
- **Side effects**: catalog refresh and location re-centering run on scene activation in `ContentView`, so rebuilding a layout doesn't repeat them.

Dismissing the map's sheet clears the selection, so the map stays in view. Choosing from the list or opening a deep link closes the sheet and shows the forecast in the detail column or Regions tab.

### Bars

- Every toolbar item has a title and a symbol (`Label`): vertical bars show the symbol, overflow menus the title, and VoiceOver reads the title.
- Close buttons use `Button(role: .close)` in `.cancellationAction`, which puts them at the top of a vertical bar.
- iOS 27 `visibilityPriority`: Favorite and Show My Location stay visible longest; Share and Show All Regions overflow first.
- The full-warning sheet has only Close, so it keeps a horizontal bar on the outer display (`toolbarVerticalBehavior(.disabled)`, iOS 27.1), leaving its full width for text.
- The data attribution scrolls with the region list, so short windows (closed landscape) keep every row reachable.

### Wide and folded forecasts

`ForecastColumnsLayout` shows the summary and day picker beside the avalanche problems when both columns can be at least 340 pt wide (scaled with Dynamic Type): iPad, Mac windows, and the inner display with the sidebar hidden. With a vertical fold in the view, `GeometryProxy.reservedRegions(kind: .division, options: .includeInactive)` (iOS 27.1) puts the gap on the fold like a two-page spread; including the inactive fold keeps columns still while the device folds. Narrower layouts stack the same two views, preserving their state. The day picker re-centers the selected day when its width changes.

### Deliberately not used

- `ArrangementView`: the HIG keeps navigation containers outside arrangement views, and the API docs advise against placing one inside a `NavigationSplitView` column or a scroll view, which is where the forecast lives. System split views and sheets already handle the fold.
- `onHingeChange`: Apple recommends it for effects, not layout.
- Scene accessories: only for external displays and camera capture.
- `toolbarVerticalCompressionBehavior`: the default (keep the tab bar, overflow toolbar items) suits a navigation-focused app.

## Testing

Use the iPhone Duo simulator in Xcode 27.1. Device Hub's Closed, Partially Open and Open buttons below the bezel change the pose; Option-drag the slider for other angles. `xcrun devicectl device orientation set` rotates from the command line; there is no command-line hinge control. The iOS 27.1 simulator runtime only provides iPhone Duo, so regular width on iOS 27 can only be checked on its inner display.

Check:

1. Closed portrait and landscape: vertical bars, the forecast and map sheets, list scrolling to the attribution.
2. Open both ways round: map in the detail column, a map tap presenting the forecast at the leading edge, the two-column forecast with the sidebar hidden.
3. Partially open in book and laptop poses: the 50/50 split, sheets clear of the fold, map controls clear of the fold and bars, columns meeting at the fold.
4. Fold and unfold mid-task: from the map with and without its sheet, from a forecast chosen in the list, and after panning the map.
5. Split View on both sides of the inner display.

`AdaptiveBrowserStateTests` and `ForecastColumnsLayoutTests` cover the transition rules and column geometry.

## App Store

iPhone Duo screenshots (outer 1398 × 2034 px, inner 2007 × 2853 px, or landscape) give the product page an "optimized for iPhone Duo" badge, and become required in April 2027 for apps built with the 27.1 SDK.

Screenshots in this repository are captured by hand; there is no `snapshot` UI-test lane. `xcrun simctl io <device> screenshot` on the iPhone Duo simulator produces exactly these sizes (open the device in Device Hub for inner-display shots). Uploading them with `fastlane upload_screenshots` needs fastlane 2.241.1 or later, which maps both sizes to the `APP_IPHONE_DUO` display type; earlier versions reject them as an unsupported size.
