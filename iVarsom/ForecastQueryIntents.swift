import AppIntents
import SwiftUI
import WidgetKit

/// Recent days people can say in a Siri phrase. App Shortcut phrases can't
/// contain dates, so spoken days are an enum; Shortcuts can pass any date.
/// Raw values are saved in shortcuts: add cases, but never rename or reorder.
enum PastForecastDay: String, AppEnum {
    case yesterday, lastMonday, lastTuesday, lastWednesday, lastThursday, lastFriday, lastSaturday, lastSunday

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Earlier day"
    static let caseDisplayRepresentations: [PastForecastDay: DisplayRepresentation] = [
        .yesterday: "yesterday",
        .lastMonday: "last Monday",
        .lastTuesday: "last Tuesday",
        .lastWednesday: "last Wednesday",
        .lastThursday: "last Thursday",
        .lastFriday: "last Friday",
        .lastSaturday: "last Saturday",
        .lastSunday: "last Sunday",
    ]

    /// Gregorian weekday, where Sunday is 1.
    private var weekday: Int? {
        switch self {
        case .yesterday: nil
        case .lastSunday: 1
        case .lastMonday: 2
        case .lastTuesday: 3
        case .lastWednesday: 4
        case .lastThursday: 5
        case .lastFriday: 6
        case .lastSaturday: 7
        }
    }

    /// Noon on the day in `calendar`. "Last Saturday" is the most recent
    /// Saturday before today.
    func date(before now: Date, calendar: Calendar) -> Date {
        let today = calendar.startOfDay(for: now)
        var daysBack = 1
        if let weekday {
            daysBack = (calendar.component(.weekday, from: today) - weekday + 7) % 7
            if daysBack == 0 { daysBack = 7 }
        }
        let day = calendar.date(byAdding: .day, value: -daysBack, to: today)!
        return calendar.date(byAdding: .hour, value: 12, to: day)!
    }
}

/// The forecast for a region on a chosen day, including past seasons.
struct GetAvalancheWarningForDateIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Avalanche Forecast for Date"
    static let description = IntentDescription(
        "Get the avalanche forecast published for a day in Norway or Sweden, including past seasons.")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Region", requestValueDialog: IntentDialog("Which region do you want the avalanche warning for?"))
    var region: RegionConfigOptionAppEntity

    @Parameter(title: "Date", kind: .date)
    var date: Date?

    /// Filled by Siri phrases; Shortcuts shows the date instead.
    @Parameter(title: "Earlier day")
    var pastDay: PastForecastDay?

    static var parameterSummary: some ParameterSummary {
        Summary("Get avalanche forecast for \(\.$region) on \(\.$date)")
    }

    init() {}

    init(pastDay: PastForecastDay) {
        self.pastDay = pastDay
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<AvalancheForecastEntity> & ProvidesDialog & ShowsSnippetView {
        guard let id = Int(region.id) else { throw ForecastError.invalidRegion }
        let regionID = try await ForecastRegionResolver.resolve(id, requestPermission: true)
        let day: Date
        if let date {
            day = ForecastLookup.regionDay(for: date, regionID: regionID)
        } else if let pastDay {
            day = pastDay.date(before: Date.current, calendar: ForecastSelection.calendar(regionID: regionID))
        } else {
            let requested = try await $date.requestValue(IntentDialog("Which day?"))
            day = ForecastLookup.regionDay(for: requested, regionID: regionID)
        }
        let language = answerLanguage
        let result = try await ForecastLookup.live(language: language.forecastLanguage).forecast(regionID: regionID, on: day)
        return result.intentResult(isVoiceOnly: isVoiceOnly, language: language)
    }
}

/// Forecasts for every favorite region, for a quick check before a trip.
struct GetFavoriteForecastsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Favorite Avalanche Forecasts"
    static let description = IntentDescription("Get published avalanche forecasts for your favorite regions.")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Forecast day", default: .today)
    var day: ForecastDay

    static var parameterSummary: some ParameterSummary {
        Summary("Get avalanche forecasts for my favorites") { \.$day }
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[AvalancheForecastEntity]> & ProvidesDialog & ShowsSnippetView {
        let favorites = FavoritesService.savedFavorites()
        guard !favorites.isEmpty else { throw ForecastError.noFavorites }
        let language = answerLanguage
        // One widget reload after all regions are saved, not one per favorite.
        let lookup = ForecastLookup.live(language: language.forecastLanguage, reloadWidgets: false)
        let day = day
        typealias Outcome = Swift.Result<ForecastLookup.Result, any Error>
        let outcomes = await withTaskGroup(of: (Int, Outcome)?.self) { group in
            for (index, id) in favorites.enumerated() {
                group.addTask {
                    guard let regionID = await Self.regionID(for: id) else { return nil }
                    do { return (index, .success(try await lookup.forecast(regionID: regionID, day: day))) }
                    catch { return (index, .failure(error)) }
                }
            }
            var outcomes: [(Int, Outcome)] = []
            for await outcome in group {
                if let outcome { outcomes.append(outcome) }
            }
            return outcomes.sorted { $0.0 < $1.0 }.map(\.1)
        }
        try Task.checkCancellation()
        // The current position can resolve to a region that is also a favorite.
        var seen = Set<Int>()
        let results = outcomes.compactMap { try? $0.get() }.filter { seen.insert($0.snapshot.regionID).inserted }
        guard !results.isEmpty else {
            throw ForecastError.combining(outcomes.compactMap { outcome -> (any Error)? in
                if case .failure(let error) = outcome { error } else { nil }
            })
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "iVarsomWidget")
        let entities = results.map {
            AvalancheForecastEntity(warning: $0.warning, snapshot: $0.snapshot, isCached: $0.isCached)
        }
        let dialog = ForecastAnswer.summary(for: results, isVoiceOnly: isVoiceOnly, language: language)
        return .result(value: entities, dialog: IntentDialog(stringLiteral: dialog)) {
            FavoriteForecastsSnippetView(results: results)
        }
    }

    /// The current-position favorite needs a location fix. Give up after a few
    /// seconds and leave it out, rather than delaying or failing the answer.
    private static func regionID(for favorite: Int) async -> Int? {
        guard favorite == RegionOption.currentPositionOption.id else {
            return try? await ForecastRegionResolver.resolve(favorite)
        }
        return await withTaskGroup(of: Int?.self) { group in
            group.addTask { try? await ForecastRegionResolver.resolve(favorite) }
            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}

/// One row per favorite: danger icon, region, danger level and, for a saved
/// forecast, when it was downloaded.
struct FavoriteForecastsSnippetView: View {
    let results: [ForecastLookup.Result]

    private static let downloadFormat = Date.FormatStyle.dateTime.day().month(.abbreviated).hour().minute()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(results, id: \.warning.RegionId) { result in
                let warning = result.warning
                HStack(spacing: 12) {
                    DangerIcon(dangerLevel: warning.DangerLevel)
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(warning.RegionName)
                            .font(.headline)
                        Text(warning.DangerLevel.localizedName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if result.isCached {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Saved forecast")
                                Text(result.snapshot.downloadedAt, format: Self.downloadFormat)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    if warning.hasActiveEmergencyWarning {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowLabel(for: result))
                .speechLocale(for: warning.RegionId)
            }
        }
        .padding()
    }

    private func rowLabel(for result: ForecastLookup.Result) -> String {
        let warning = result.warning
        var label = "\(warning.RegionName), "
            + String(localized: "Danger level \(warning.DangerLevel.description), \(warning.DangerLevel.localizedName)")
        if warning.hasActiveEmergencyWarning { label += ", " + String(localized: "Emergency warning") }
        if result.isCached {
            let downloaded = result.snapshot.downloadedAt.formatted(Self.downloadFormat)
            label += ". " + String(localized: "Saved forecast from \(downloaded).")
        }
        return label
    }
}
