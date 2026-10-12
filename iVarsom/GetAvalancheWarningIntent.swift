import AppIntents
import Foundation

struct GetAvalancheWarningIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Avalanche Warning"
    static let description = IntentDescription("Get a published avalanche forecast for Norway or Sweden.")
    static let openAppWhenRun = false

    @Parameter(title: "Region", requestValueDialog: IntentDialog("Which region do you want the avalanche warning for?"))
    var region: RegionConfigOptionAppEntity

    @Parameter(title: "Forecast day", default: .today)
    var day: ForecastDay

    static var parameterSummary: some ParameterSummary {
        Summary("Get avalanche warning for \(\.$region)") { \.$day }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<AvalancheForecastEntity> & ProvidesDialog & ShowsSnippetView {
        guard let id = Int(region.id) else { throw ForecastError.invalidRegion }
        let resolvedID = try await ForecastRegionResolver.resolve(id, requestPermission: true)
        let loaded = try await ForecastService(store: SharedForecastStore(reloadWidgets: true)).load(regionID: resolvedID)
        guard let warning = ForecastSelection.warning(in: loaded.snapshot.warnings, day: day, at: Date.current) else {
            throw ForecastError.noForecast
        }
        let entity = AvalancheForecastEntity(warning: warning, snapshot: loaded.snapshot, isCached: loaded.isCached)
        let date = warning.formattedForecastDate(.init(date: .abbreviated, time: .omitted))
        let text = String(format: String(localized: "The avalanche danger level in %@ for %@ is %@."),
            warning.RegionName, date, warning.DangerLevel.localizedName)
        let saved = loaded.isCached ? String(localized: "Saved forecast") + ". " : ""
        return .result(value: entity, dialog: IntentDialog(stringLiteral: "\(saved)\(text) \(warning.MainText)")) {
            AvalancheWarningSnippetView(warning: warning, error: nil,
                downloadedAt: loaded.snapshot.downloadedAt, isCached: loaded.isCached)
        }
    }
}
