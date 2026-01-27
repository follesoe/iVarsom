import AppIntents
import Foundation

struct GetAvalancheWarningIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Avalanche Warning"
    static let description = IntentDescription(
        LocalizedStringResource("Get the current avalanche danger level for a region in Norway"))

    @Parameter(title: "Region", requestValueDialog: IntentDialog("Which region do you want the avalanche warning for?"))
    var region: RegionConfigOptionAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get avalanche warning for \(\.$region)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let regionId = region.regionId ?? RegionOption.defaultOption.id
        let regionName = region.displayString

        let client = VarsomApiClient()
        let today = Date.current

        let warnings: [AvalancheWarningSimple]

        do {
            // Check if this is the "current position" option (id = 1)
            if regionId == RegionOption.currentPositionOption.id {
                let locationManager = LocationManager()

                guard locationManager.isAuthorized else {
                    return .result(
                        dialog: IntentDialog(LocalizedStringResource("Location access is required to get warnings for your current position.")))
                    {
                        AvalancheWarningSnippetView(warning: nil, error: String(localized: "Location access required"))
                    }
                }

                guard let location = try await locationManager.updateLocation() else {
                    return .result(
                        dialog: IntentDialog(LocalizedStringResource("Could not determine your current location.")))
                    {
                        AvalancheWarningSnippetView(warning: nil, error: String(localized: "Location unavailable"))
                    }
                }

                warnings = try await client.loadWarnings(
                    lang: VarsomApiClient.currentLang(),
                    coordinate: location,
                    from: today,
                    to: today)
            } else {
                warnings = try await client.loadWarnings(
                    lang: VarsomApiClient.currentLang(),
                    regionId: regionId,
                    from: today,
                    to: today)
            }
        } catch {
            let dialog: IntentDialog
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                dialog = IntentDialog(LocalizedStringResource("No internet connection. Unable to retrieve avalanche warnings."))
            } else {
                dialog = IntentDialog(LocalizedStringResource("Unable to retrieve avalanche warnings. Please try again later."))
            }
            return .result(dialog: dialog) {
                AvalancheWarningSnippetView(warning: nil, error: String(localized: "Service unavailable"))
            }
        }

        guard let todayWarning = warnings.first else {
            return .result(
                dialog: IntentDialog(LocalizedStringResource("No avalanche warning available for \(regionName) today.")))
            {
                AvalancheWarningSnippetView(warning: nil, error: String(localized: "No warning available"))
            }
        }

        let dangerLevelName = String(localized: LocalizedStringResource(stringLiteral: todayWarning.DangerLevelName))
        let actualRegionName = todayWarning.RegionName
        let mainText = todayWarning.MainText.trimmingCharacters(in: .whitespacesAndNewlines)

        let dialog: IntentDialog
        if mainText.isEmpty {
            dialog = IntentDialog(LocalizedStringResource(
                "The avalanche danger level in \(actualRegionName) is \(dangerLevelName)."))
        } else {
            dialog = IntentDialog(LocalizedStringResource(
                "The avalanche danger level in \(actualRegionName) is \(dangerLevelName). \(mainText)"))
        }

        return .result(dialog: dialog) {
            AvalancheWarningSnippetView(warning: todayWarning, error: nil)
        }
    }

    static let openAppWhenRun: Bool = false
}
