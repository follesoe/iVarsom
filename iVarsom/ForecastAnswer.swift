import AppIntents
import Foundation

extension AppIntent {
    /// The language the person asked in (iOS 27), otherwise the app's language.
    var answerLanguage: ForecastAnswerLanguage {
        if #available(iOS 27, watchOS 27, *) {
            return ForecastAnswerLanguage(requestLocale: systemContext.locale)
        }
        return .app
    }

    /// Whether the person only hears the answer, for example on AirPods or in CarPlay (iOS 27).
    var isVoiceOnly: Bool {
        if #available(iOS 27, watchOS 27, *) { return systemContext.isVoiceOnly }
        return false
    }
}

/// Finds the bulletin Siri and Shortcuts answer with.
struct ForecastLookup: Sendable {
    struct Result: Sendable {
        let warning: AvalancheWarningSimple
        let snapshot: ForecastSnapshot
        let isCached: Bool
        /// Set for earlier days, which come from the provider's archive rather than the shared store.
        var archiveDay: Date? = nil
    }

    let repository: any WarningRepositoryProviding
    let store: SharedForecastStore
    let language: VarsomApiClient.Language
    var now: @Sendable () -> Date = { Date.current }

    /// The shared store keeps one snapshot per language, so answering in the
    /// request's language never replaces the widgets' forecast.
    /// Pass `reloadWidgets: false` when loading several regions, and reload once afterwards.
    static func live(language: VarsomApiClient.Language, reloadWidgets: Bool = true) -> ForecastLookup {
        ForecastLookup(
            repository: WarningRepository(cache: nil, language: { language }),
            store: SharedForecastStore(reloadWidgets: reloadWidgets), language: language)
    }

    /// The current or tomorrow's bulletin, falling back to the saved forecast offline.
    func forecast(regionID: Int, day: ForecastDay) async throws -> Result {
        try await current(regionID: regionID) { ForecastSelection.warning(in: $0, day: day, at: $1) }
    }

    /// The bulletin for a calendar day in the region's time zone. Today and the
    /// next two days use the current forecast, which includes the day after
    /// tomorrow once Norway publishes it early; earlier days come from the
    /// provider's archive and aren't stored.
    func forecast(regionID: Int, on day: Date) async throws -> Result {
        let now = now()
        let calendar = ForecastSelection.calendar(regionID: regionID)
        let offset = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: day)).day ?? 0
        switch offset {
        case 0...2:
            var result: Result
            do {
                // Select by day rather than validity: after 18:00, Sweden's valid
                // bulletin is already tomorrow's. Unpublished days are left out.
                result = try await current(regionID: regionID) { ForecastSelection.warning(in: $0, on: day, at: $1) }
            } catch let error as ForecastError where offset == 0 && (error == .noForecast || error == .unavailable) {
                // Sweden loads today's bulletin with a request of its own, which
                // can succeed when the current forecast fails, or fail when it
                // loads. Ask for the day, so its own answer decides.
                return try await archived(regionID: regionID, on: day, now: now)
            }
            // The entity query finds only valid bulletins in the shared store, so
            // an expired one, such as Sweden's today after 18:00, gets an
            // archive ID that Shortcuts can fetch again.
            if result.warning.validityEnd <= now { result.archiveDay = day }
            return result
        case 3...: throw ForecastError.noForecast  // Not published yet.
        default: return try await archived(regionID: regionID, on: day, now: now)
        }
    }

    /// The bulletin for a day from the provider's archive, which isn't stored.
    private func archived(regionID: Int, on day: Date, now: Date) async throws -> Result {
        let warnings: [AvalancheWarningSimple]
        do {
            warnings = try await repository.loadWarnings(on: day, regionID: regionID)
        } catch {
            try error.rethrowCancellation()
            // Days without a bulletin come back as an empty list (Norway) or
            // as not found (Sweden). Anything else, including a response the
            // app can't read, is a failed request.
            let isMissing = (error as? LavinprognoserApiClient.LavinError) == .notFound
            throw isMissing ? ForecastError.noForecast : ForecastError.unavailable
        }
        guard let warning = ForecastSelection.warning(in: warnings, on: day, at: now) else {
            throw ForecastError.noForecast
        }
        let snapshot = ForecastSnapshot(
            regionID: regionID, language: SharedForecastStore.languageKey(regionID: regionID, language: language),
            requestStartedAt: now, downloadedAt: now, warnings: warnings)
        return Result(warning: warning, snapshot: snapshot, isCached: false, archiveDay: day)
    }

    /// Loads the current forecast, or the saved one offline, and picks a bulletin
    /// from it with `select`, which receives the bulletins and the current time.
    private func current(
        regionID: Int, select: ([AvalancheWarningSimple], Date) -> AvalancheWarningSimple?
    ) async throws -> Result {
        let language = language
        let service = ForecastService(repository: repository, store: store, now: now, language: { language })
        let loaded = try await service.load(regionID: regionID)
        guard let warning = select(loaded.snapshot.warnings, now()) else { throw ForecastError.noForecast }
        return Result(warning: warning, snapshot: loaded.snapshot, isCached: loaded.isCached)
    }

    /// The same calendar day in the region's time zone, at noon. Shortcuts
    /// supplies dates at midnight in the person's time zone. The day is read in
    /// the Gregorian calendar, which the regions use, whatever calendar the
    /// person has chosen.
    static func regionDay(for date: Date, regionID: Int, timeZone: TimeZone = .current) -> Date {
        var personCalendar = Calendar(identifier: .gregorian)
        personCalendar.timeZone = timeZone
        var components = personCalendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        return ForecastSelection.calendar(regionID: regionID).date(from: components) ?? date
    }
}

/// A forecast error worded in a Siri request's language (iOS 27), like the
/// answers. Siri reads `errorDescription`, which ForecastError gives in the
/// app's language.
struct ForecastAnswerError: LocalizedError {
    let error: ForecastError
    let errorDescription: String?
}

extension ForecastError {
    func worded(in language: ForecastAnswerLanguage) -> ForecastAnswerError {
        ForecastAnswerError(error: self, errorDescription: language.string(key))
    }

    /// One error for several regions that all failed. Only when every region
    /// has no bulletin is it "no forecast", so a failed connection isn't
    /// reported as a missing forecast.
    static func combining(_ errors: [any Error]) -> ForecastError {
        guard !errors.isEmpty, errors.allSatisfy({ ($0 as? ForecastError) == .noForecast }) else {
            return .unavailable
        }
        return .noForecast
    }
}

/// The language of a Siri or Shortcuts forecast answer.
struct ForecastAnswerLanguage {
    /// The bulletin language to request from the forecast provider.
    let forecastLanguage: VarsomApiClient.Language
    /// Formats dates in the answer.
    let locale: Locale
    /// The app localization used for the answer's wording.
    let bundle: Bundle

    /// The app's own language, used before iOS 27 reports a request's locale.
    static var app: ForecastAnswerLanguage {
        ForecastAnswerLanguage(forecastLanguage: VarsomApiClient.currentLang(), locale: .current, bundle: .main)
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension ForecastAnswerLanguage {
    /// The language a person used for a request. Bulletin text comes from the
    /// providers, so the app can't localize it afterwards; requesting it in the
    /// person's language follows Apple's guidance for server-generated results.
    init(requestLocale: Locale, bundle: Bundle = .main) {
        forecastLanguage = VarsomApiClient.language(for: requestLocale)
        locale = requestLocale
        self.bundle = Self.localization(for: requestLocale, in: bundle)
    }

    /// The app localization closest to `locale`, or `bundle` itself when none matches.
    static func localization(for locale: Locale, in bundle: Bundle) -> Bundle {
        // Base holds the keys, not the English values.
        let preferred = Bundle.preferredLocalizations(
            from: bundle.localizations.filter { $0 != "Base" }, forPreferences: [locale.identifier(.bcp47)])
        guard let name = preferred.first, let path = bundle.path(forResource: name, ofType: "lproj"),
            let localized = Bundle(path: path)
        else { return bundle }
        return localized
    }
}

/// The dialog for a forecast answer in Siri or Shortcuts.
enum ForecastAnswer {
    /// A short answer covering several regions, such as the person's favorites.
    /// Emergency warnings come first, then regions without an answer and regions
    /// using a saved forecast; at most `limit` regions are read out.
    /// - Parameters:
    ///   - isVoiceOnly: Whether the person only hears the answer. Without the
    ///     snippet, the answer says when saved forecasts were downloaded.
    ///   - failed: Regions whose forecast couldn't be loaded.
    ///   - withoutForecast: Regions without a bulletin for the day.
    static func summary(
        for results: [ForecastLookup.Result], failed: [String] = [], withoutForecast: [String] = [],
        isVoiceOnly: Bool, language: ForecastAnswerLanguage, limit: Int = 4, now: Date = Date.current
    ) -> String {
        var parts: [String] = []
        let list = { (names: [String]) in names.formatted(.list(type: .and).locale(language.locale)) }
        let warnings = results.map(\.warning)
        let emergencies = warnings.filter(\.hasActiveEmergencyWarning).map(\.RegionName)
        if !emergencies.isEmpty {
            parts.append("\(language.string("Emergency warning")): \(list(emergencies)).")
        }
        // A region left out silently could hide an emergency warning.
        if !failed.isEmpty {
            parts.append(String(format: language.string("Error loading warnings for %@"), list(failed)))
        }
        if !withoutForecast.isEmpty {
            parts.append(String(format: language.string("No forecast for %@."), list(withoutForecast)))
        }
        let saved = results.filter(\.isCached)
        if let oldest = saved.min(by: { $0.snapshot.downloadedAt < $1.snapshot.downloadedAt }) {
            // When every region is saved, the regions go without saying.
            let regions = saved.count == results.count ? nil : list(saved.map(\.warning.RegionName))
            let time = savedTime(oldest.snapshot.downloadedAt, regionID: oldest.warning.RegionId, language: language)
            switch (isVoiceOnly, regions) {
            case (true, let regions?):
                parts.append(String(format: language.string("Saved forecast from %@: %@."), time, regions))
            case (true, nil): parts.append(String(format: language.string("Saved forecast from %@."), time))
            case (false, let regions?): parts.append(String(format: language.string("Saved forecast: %@."), regions))
            case (false, nil): parts.append(language.string("Saved forecast") + ".")
            }
        }
        // After Sweden's 18:00 changeover, a current forecast can be tomorrow's
        // while Norway's is today's; then each region says its day.
        let days = warnings.map {
            ForecastSelection.dayLabel(
                $0.ValidFrom, regionID: $0.RegionId, now: now, locale: language.locale, midSentence: true)
        }
        let showsDays = Set(days).count > 1
        for (warning, day) in zip(warnings, days).prefix(limit) {
            let danger = warning.DangerLevel.localizedName(in: language.bundle)
            let region = showsDays ? "\(warning.RegionName) (\(day))" : warning.RegionName
            parts.append(warning.DangerLevel == .unknown
                ? "\(region): \(danger)."
                : String(format: language.string("%@: level %@, %@."),
                    region, warning.DangerLevel.description, danger))
        }
        if warnings.count > limit {
            parts.append(String(format: language.string("And %lld more."), warnings.count - limit))
        }
        return parts.joined(separator: " ")
    }

    /// - Parameter isVoiceOnly: Whether the person only hears the answer. Without
    ///   the snippet, the answer says the date, the danger level number and when a
    ///   saved forecast was downloaded.
    static func dialog(
        for warning: AvalancheWarningSimple, downloadedAt: Date, isCached: Bool,
        isVoiceOnly: Bool, language: ForecastAnswerLanguage, now: Date = Date.current
    ) -> String {
        var parts: [String] = []
        let danger = warning.DangerLevel.localizedName(in: language.bundle)
        if isCached {
            if isVoiceOnly {
                let saved = savedTime(downloadedAt, regionID: warning.RegionId, language: language)
                parts.append(String(format: language.string("Saved forecast from %@."), saved))
            } else {
                parts.append(language.string("Saved forecast") + ".")
            }
        }
        if isVoiceOnly, warning.DangerLevel != .unknown {
            // Say the year for days more than a week away, such as earlier seasons.
            var style = Date.FormatStyle(locale: language.locale).weekday(.wide).day().month(.wide)
            if abs(warning.ValidFrom.timeIntervalSince(now)) > 7 * 86400 { style = style.year() }
            let date = ForecastSelection.dateText(warning.ValidFrom, regionID: warning.RegionId, style: style)
            parts.append(String(
                format: language.string("The avalanche danger in %@ for %@ is level %@, %@."),
                warning.RegionName, date, warning.DangerLevel.description, danger))
        } else {
            let date = ForecastSelection.dateText(
                warning.ValidFrom, regionID: warning.RegionId,
                style: Date.FormatStyle(date: .abbreviated, time: .omitted, locale: language.locale))
            parts.append(String(
                format: language.string("The avalanche danger level in %@ for %@ is %@."),
                warning.RegionName, date, danger))
        }
        // Emergency warnings matter most, and the snippet doesn't show them.
        if warning.hasActiveEmergencyWarning, let emergency = warning.EmergencyWarning {
            parts.append("\(language.string("Emergency warning")): \(emergency)")
        }
        parts.append(warning.MainText)
        return parts.joined(separator: " ")
    }

    /// When a saved forecast was downloaded, spoken in full, for example
    /// "Saturday 21 February at 10:00".
    private static func savedTime(_ date: Date, regionID: Int, language: ForecastAnswerLanguage) -> String {
        ForecastSelection.dateText(
            date, regionID: regionID,
            style: Date.FormatStyle(locale: language.locale).weekday(.wide).day().month(.wide).hour().minute())
    }
}
