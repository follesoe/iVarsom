import Foundation
import SwiftUI

struct AvalancheWarningSimple: Codable {
    var RegId: Int
    var RegionId: Int
    var RegionName: String
    var RegionTypeName: String
    var ValidFrom: Date
    var ValidTo: Date
    var NextWarningTime: Date
    var PublishTime: Date
    var DangerLevel: DangerLevel
    var MainText: String
    var LangKey: Int
    
    var DangerLevelNumeric: Float {
        return Float(DangerLevel.rawValue) ?? 0
    }
    
    var DangerLevelName: String {
        switch DangerLevel {
        case .unknown: return "Not assessed"
        case .level1: return "Low"
        case .level2: return "Moderate"
        case .level3: return "Considerable"
        case .level4: return "High"
        case .level5: return "Very high"
        }
    }
    
    var VarsomUrl: URL {
        let argumentDateFormatter = DateFormatter()
        argumentDateFormatter.dateFormat = "yyyy-MM-dd"
        let warningDate = argumentDateFormatter.string(from: ValidFrom)
        let encodedName = RegionName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        if (Locale.current.identifier.starts(with: "nb")) {
            return URL(string: "https://varsom.no/snoskredvarsling/varsel/\(encodedName)/\(warningDate)")!
        } else {
            return URL(string: "https://varsom.no/en/avalanche-bulletins/forecast/\(encodedName)/\(warningDate)")!
        }
    }
}

extension AvalancheWarningSimple: Identifiable {
    var id: Int { RegId }
}
