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
        let language = language
        let service = ForecastService(repository: repository, store: store, now: now, language: { language })
        let loaded = try await service.load(regionID: regionID)
        guard let warning = ForecastSelection.warning(in: loaded.snapshot.warnings, day: day, at: now()) else {
            throw ForecastError.noForecast
        }
        return Result(warning: warning, snapshot: loaded.snapshot, isCached: loaded.isCached)
    }

    /// The bulletin for a calendar day in the region's time zone. Today and
    /// tomorrow use the current forecast; earlier days come from the provider's
    /// archive and aren't stored.
    func forecast(regionID: Int, on day: Date) async throws -> Result {
        let now = now()
        let calendar = ForecastSelection.calendar(regionID: regionID)
        let offset = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: day)).day ?? 0
        switch offset {
        case 0: return try await forecast(regionID: regionID, day: .today)
        case 1: return try await forecast(regionID: regionID, day: .tomorrow)
        case 2...: throw ForecastError.noForecast  // Not published yet.
        default:
            let warnings: [AvalancheWarningSimple]
            do {
                warnings = try await repository.loadWarnings(on: day, regionID: regionID)
            } catch {
                try error.rethrowCancellation()
                // Days without a bulletin (such as summer) come back as an empty
                // list, a 404 or an empty page; anything else is a failed request.
                let isMissing = error is DecodingError || (error as? LavinprognoserApiClient.LavinError) == .notFound
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
    }

    /// The same calendar day in the region's time zone, at noon. Shortcuts
    /// supplies dates at midnight in the person's own time zone.
    static func regionDay(for date: Date, regionID: Int, calendar personCalendar: Calendar = .current) -> Date {
        var components = personCalendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        return ForecastSelection.calendar(regionID: regionID).date(from: components) ?? date
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
    /// Emergency warnings come first; at most `limit` regions are read out.
    static func summary(
        for warnings: [AvalancheWarningSimple], language: ForecastAnswerLanguage, limit: Int = 4
    ) -> String {
        var parts: [String] = []
        let emergencies = warnings.filter(\.hasActiveEmergencyWarning).map(\.RegionName)
        if !emergencies.isEmpty {
            parts.append("\(language.string("Emergency warning")): \(emergencies.formatted(.list(type: .and).locale(language.locale))).")
        }
        for warning in warnings.prefix(limit) {
            let danger = warning.DangerLevel.localizedName(in: language.bundle)
            parts.append(warning.DangerLevel == .unknown
                ? "\(warning.RegionName): \(danger)."
                : String(format: language.string("%@: level %@, %@."),
                    warning.RegionName, warning.DangerLevel.description, danger))
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
        if isVoiceOnly, warning.DangerLevel != .unknown {
            if isCached {
                let saved = ForecastSelection.dateText(
                    downloadedAt, regionID: warning.RegionId,
                    style: Date.FormatStyle(locale: language.locale).weekday(.wide).day().month(.wide)
                        .hour().minute())
                parts.append(String(format: language.string("Saved forecast from %@."), saved))
            }
            // Say the year for days more than a week away, such as earlier seasons.
            var style = Date.FormatStyle(locale: language.locale).weekday(.wide).day().month(.wide)
            if abs(warning.ValidFrom.timeIntervalSince(now)) > 7 * 86400 { style = style.year() }
            let date = ForecastSelection.dateText(warning.ValidFrom, regionID: warning.RegionId, style: style)
            parts.append(String(
                format: language.string("The avalanche danger in %@ for %@ is level %@, %@."),
                warning.RegionName, date, warning.DangerLevel.description, danger))
        } else {
            if isCached { parts.append(language.string("Saved forecast") + ".") }
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
}
