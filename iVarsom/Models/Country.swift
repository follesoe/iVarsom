import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private func withSpeechLanguage(_ string: String, code: String) -> AttributedString {
    #if canImport(UIKit)
    let nsStr = NSMutableAttributedString(string: string)
    nsStr.addAttribute(.accessibilitySpeechLanguage, value: code, range: NSRange(location: 0, length: nsStr.length))
    if let result = try? AttributedString(nsStr, including: \.uiKit) {
        return result
    }
    #endif
    return AttributedString(string)
}

extension String {
    /// For region names — always use the region's native language.
    func speechLanguage(for regionId: Int) -> AttributedString {
        withSpeechLanguage(self, code: Country.from(regionId: regionId).languageCode)
    }

    /// For warning text — use the language the warning was loaded in,
    /// as stored on the model's textLanguageCode property.
    func warningTextSpeechLanguage(_ languageCode: String) -> AttributedString {
        withSpeechLanguage(self, code: languageCode)
    }
}

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
