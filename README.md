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

## macOS

<img src="images/macBookScreenshot.webp" alt="App running on macOS" />

<a href="https://apps.apple.com/app/skredvarsel/id1613060787">
    <img src="images/DownloadOnTheMacAppStore.svg" alt="Download on the Mac App Store" />
</a>

## Beta testing

Join the [beta testing group on TestFlight](https://testflight.apple.com/join/8IeX64AS).

## Learning points covered by the app

The app is primarily a learning exercise to familiarize myself with SwiftUI and modern development practices on iOS, iPadOS, macOS and watchOS. This section will list some of the concepts covered in the app, with references to the learning materials I used for the different topics. 

### SwiftUI

The app is developed entirely in SwiftUI. The first prototype was actually developed on an iPad using [Swift Playgrounds](https://www.apple.com/swift/playgrounds/). The built-in learning programmes in Swift Playground is a nice introduction to the Swift language and SwiftUI. However, due to the lack of Widget support I had to move to full Xcode for most of the development.

The app makes extensive use of SwiftUI previews, and the listed WWDC presentation was of great help to make the most of this feature.

The Introducing SwiftUI tutorial from Apple is also a great way to get familiar with SwiftUI.

* [Introducing SwiftUI tutorial](https://developer.apple.com/tutorials/swiftui)
* [WWDC20: Introduction to SwiftUI](https://developer.apple.com/wwdc20/10119)
* [WWDC20: App essentials in SwiftUI](https://developer.apple.com/wwdc20/10037)
* [WWDC21: What's new in SwiftUI](https://developer.apple.com/wwdc21/10018)
* [WWDC20: Structure your app for SwiftUI previews](https://developer.apple.com/wwdc20/10149)
* [WWDC21: Add rich graphics to your SwiftUI app](https://developer.apple.com/wwdc21/10021)
* [WWDC20: Data Essentials in SwiftUI](https://developer.apple.com/wwdc20/10040)

### WidgetKit

Widgets is the key feature of the app, so I spent quite some time learning about Widgets. The app uses intents for configuration, including color customizations to the configuration interface.

* [WWDC20: Meet WidgetKit](https://developer.apple.com/wwdc20/10028)
* [WWDC20: Build SwiftUI views for widgets](https://developer.apple.com/wwdc20/10033)
* [WWDC20: Widgets Code-along, part 1](https://developer.apple.com/wwdc20/10034)
* [WWDC20: Widgets Code-along, part 2](https://developer.apple.com/wwdc20/10035)
* [WWDC20: Widgets Code-along, part 3](https://developer.apple.com/wwdc20/10036)
* [WWDC21: Principles of great widgets](https://developer.apple.com/wwdc21/10048)
* [WWDC20: Add configuration and intelligence to your widgets](https://developer.apple.com/wwdc20/10194)

### Localization

The app is localized in Norwegian and English language.

* [WWDC21: Localize your SwiftUI app](https://developer.apple.com/wwdc21/10220)
* [WWDC21: Streamline your localized strings](https://developer.apple.com/wwdc21/10221)

### Swift Packages

The app uses the open source package [DynamicColor](https://github.com/yannickl/DynamicColor) in the `DangerGradient.swift` file to dynamically generate the gradient background of the warning views.

* [WWDC21: What's new in Swift](https://developer.apple.com/wwdc21/10192)

### Concurrency and asynchronous code

The app uses `async/await` for network operations in the `VarsomApiClient.swift` file.

* [WWDC21: Meet async/await in Swift](https://developer.apple.com/wwdc21/10132)
* [WWDC2!: Discover concurrency in SwiftUI](https://developer.apple.com/wwdc21/10019)