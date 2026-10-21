import Foundation

/// `lang` selects Swedish (`.norwegian`, the native-language bulletin) or English,
/// matching `VarsomAPIProviding`.
protocol LavinprognoserAPIProviding: Sendable {
    func loadRegions(lang: VarsomApiClient.Language) async throws -> [RegionSummary]
    func loadWarnings(lang: VarsomApiClient.Language, regionId: Int, daysBefore: Int) async throws
        -> [AvalancheWarningSimple]
    func loadWarningsDetailed(lang: VarsomApiClient.Language, regionId: Int, daysBefore: Int) async throws
        -> [AvalancheWarningDetailed]
    /// The bulletin for one forecast day, including past seasons.
    func loadWarningDetailed(lang: VarsomApiClient.Language, regionId: Int, date: Date) async throws
        -> AvalancheWarningDetailed
}

actor LavinprognoserApiClient: LavinprognoserAPIProviding {
    private let transport: any HTTPTransport
    private let now: @Sendable () -> Date

    init(transport: any HTTPTransport = URLSessionTransport(), now: @escaping @Sendable () -> Date = { Date.current }) {
        self.transport = transport
        self.now = now
    }

    enum LavinError: Error {
        case requestError
        /// The provider has no bulletin for the requested area and day.
        case notFound
        case invalidUrlError
        case parseError
    }

    private let baseUrl = "https://lavinprognoser.se"

    // MARK: - Public Methods

    func loadRegions(lang: VarsomApiClient.Language = VarsomApiClient.currentLang()) async throws -> [RegionSummary] {
        let useSwedish = lang == .norwegian
        let overviewPath = useSwedish ? "\(baseUrl)/.json" : "\(baseUrl)/en.json"
        let langKey = useSwedish ? 3 : 2  // 3=Swedish, 2=English
        guard let url = URL(string: overviewPath) else { throw LavinError.invalidUrlError }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await transport.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw LavinError.requestError }

        let overview = try JSONDecoder().decode(LavinprognoserResponse.OverviewResponse.self, from: data)
        return LavinprognoserMapper(date: now(), languageKey: langKey).regions(from: overview)
    }

    func loadWarningsDetailed(
        lang: VarsomApiClient.Language = VarsomApiClient.currentLang(), regionId: Int, daysBefore: Int = 1
    ) async throws -> [AvalancheWarningDetailed] {
        guard let slug = Country.swedishSlug(for: regionId) else { throw LavinError.invalidUrlError }

        // Fetch today + previous days by explicit date to avoid gaps.
        // The "current" (no date) endpoint returns the active forecast which
        // may be tomorrow's after 18:00, skipping today entirely.
        let today = now()
        let calendar = ForecastSelection.calendar(regionID: regionId)
        let firstDay = calendar.date(byAdding: .day, value: -max(0, daysBefore), to: calendar.startOfDay(for: today))!
        let endDay = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: today))!
        let dates: [Date?] = (0...max(0, daysBefore)).map {
            calendar.date(byAdding: .day, value: -$0, to: today)
        } + [nil] // The active endpoint includes the next bulletin after the evening changeover.
        let warnings = try await withThrowingTaskGroup(of: AvalancheWarningDetailed?.self) { group in
            for date in dates {
                group.addTask {
                    do {
                        return try await self.loadForecast(slug: slug, regionId: regionId, date: date, lang: lang)
                    } catch {
                        try error.rethrowCancellation()
                        // Only dated history is optional. Treat an active-endpoint
                        // failure as a failed refresh so repositories keep saved
                        // current bulletins instead of replacing them with history.
                        if date == nil { throw error }
                        return nil
                    }
                }
            }
            var result = [AvalancheWarningDetailed]()
            for try await warning in group {
                // The active endpoint follows the server's clock. Keep it in
                // the requested window, including tomorrow's evening bulletin.
                if let warning, warning.ValidFrom >= firstDay, warning.ValidFrom < endDay {
                    result.append(warning)
                }
            }
            try Task.checkCancellation()
            let unique = Dictionary(grouping: result, by: \.RegId).compactMap { _, revisions in
                revisions.max { $0.PublishTime < $1.PublishTime }
            }
            return unique.sorted { $0.ValidFrom < $1.ValidFrom }
        }

        guard !warnings.isEmpty else { throw LavinError.requestError }
        return warnings
    }

    func loadWarningDetailed(lang: VarsomApiClient.Language, regionId: Int, date: Date) async throws
        -> AvalancheWarningDetailed
    {
        guard let slug = Country.swedishSlug(for: regionId) else { throw LavinError.invalidUrlError }
        return try await loadForecast(slug: slug, regionId: regionId, date: date, lang: lang)
    }

    private func loadForecast(slug: String, regionId: Int, date: Date?, lang: VarsomApiClient.Language) async throws
        -> AvalancheWarningDetailed
    {
        let useSwedish = lang == .norwegian
        let langKey = useSwedish ? 3 : 2  // 3=Swedish, 2=English
        let basePath =
            useSwedish
            ? "\(baseUrl)/oversikt-alla-omraden/\(slug)"
            : "\(baseUrl)/en/current-avalanche-bulletins/\(slug)"

        var urlString = "\(basePath)/index.json"
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "Europe/Stockholm")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            urlString += "?forecast_date=\(dateFormatter.string(from: date))"
        }

        guard let url = URL(string: urlString) else { throw LavinError.invalidUrlError }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await transport.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode
        guard status == 200 else { throw status == 404 ? LavinError.notFound : LavinError.requestError }

        let detail = try JSONDecoder().decode(LavinprognoserResponse.DetailResponse.self, from: data)
        guard let forecast = detail.content.forecast else { throw LavinError.notFound }
        return LavinprognoserMapper(date: now(), languageKey: langKey).warning(from: forecast, regionId: regionId)
    }

    func loadWarnings(
        lang: VarsomApiClient.Language = VarsomApiClient.currentLang(), regionId: Int, daysBefore: Int = 1
    ) async throws -> [AvalancheWarningSimple] {
        let detailed = try await loadWarningsDetailed(lang: lang, regionId: regionId, daysBefore: daysBefore)
        return detailed.map(\.summary)
    }

}
