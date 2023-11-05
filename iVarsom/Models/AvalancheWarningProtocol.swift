import Foundation

protocol AvalancheWarningProtocol: Identifiable {
    var RegId: Int { get set }
    var RegionId: Int { get }
    var RegionName: String { get }
    var RegionTypeName: String { get }
    var ValidFrom: Date { get }
    var ValidTo: Date { get }
    var DangerLevel: DangerLevel { get }
    var MainText: String { get }
    var LangKey: Int { get }
}

extension AvalancheWarningProtocol {
    var id: Int { RegId }

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
}
