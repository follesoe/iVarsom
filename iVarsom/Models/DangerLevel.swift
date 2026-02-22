import Foundation
import SwiftUI

public enum DangerLevel: String, Codable, Sendable, CustomStringConvertible {
    case unknown = "0"
    case level1 = "1"
    case level2 = "2"
    case level3 = "3"
    case level4 = "4"
    case level5 = "5"
    
    public var description: String {
        switch self {
        case .unknown: return "?"
        default: return rawValue
        }
    }
    
    public var color: Color {
        return Color("DangerLevel\(self.rawValue)")
    }

    public var localizedName: String {
        switch self {
        case .unknown: return String(localized: "Not assessed")
        case .level1: return String(localized: "Low")
        case .level2: return String(localized: "Moderate")
        case .level3: return String(localized: "Considerable")
        case .level4: return String(localized: "High")
        case .level5: return String(localized: "Very high")
        }
    }
}
