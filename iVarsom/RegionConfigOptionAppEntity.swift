import Foundation
import AppIntents
import CoreLocation

struct RegionConfigOptionAppEntity: AppEntity {
    var id: String
    var displayString: String
    
    @Property(title: "Region Id")
    var regionId: Int?
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Region Config Option")
    static let defaultQuery = RegionConfigOptionAppEntityQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }

    struct RegionConfigOptionAppEntityQuery: EntityQuery {
        func entities(for identifiers: [RegionConfigOptionAppEntity.ID]) async throws -> [RegionConfigOptionAppEntity] {
            RegionConfigOptionAppEntity.allRegions().filter { identifiers.contains($0.id) }
        }

        func suggestedEntities() async throws -> [RegionConfigOptionAppEntity] {
            RegionConfigOptionAppEntity.allRegions()
        }
        
        func defaultResult() async -> RegionConfigOptionAppEntity? {
            nil
        }
    }
    
    static func allRegions() -> [RegionConfigOptionAppEntity] {
        let options = LocationManager().isAuthorizedForWidgetUpdates ?
            RegionOption.allOptions : RegionOption.aRegions + RegionOption.swedenRegions

        return options.map { region in
            let option = RegionConfigOptionAppEntity(
                id: "\(region.id)",
                displayString: region.name)
            option.regionId = region.id
            return option
        }
    }

    init(id: String, displayString: String) {
        self.id = id
        self.displayString = displayString
    }
}
