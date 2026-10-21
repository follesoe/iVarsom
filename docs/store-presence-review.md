# App Store presence review

Reviewed on 21 October 2026. The best next release package is the existing 6.0 metadata, refreshed screenshots that bring widgets forward, the new Duo set, and tested accessibility declarations. Apple’s new header and search-result creative assets provide a useful home for a later promotional video.

This review covers the public iPhone pages in [English](https://apps.apple.com/us/app/avalanche-forecast/id1613060787), [Norwegian](https://apps.apple.com/no/app/skredvarsel/id1613060787?l=nb), and [Swedish](https://apps.apple.com/se/app/lavinvarning/id1613060787), plus the repository’s iOS and Mac metadata and media. A follow-up added accessibility drafts in App Store Connect. Analytics and unpublished media were not audited.

## Current listing and prepared content

All three public pages still show version 5.3, dated 9 March, and lead their descriptions with the 5.3 translation announcement. The repository’s 6.0 drafts already improve this substantially: the descriptions start with the everyday benefit, identify both forecast providers, and explain widgets, maps, history, Siri, translation, and saved forecasts. Publish that refreshed copy with the matching release.

| Locale | Public subtitle | Prepared subtitle |
| --- | --- | --- |
| English | Norway & Sweden as widgets | Norway & Sweden danger levels |
| Norwegian | Som widgets på hjem-skjermen | Skredfare for Norge og Sverige |
| Swedish | Lavinvarningar som widgets | Lavinfara i Sverige och Norge |

Keep the prepared subtitles: they make geographical coverage explicit. Reinforce the widget benefit in the first screenshots. Names, subtitles, promotional text, keywords, descriptions, and release notes in all three iOS folders fit their field limits.

The public iPhone media inspected showed screenshots and no app preview video. The repository has no `.mov`, `.mp4`, or `.m4v` preview assets; the README links to a [YouTube demo](https://www.youtube.com/watch?v=9gNlAR0sUzc). Its age and contents were not verified. This supports planning a new preview, without assuming that no older or unpublished video exists in App Store Connect.

## Copy changes to make before release

1. **Mac promotional text corrected locally.** All three files in `fastlane/metadata_osx` now use the replacement copy below, leading with Mac desktop widgets and the wider forecast. The Mac descriptions and release notes were already tailored to Mac. Upload remains part of the release process.
2. **Use the localized app name in release notes.** English and Swedish 6.0 notes both start with “Skredvarsel”; use “Avalanche Forecast” and “Lavinvarning” respectively, or omit the name.
3. **Shorten the public release notes.** The drafts run about 1,450 characters each. Lead with Siri, the tall widget, and Duo, then group reliability and readability improvements. Keep the detailed engineering change list in the repository or review notes.
4. **Retain the source attribution and terrain-assessment sentence.** Keep saved forecasts described as previously downloaded data, and identify machine translation as such. Avoid suggesting that a danger level is a personal route-safety decision.
5. **Support the VoiceOver claim with a task audit.** The descriptions say “full” support. Verify common tasks on each advertised platform before retaining that absolute wording and publishing accessibility labels.

Applied Mac promotional copy, each under 170 characters:

| Locale | Draft |
| --- | --- |
| English | Winter 2026/27: keep avalanche forecasts on your Mac desktop, ask Siri about your favorite regions, and compare forecast details in a wider window. |
| Norwegian | Vinteren 2026/27: Se skredvarselet på Mac-skrivebordet, spør Siri om favorittregionene dine og les varselet i to kolonner i brede vinduer. |
| Swedish | Vintern 2026/27: Se lavinprognosen på Mac-skrivbordet, fråga Siri om dina favoritområden och läs prognosen i två kolumner i breda fönster. |

The keyword lists already cover relevant activities and forecast terms. Improve coverage before adding more generic snow words. In Swedish, `lavinfara` duplicates the subtitle; it is a candidate to replace with a relevant missing term after checking search demand. There is no analytics evidence here to promise ranking gains.

The app advertises seven interface languages, while the repository maintains store copy in three. German, French, Italian, and Spanish store localizations are useful follow-ups for visitors planning trips to Norway or Sweden. Keep coverage explicit in each language so the listing does not imply forecasts for other countries.

## Screenshot priorities

The regular iPhone sequence starts with the region list and places widgets fifth and sixth in the repository. The live Norwegian first images likewise show the list, forecast, and maps. Bring the main benefit into the first three positions:

1. A current Home Screen widget with a short benefit caption.
2. The regional map with a populated forecast.
3. The detailed forecast with avalanche problems, aspects, and elevations.
4. History and tomorrow’s forecast, followed by Lock Screen widgets and other distinct features.

Possible first-image captions are “The forecast at a glance”, “Skredvarselet med et blikk”, and “Lavinprognosen med en blick”. Use real app captures and legible, restrained overlays; Apple permits explanatory text and image overlays on screenshots that show the app in use. [Screenshot guidance](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata)

The new Duo captures are in `fastlane/screenshots_ios/{en-US,no,sv}`: six each for English and Norwegian, and five for Swedish, with the tall Home Screen widget second in every set. The other captures cover map with forecast (English/Norwegian), wide forecast, outer portrait, inner portrait, and dark appearance. All 17 are native RGB PNGs without alpha, and fastlane 2.241.1 classifies them as `APP_IPHONE_DUO`. Capture details and dimensions are in [iPhone Duo](iphone-duo.md#app-store-screenshots).

For Swedish, lead with the wide forecast. The historical bulletin is populated and Swedish, but the Swedish map overview still uses the current feed and shows unavailable danger levels outside the season. Its map capture is preserved outside the upload folders as a review candidate to replace during the active season. No forecast values were altered for these images.

## New App Store opportunities

### Product page header and search creative

Apple now supports optional creative images and videos in the product page header and search results on iOS 27 and iPadOS 27 or later. These can communicate the app’s broader brand and seasonal value. Start with static artwork using a Nordic winter setting and a real forecast or widget, then develop motion from the same composition. [Asset guidance](https://developer.apple.com/app-store/asset-best-practices/)

| Placement | Image size to prepare | Video requirements |
| --- | --- | --- |
| Product page header | 3840 × 1646, 21:9 | Same resolution; 5–30 seconds; 30 or 60 fps |
| Search results | 3840 × 2560, 3:2 | Same resolution; 5–30 seconds; 30 or 60 fps |
| Universal still image alternative | 5244 × 2950 PNG | Use dedicated video exports for each placement |

Images must have no alpha. Creative videos loop; search videos cannot currently be unmuted, while header videos start muted and allow unmuting. Compose the message to work silently, with important content inside Apple’s placement templates. [Creative asset specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications)

Use App Store Connect’s Asset Library and Header and Search Results controls for these assets, then inspect them in its Preview tool. The repository’s existing screenshot lanes do not configure these placements. [Asset management](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets)

### Accessibility labels

All three public listings currently say that the developer has not specified supported accessibility features. Evaluate VoiceOver, Larger Text where applicable, Dark Interface, and Differentiate Without Color Alone first. The existing symbols, numbers, text, and dark appearance make these sensible candidates, but labels require completing all common tasks with the feature on each declared device. Include region selection, map access, dates, full forecasts, favorites, translation, sharing, widgets, and first-launch/location choices. Apple also uses declared features for relevant accessibility searches. [Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)

Draft declarations were created and read back for **iPhone, iPad, and Mac**, selecting **Dark Interface** and **Differentiate Without Color Alone**. They remain **DRAFT**, not public. Other features are not claimed pending the common-task audit in [#24](https://github.com/follesoe/iVarsom/issues/24); an unselected feature is not a conclusion that the app cannot support it. Larger Text does not apply to the Mac declaration. No Apple Watch declaration was created. Verify the shipping version before publication: the live listing is 5.3 while these screenshots and the repository describe 6.0.

### Custom pages and measurement

A Swedish touring page could lead with Swedish forecasts; a widget page could focus on quick daily checks. Custom product pages support distinct assets, shareable URLs, keyword targeting in search, and deep links into the app. Create them when there is a campaign or audience to send to them. [Custom product pages](https://developer.apple.com/app-store/custom-product-pages/)

After the baseline refresh, test one alternative: widget first versus map first. Product Page Optimization supports testing screenshots and previews. Review conversion by locale and traffic source; wait for adequate evidence before choosing a winner. A new video is a hypothesis to test, not a guaranteed improvement. [Product Page Optimization](https://developer.apple.com/app-store/product-page-optimization/)

## Video brief for later

Prepare two deliverables:

- **App preview:** a 20–25 second edit of real app screen recordings, localized in English, Norwegian, and Swedish. Start with the map, open a forecast, show the problems and date picker, then finish with a useful wide Duo layout in the appropriate device-specific version. Use readable captions, a strong poster frame, and simple cuts. Apple allows up to three previews per language, up to 30 seconds each; previews should show captured app functionality and work without sound. [App previews](https://developer.apple.com/app-store/app-previews/)
- **Header and search creative:** a 10–15 second winter scene that introduces checking the forecast, shows a genuine widget/forecast capture, and ends on the localized app name. Produce separate 21:9 and 3:2 compositions. This is the better placement for generated scenery and a broader visual story. Creative assets may depict the app’s wider brand; app previews are restricted to screen captures of the app itself. [Review guidelines 2.3.4 and 2.3.14](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata)

If using Gemini later, generate scenery or transitions and composite the real app footage during editing. Preserve the actual forecast text, dates, symbols, colors, and controls. Avoid generated UI and imagery that suggests the app guarantees a safe route. Keep the evergreen app preview separate from seasonal creative so the preview does not need replacing every winter. This brief does not depend on a particular Gemini model or its availability.

## Supporting website

The Developer Website points to the GitHub repository. Its first device image still identifies an iPhone 13 and iPad Pro 12.9, and the introduction mixes user benefits with development context. A small user-facing page could explain Norway/Sweden coverage, show the new widgets and Duo layouts, provide a current demo, explain adding widgets, and link to support and privacy. Keep GitHub as the source-code destination.

The Norwegian listing has seven ratings and an older widget complaint with an existing developer response. A clear widget setup guide is a practical improvement; that review does not need another response merely because it appeared in this audit.

## Suggested release order

1. Correct the Mac promotional copy and localized names, shorten release notes, and review the final 6.0 metadata.
2. Refresh the regular iPhone lead images and select the new Duo captures; resolve the Swedish map candidate before upload.
3. Complete the accessibility task audit and publish only the declarations it supports.
4. Add static header/search creative and inspect all locales in App Store Connect’s Preview tool.
5. Produce and test the videos later, followed by targeted pages and the additional store languages.

## Follow-up issues

Created labels `marketing`, `store presence`, and `accessibility`, and filed these scoped issues with relevant existing labels:

| Issue | Work |
| --- | --- |
| [#17](https://github.com/follesoe/iVarsom/issues/17) | Localized header and search creative |
| [#18](https://github.com/follesoe/iVarsom/issues/18) | Real app recordings and localized app previews |
| [#19](https://github.com/follesoe/iVarsom/issues/19) | Widget-led standard iPhone and iPad screenshots |
| [#20](https://github.com/follesoe/iVarsom/issues/20) | German, French, Italian, and Spanish store copy |
| [#21](https://github.com/follesoe/iVarsom/issues/21) | User-facing website and widget setup guide |
| [#22](https://github.com/follesoe/iVarsom/issues/22) | Measured screenshot experiment and targeted pages |
| [#23](https://github.com/follesoe/iVarsom/issues/23) | Swedish historical map mismatch |
| [#24](https://github.com/follesoe/iVarsom/issues/24) | Release-copy and accessibility-claim audit |

Mac promotional metadata changed locally; accessibility declarations were saved as drafts. No screenshot assets were uploaded and no store content was published. All repository changes remain uncommitted.
