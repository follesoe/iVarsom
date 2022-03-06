import Foundation

struct RegionSummary: Codable {
    var Id: Int
    var Name: String
    var TypeName: String
    var AvalancheWarningList: [AvalancheWarningSimple]
}

extension RegionSummary: Identifiable {
    var id: Int { return Id }
}
