import Foundation

public enum DangerLevel: String, Codable, CustomStringConvertible {
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
}
