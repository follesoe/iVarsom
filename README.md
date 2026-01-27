<img src="images/iVarsomIcon.png" alt="iVarsom icon" width="64" />

# Skredvarsel

The Skredvarsel (Avalanche warning) app is an iOS, iPadOS, and macOS application that provides daily avalanche warnings from the [Norwegian Avalanche Warning Service API](http://api.nve.no/doc/snoeskredvarsel/).

The main feature of the app is a set of beautiful widgets that can be added to the home screen on iOS and iPadOS, or the notification center on macOS. It is not intended to replace the official [Varsom Regobs app](https://apps.apple.com/us/app/varsom-regobs/id1450501601), but rather complement it with an app taking full advantage of the Apple platforms. Hence the code name iVarsom.

The app is also a learning exercise for myself to learn how to build and distribute a SwiftUI app for iOS, iPadOS, watchOS, and macOS.

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

- Xcode 16+
- Swift 6
- iOS 15+ / macOS 12+ / watchOS 8+

### Building from Source

```bash
git clone https://github.com/follesoe/iVarsom.git
cd iVarsom
open Skredvarsel.xcodeproj
```

Dependencies (SwiftLocation) are resolved automatically via Swift Package Manager.

### Running Tests

```bash
xcodebuild test -scheme Skredvarsel -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Architecture

The app uses SwiftUI with MVVM architecture. See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Privacy

The app collects no user data. Location is used only to find your local avalanche region (3km accuracy) and is not stored or transmitted beyond the initial API query.

## License

[MIT License](LICENSE) © Jonas Follesø
