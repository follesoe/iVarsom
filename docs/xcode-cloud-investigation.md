# Xcode Cloud investigation — 21 October 2026

The Default workflow is now pinned to **Xcode 27.1 (27A9275)**. With approval, a manual build of `main` at `fd7d084addd46a8172dc5e8c8d42bf7243d8df32` was started. **Build 30 succeeded for both iOS and Mac Catalyst** (10 minutes elapsed, 4 minutes reported usage).

[Build 30](https://appstoreconnect.apple.com/teams/00e3549c-8e4a-49da-bdc4-8b80ac8a217d/xcode-cloud/products/4DD4874D-C595-4C8E-A9DE-A5CF19DB053E/builds/b9ffbec1-565a-4581-bad7-8a1e65bd5fc2/summary)

## Why recent commits had no builds

The workflow was enabled, with an any-file-change trigger for the exact branch `main`. Xcode Cloud could list and fetch that branch. GitHub's Xcode Cloud installation was active and already had repository access; no access changes were made. The repository UI showed its last prior access 227 days earlier and there were no retained recent runs.

The workflow's **Latest Release** alias resolved to Xcode 27 (27A266a), even though 27.1 was available in its version selector. Pinning 27.1 corrects the SDK selection needed for the Duo changes. An old SDK could cause compilation failures after a trigger; it does not by itself explain why no runs were created.

The manual success proves repository access and the archive pipeline work. **The automatic-trigger failure remains unproven.** Check whether the next normally approved commit pushed to `main` creates a run. No diagnostic commit was created. If it does not trigger, retain the commit SHA and push time and investigate the GitHub App event delivery with Apple support. Do not expand repository access or recreate the workflow without evidence that either is necessary.

## Mac warnings in Build 30

The overview groups two warnings. The expanded logs contain the same linker warning for the app and widget extension, each for `arm64` and `x86_64`:

```text
Search path '/Users/local/Library/Developer/DVTDownloads/MetalToolchain/mounts/E2D7D12A-5B92-4ACC-8A15-AC88EF542EA0/Metal.xctoolchain/usr/lib/swift/maccatalyst' not found
```

This is a missing **search directory**, not an unresolved symbol or missing required library. Compilation, linking, archive export, and the completed build succeeded. No matching custom library path, toolchain override, or linker flag was found in the project or CI scripts. The iOS action showed no warnings.

Apple DTS reproduced this warning in a new Catalyst project after installing the Metal toolchain and identified it as a tooling bug: [Apple Developer Forums, thread 812718](https://developer.apple.com/forums/thread/812718). Build 30 matches that reported failure mode; no app-source fix is indicated by these logs.

Keep the warning visible rather than suppressing all linker diagnostics or creating empty toolchain directories in CI. Recheck with a later stable Xcode cloud image; if it persists, include this build link in an Apple Feedback report. No toolchain removal, warning suppression, or additional cloud configuration changes were made.

The logs also report absent optional `ci_pre_xcodebuild.sh`, `ci_post_xcodebuild.sh`, and “What to test” files as passed informational steps. They are not failures and do not require empty scripts to silence them.

Local evidence is in ignored `build/store-presence/cloud-warnings.txt` and `cloud-build-30.png`. The diagnostic build used the existing remote commit, so it does not include the uncommitted screenshot and widget-summary changes from this session.
