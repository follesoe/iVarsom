#if !targetEnvironment(macCatalyst)
import AppIntents
import SwiftUI
import WidgetKit

struct OpenForecastControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Open avalanche forecast"
    @Parameter(title: "Region") var region: RegionConfigOptionAppEntity?
}

struct OpenForecastControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "OpenAvalancheForecast", intent: OpenForecastControlConfiguration.self) { configuration in
            ControlWidgetButton(action: OpenRegionIntent(region: configuration.region
                ?? RegionConfigOptionAppEntity(RegionOption.currentPositionOption))) {
                Label("Open avalanche forecast", systemImage: "mountain.2")
            }
        }
        .displayName("Open avalanche forecast")
        .description("Open a selected region, or use your current position.")
    }
}
#endif
