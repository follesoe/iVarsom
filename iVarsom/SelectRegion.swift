import Foundation
import AppIntents

struct SelectRegion: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "SelectRegionIntent"

    static let title: LocalizedStringResource = "Select Region"
    static let description = IntentDescription("Select which region you wish to view avalanche warnings from")

    @Parameter(title: "Region")
    var region: RegionConfigOptionAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary()
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}


