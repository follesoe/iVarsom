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

- **Map camera**: one camera position shared by both maps. The map stores its camera when a pan ends, so the other map opens at the same place. The map centers on the person's location once per launch, or when they choose Show My Location; after that it keeps the position they chose, through activations and folds.
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

Use the iPhone Duo simulator in Xcode 27.1. Device Hub's Closed, Partially Open and Open buttons below the bezel change the pose; Option-drag the slider for other angles. Use Device Hub's Rotate Right control for screenshot orientation: during capture, `xcrun devicectl device orientation set` reported success without rotating the displayed simulator. There is no command-line hinge control. The iOS 27.1 simulator runtime only provides iPhone Duo, so regular width on iOS 27 can only be checked on its inner display.

Check:

1. Closed portrait and landscape: vertical bars, the forecast and map sheets, list scrolling to the attribution.
2. Open both ways round: map in the detail column, a map tap presenting the forecast at the leading edge, the two-column forecast with the sidebar hidden.
3. Partially open in book and laptop poses: the 50/50 split, sheets clear of the fold, map controls clear of the fold and bars, columns meeting at the fold.
4. Fold and unfold mid-task: from the map with and without its sheet, from a forecast chosen in the list, and after panning the map.
5. Split View on both sides of the inner display.

`AdaptiveBrowserStateTests` and `ForecastColumnsLayoutTests` cover the transition rules and column geometry.

## App Store screenshots

Verified with Xcode 27.1 and Homebrew fastlane 2.241.1 on October 21, 2026. The Fastfile requires at least 2.241.1: this release adds Duo screenshot recognition to `deliver`. Update this machine's installation with `brew upgrade fastlane`, then check `fastlane --version`. See the [fastlane release notes](https://github.com/fastlane/fastlane/releases/tag/2.241.1).

### Accepted images

| Display | Portrait | Landscape |
| --- | --- | --- |
| Outer | 1398 × 2034 px | 2034 × 1398 px |
| Inner | 2007 × 2853 px | 2853 × 2007 px |

Apple accepts PNG or JPEG without alpha channels or transparency. Both displays map to the same `APP_IPHONE_DUO` screenshot set, so budget up to **10 images total per locale**, across both displays and orientations. Duo screenshots enable the product page's "optimized for iPhone Duo" badge; Apple's specifications say they become required in April 2027 for apps using the iOS 27.1 SDK or later. Source: [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

### Capture workflow

Screens are composed manually in Device Hub; there is no `snapshot` UI-test suite. The `capture_duo` lane saves the selected display using [scripts/screenshots_duo.sh](../scripts/screenshots_duo.sh).

1. Run the app on **iPhone Duo (iOS 27.1)** from Xcode and select it in Device Hub. Use the app language you intend to capture. To populate forecasts outside winter, use the existing Debug-only `SKREDVARSEL_PREVIEW_DATE=2026-02-21T12:00:00Z` launch setting described in the [README](../README.md#previewing-a-winter-forecast).
2. Choose **Closed** below the device for the outer display, or **Open** / **Partially Open** for the inner display. Rotate with Device Hub's rotation control. Wait for the app, map tiles and any fold animation to finish.
3. Capture from the repository root, matching `display:` to the pose currently visible:

   ```sh
   # Closed, with the forecast visible:
   fastlane ios capture_duo locale:en-US display:outer name:forecast

   # Choose Open in Device Hub, then capture the expanded layout:
   fastlane ios capture_duo locale:en-US display:inner name:forecast
   ```

   Optional `device:<UDID>` selects a specific simulator if there are multiple named iPhone Duo. Locale values match the metadata folders (`en-US`, `no`, `sv`, etc.). **`locale:` chooses only the destination folder; it does not change the app's language.**

4. Review the PNGs in `fastlane/screenshots_ios/<locale>/`. The helper checks native dimensions, rejects completely black frames, removes alpha losslessly, and numbers outer and inner images together (`01_duo_outer_forecast.png`, `02_duo_inner_forecast.png`). Rename the numeric prefixes to set the final order. The `duo` prefix also keeps these images out of the existing iPhone 17 bezel-framing script.
5. When the set is ready, `fastlane ios upload_screenshots` uploads **all iOS screenshots** in those folders, including existing iPhone and iPad images. Capture does not upload. Use App Store Connect's Preview tool to review the product page before release.

The helper uses ImageMagick (`brew install imagemagick`), already used by `frame_screenshots.sh`. For local experiments outside the upload folders:

```sh
./scripts/screenshots_duo.sh --locale en-US --display inner \
  --output-dir build/duo-screenshots -- forecast
```

### Capture details and troubleshooting

On Xcode 27.1, `xcrun simctl io "iPhone Duo" enumerate` lists `primary` as the outer display and `primary-1` as the inner display. Select the display explicitly; the default screenshot command can pick the inactive display and return a black image. Selecting a display **does not unfold the device**. Change its pose in Device Hub first.

```sh
xcrun simctl io "iPhone Duo" screenshot --display=primary --mask=ignored /tmp/duo-outer.png
xcrun simctl io "iPhone Duo" screenshot --display=primary-1 --mask=ignored /tmp/duo-inner.png
```

These raw PNGs can still have an alpha channel even with `--mask=ignored`. The helper writes an RGB PNG without alpha, preserving the native dimensions; verify with `sips -g pixelWidth -g pixelHeight -g hasAlpha <file.png>`. Capture the framebuffer rather than the Mac's Device Hub window: the window includes a scaled device bezel, and partially open poses have a perspective effect that does not belong in the raw screenshot.

If a capture is black, ensure the matching pose is active and the app is visible; after a fresh boot, wait for rendering to settle and retry. Correct dimensions alone do not establish that a capture contains the intended app. Always inspect the saved image, including its orientation and language.

### Recommended set for Skredvarsel

Apple recommends showing the app in use, leading with strong features, keeping text legible, localizing assets, and highlighting Duo across orientations. See [App Store asset best practices](https://developer.apple.com/app-store/asset-best-practices/) and [Prepare for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/). The following sequence is our recommendation for this app:

1. **Inner, landscape:** map beside a selected forecast, showing the benefit of the expanded display.
2. **Inner, landscape:** the tall Home Screen widget, including the next published forecast.
3. **Inner, landscape:** a detailed forecast with the sidebar hidden, showing the summary and avalanche problems side by side.
4. **Outer, portrait:** the same forecast in its compact layout, with the vertical controls visible.
5. **Inner, portrait or partially open:** a useful alternate arrangement of the same task; capture the flat display image, not Device Hub's perspective rendering.
6. Optionally include a dark appearance if it adds useful information, keeping the complete Duo set within 10 images.

Use representative, populated forecasts with readable dates, dismiss permission dialogs and loading states, and check maps have loaded. Repeat in the languages used by the product page. For consistent status bars, optionally use `xcrun simctl status_bar "iPhone Duo" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100`; restore with `xcrun simctl status_bar "iPhone Duo" clear` after capture.

### Captured localized set

Captured on October 21, 2026 using the installed Debug app on iOS 27.1, the existing preview-date setting, and real provider forecasts dated February 21, 2026. These are native display captures without device bezels or added captions.

| Folder | App language and locale | Forecast region | Images |
| --- | --- | --- | --- |
| `fastlane/screenshots_ios/en-US` | `en`, `en_US` | Tromsø (3011) | 6 |
| `fastlane/screenshots_ios/no` | `nb`, `nb_NO` | Tromsø (3011) | 6 |
| `fastlane/screenshots_ios/sv` | `sv`, `sv_SE` | Abisko/Riksgränsfjällen (100002) | 5 |

English and Norwegian contain a map/forecast, tall Home Screen widget, two-column forecast, outer portrait, inner portrait, and dark forecast. Swedish leads with the two-column forecast, followed by the widget, outer portrait, inner portrait, and dark forecast. Widgets are second in every locale. There are 17 upload-folder images in total; all have native dimensions and no alpha and are recognized as `APP_IPHONE_DUO`.

The Swedish map is **excluded from the upload folders** and preserved in ignored `build/duo-screenshots/candidates/sv`: the detailed historical bulletin is available, but `LavinprognoserApiClient.loadRegions` uses the current overview endpoint without a date parameter. Swedish markers therefore show no assessed danger level outside the active season, even though the historical forecast is populated. Recapture that image during the season before adding it back to the upload selection; see [issue #23](https://github.com/follesoe/iVarsom/issues/23). The forecast text and danger levels were not modified to hide this limitation.

To reproduce the localization setup, substitute the language and locale from the table:

```sh
SIMCTL_CHILD_SKREDVARSEL_PREVIEW_DATE=2026-02-21T12:00:00Z \
  xcrun simctl launch --terminate-running-process 'iPhone Duo' \
  no.follesoe.iVarsom -AppleLanguages '(sv)' -AppleLocale sv_SE
xcrun simctl openurl 'iPhone Duo' 'no.follesoe.iVarsom://region?id=100002'
```

For the map composition, open Map, hide the sidebar, select the region, expand the forecast sheet, and choose Partially Open in landscape. For the two-column composition, dismiss the sheet, choose Open, reopen the region, and hide the sidebar. Check orientation again after folding; an outer display can initially retain a landscape layout inside the portrait device view.

The local review gallery is `build/duo-screenshots/index.html`, with contact sheets and `validation.json` beside it. The `build` directory is ignored by Git. Capture-only status-bar, simulated-location, appearance, and date overrides were cleared after this session. See the [store presence review](store-presence-review.md) for the proposed release package and future video brief.

### Widget capture setup

Widget extensions do not inherit the app's launch arguments. A Debug build can also read `SKREDVARSEL_PREVIEW_DATE` from the `group.no.follesoe.iVarsom` shared preferences. Install a simulator build signed with `CODE_SIGN_IDENTITY=-` so the app and extension receive their app-group entitlement; an unsigned build did not expose the shared container.

For English and Norwegian widget captures, the shared clock was `2026-02-21T18:00:00Z` so the real next-day bulletin was already published. Swedish used `2026-02-21T12:00:00Z`, within the Abisko bulletin’s validity window (it expired at 17:00 UTC); no later bulletin was available in that historical response, so its widget shows the current forecast and history without a tomorrow row. The Debug timeline freezes its first historical entry instead of allowing WidgetKit's actual system clock to advance to the expired entry. Release timelines retain their normal scheduling. Dates, forecast values, and provider text are unchanged.

Set the simulator's system language and locale for each widget capture (`en-US` / `en_US`, `nb` / `nb_NO`, `sv` / `sv_SE`) and restart it, then launch the app and let widget refresh finish. Configure the tall widget for Tromsø or Abisko/Riksgränsfjällen and inspect the downloaded time and language before capture. Allow widget configuration-sheet animations to settle before coordinate input; their initial position can differ from the settled position.

Afterward remove the shared preview-date key and any simulator environment override, restore the original simulator language/locale, clear the status-bar override, and relaunch the app to resume normal widget timelines. The widget summary no longer enables text selection: WidgetKit rendered that unsupported behavior as warning overlays, which were verified absent after rebuilding.
