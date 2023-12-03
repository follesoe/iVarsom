import Foundation
import SwiftUI

struct AvalancheWarningSimple: Codable, AvalancheWarningProtocol {
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
        case .unknown: return NSLocalizedString("Not assessed", comment: "")
        case .level1: return NSLocalizedString("Low", comment: "")
        case .level2: return NSLocalizedString("Moderate", comment: "")
        case .level3: return NSLocalizedString("Considerable", comment: "")
        case .level4: return NSLocalizedString("High", comment: "")
        case .level5: return NSLocalizedString("Very high", comment: "")
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
