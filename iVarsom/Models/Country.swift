import Foundation
import SwiftUI

private struct AccessibilityBridgeDisabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var accessibilityBridgeDisabled: Bool {
        get { self[AccessibilityBridgeDisabledKey.self] }
        set { self[AccessibilityBridgeDisabledKey.self] = newValue }
    }
}

extension View {
    /// Sets the locale so VoiceOver pronounces text in the region's native language.
    func speechLocale(for regionId: Int) -> some View {
        speechLocale(Country.from(regionId: regionId).languageCode)
    }

    /// Sets the locale and UIKit accessibilityLanguage so VoiceOver pronounces
    /// both rendered Text and String-based accessibility labels correctly.
    func speechLocale(_ code: String) -> some View {
        self.environment(\.locale, Locale(identifier: code))
        #if os(iOS)
            .modifier(AccessibilityBridgeModifier(language: code))
        #endif
    }
}

#if os(iOS)
/// Conditionally applies the AccessibilityLanguageBridge, skipping it
/// when `accessibilityBridgeDisabled` is set (e.g. inside ImageRenderer).
private struct AccessibilityBridgeModifier: ViewModifier {
    @Environment(\.accessibilityBridgeDisabled) private var bridgeDisabled
    let language: String

    func body(content: Content) -> some View {
        if bridgeDisabled {
            content
        } else {
            content.background(AccessibilityLanguageBridge(language: language))
        }
    }
}

/// Zero-size UIView that sets `accessibilityLanguage` on its parent
/// subtree. This bridges SwiftUI's locale environment to UIKit's
/// accessibility system, ensuring VoiceOver uses the correct speech
/// language for String-based accessibility labels.
///
/// Walks DOWN from the bridge's parent view to set language on all
/// descendants (including the actual accessibility elements). This
/// avoids polluting shared ancestor views in List/UICollectionView,
/// which would cause rows with different languages to overwrite
/// each other.
private struct AccessibilityLanguageBridge: UIViewRepresentable {
    let language: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let parent = view.superview else { return }
            Self.applyLanguage(language, to: parent)
        }
    }

    private static func applyLanguage(_ language: String, to view: UIView) {
        view.accessibilityLanguage = language
        for child in view.subviews {
            applyLanguage(language, to: child)
        }
    }
}
#endif

enum Country {
    case norway
    case sweden

    var languageCode: String {
        switch self {
        case .norway: return "nb"
        case .sweden: return "sv"
        }
    }

    private static let swedenOffset = 100000

    static let swedishAreaSlugs: [Int: String] = [
        1: "vastra_vindelfjallen",
        2: "abisko_riksgransfjallen",
        3: "sodra_jamtlandsfjallen",
        7: "vastra_harjedalsfjallen",
        8: "kebnekaisefjallen",
        9: "sodra_lapplandsfjallen"
    ]

    static func from(regionId: Int) -> Country {
        return regionId >= swedenOffset ? .sweden : .norway
    }

    static func swedishAreaId(from regionId: Int) -> Int {
        return regionId - swedenOffset
    }

    static func syntheticId(from areaId: Int) -> Int {
        return areaId + swedenOffset
    }

    static func swedishSlug(for regionId: Int) -> String? {
        return swedishAreaSlugs[swedishAreaId(from: regionId)]
    }
}
