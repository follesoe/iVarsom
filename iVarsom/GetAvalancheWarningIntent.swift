import AppIntents
import Foundation

struct GetAvalancheWarningIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Avalanche Warning"
    static let description = IntentDescription("Get a published avalanche forecast for Norway or Sweden.")
    /// Answers in Siri and Shortcuts without opening the app.
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Region", requestValueDialog: IntentDialog("Which region do you want the avalanche warning for?"))
    var region: RegionConfigOptionAppEntity

    @Parameter(title: "Forecast day", default: .today)
    var day: ForecastDay

    static var parameterSummary: some ParameterSummary {
        Summary("Get avalanche warning for \(\.$region)") { \.$day }
    }

    init() {}

    /// Presets the day for an App Shortcut, leaving the region to the phrase.
    init(day: ForecastDay) {
        self.day = day
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<AvalancheForecastEntity> & ProvidesDialog & ShowsSnippetView {
        let language = answerLanguage
        do {
            guard let id = Int(region.id) else { throw ForecastError.invalidRegion }
            let resolvedID = try await ForecastRegionResolver.resolve(id, requestPermission: true)
            let result = try await ForecastLookup.live(language: language.forecastLanguage)
                .forecast(regionID: resolvedID, day: day)
            return result.intentResult(isVoiceOnly: isVoiceOnly, language: language)
        } catch let error as ForecastError {
            throw error.worded(in: language)
        }
    }
}

extension ForecastLookup.Result {
    /// The returned entity, answer and snippet shared by the forecast intents.
    func intentResult(isVoiceOnly: Bool, language: ForecastAnswerLanguage)
        -> some IntentResult & ReturnsValue<AvalancheForecastEntity> & ProvidesDialog & ShowsSnippetView
    {
        let entity = AvalancheForecastEntity(
            warning: warning, snapshot: snapshot, isCached: isCached, archiveDay: archiveDay)
        let dialog = ForecastAnswer.dialog(
            for: warning, downloadedAt: snapshot.downloadedAt, isCached: isCached,
            isVoiceOnly: isVoiceOnly, language: language)
        return .result(value: entity, dialog: IntentDialog(stringLiteral: dialog)) {
            AvalancheWarningSnippetView(warning: warning, error: nil,
                downloadedAt: snapshot.downloadedAt, isCached: isCached)
        }
    }
}
