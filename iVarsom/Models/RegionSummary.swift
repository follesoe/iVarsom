import Foundation

struct RegionSummary: Sendable {
    var Id: Int
    var Name: String
    var TypeName: String
    var AvalancheWarningList: [AvalancheWarningSimple]
}

extension RegionSummary: Identifiable, Codable, Hashable {
    var id: Int { return Id }
    
    static func == (lhs: RegionSummary, rhs: RegionSummary) -> Bool {
        return lhs.Id == rhs.Id && lhs.Name == rhs.Name && lhs.TypeName == rhs.TypeName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(Id)
        hasher.combine(Name)
        hasher.combine(TypeName)
    }
}
