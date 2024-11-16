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
}
