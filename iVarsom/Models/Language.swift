import SwiftUI

public enum Language: CustomStringConvertible {
    case norwegian
    case english
    
    public var description: String {
        switch self {
        case .norwegian: return "1"
        case .english: return "2"
        }
    }
    
    public static func fromLocale() -> Language {
        let identifier = Locale.current.identifier
        return identifier.starts(with: "nb") ? .norwegian : .english
    }
}
