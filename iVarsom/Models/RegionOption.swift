import Foundation
import AppIntents

struct RegionOption: AppEntity, Codable, Identifiable {
    var id: Int
    var name: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Region"
      var displayRepresentation: DisplayRepresentation {
        .init(stringLiteral: name)
      }

    static var defaultQuery = RegionQuery()
    
    public static let aRegions = [
        RegionOption(id: 3003, name: "Norden​skiöld Land"),
        RegionOption(id: 3006, name: "Finnmarks​kysten"),
        RegionOption(id: 3007, name: "Vest-Finn​mark"),
        RegionOption(id: 3009, name: "Nord-Troms"),
        RegionOption(id: 3010, name: "Lyngen"),
        RegionOption(id: 3011, name: "Tromsø"),
        RegionOption(id: 3012, name: "Sør-Troms"),
        RegionOption(id: 3013, name: "Indre Troms"),
        RegionOption(id: 3014, name: "Lofoten og Vesterålen"),
        RegionOption(id: 3015, name: "Ofoten"),
        RegionOption(id: 3016, name: "Salten"),
        RegionOption(id: 3017, name: "Svartisen"),
        RegionOption(id: 3018, name: "Helgeland"),
        RegionOption(id: 3022, name: "Troll​heimen"),
        RegionOption(id: 3023, name: "Romsdal"),
        RegionOption(id: 3024, name: "Sunnmøre"),
        RegionOption(id: 3027, name: "Indre Fjordane"),
        RegionOption(id: 3028, name: "Jotun​heimen"),
        RegionOption(id: 3029, name: "Indre Sogn"),
        RegionOption(id: 3031, name: "Voss"),
        RegionOption(id: 3032, name: "Hallingdal"),
        RegionOption(id: 3034, name: "Hardanger"),
        RegionOption(id: 3035, name: "Vest-Telemark"),
        RegionOption(id: 3037, name: "Heiane")
    ]
    
    public static func getName(id: Int, def: String) -> String {
        return aRegions.first(where: { $0.id == id })?.name ?? def
    }
    
    public static let allOptions = [currentPositionOption] + aRegions
    public static let currentPositionOption = RegionOption(id: 1, name: String(localized: "Current position"))
    public static let defaultOption = RegionOption(id: 3022, name: "Trollheimen")
}
