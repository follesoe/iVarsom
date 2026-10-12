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

    struct RegionConfigOptionAppEntityQuery: EntityStringQuery {
        func entities(for identifiers: [RegionConfigOptionAppEntity.ID]) async throws -> [RegionConfigOptionAppEntity] {
            // Restoring a saved current-position choice must not depend on the
            // current authorization state. Permission is checked on execution.
            identifiers.compactMap { id in
                RegionOption.allOptions.first(where: { String($0.id) == id }).map(RegionConfigOptionAppEntity.init)
            }
        }

        func entities(matching string: String) async throws -> [RegionConfigOptionAppEntity] {
            Self.matching(string, in: RegionOption.allOptions).map(RegionConfigOptionAppEntity.init)
        }

        static func matching(_ string: String, in options: [RegionOption]) -> [RegionOption] {
            func normalized(_ value: String) -> String {
                value.replacingOccurrences(of: "\u{200B}", with: "")
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
                    .replacingOccurrences(of: "ø", with: "o")
                    .replacingOccurrences(of: "æ", with: "ae")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let query = normalized(string)
            return options.filter { query.isEmpty || normalized($0.name).contains(query) || String($0.id) == query }
        }

        func suggestedEntities() async throws -> [RegionConfigOptionAppEntity] {
            await RegionConfigOptionAppEntity.allRegions()
        }
        
        func defaultResult() async -> RegionConfigOptionAppEntity? {
            nil
        }
    }
    
    @MainActor
    static func allRegions() async -> [RegionConfigOptionAppEntity] {
        let authorized = (try? await LocationManager().checkWidgetAuthorization()) ?? false
        let options = authorized ?
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

    init(_ option: RegionOption) {
        self.init(id: String(option.id), displayString: option.name)
        regionId = option.id
    }
}
