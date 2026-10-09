import Foundation

protocol LavinprognoserAPIProviding: Sendable {
    func loadRegions() async throws -> [RegionSummary]
    func loadWarnings(regionId: Int, daysBefore: Int) async throws -> [AvalancheWarningSimple]
    func loadWarningsDetailed(regionId: Int, daysBefore: Int) async throws -> [AvalancheWarningDetailed]
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
        case invalidUrlError
        case parseError
    }

    private let baseUrl = "https://lavinprognoser.se"

    // MARK: - Public Methods

    func loadRegions() async throws -> [RegionSummary] {
        let useSwedish = VarsomApiClient.currentLang() == .norwegian
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

    func loadWarningsDetailed(regionId: Int, daysBefore: Int = 1) async throws -> [AvalancheWarningDetailed] {
        guard let slug = Country.swedishSlug(for: regionId) else { throw LavinError.invalidUrlError }

        // Fetch today + previous days by explicit date to avoid gaps.
        // The "current" (no date) endpoint returns the active forecast which
        // may be tomorrow's after 18:00, skipping today entirely.
        let today = now()
        let warnings = try await withThrowingTaskGroup(of: AvalancheWarningDetailed?.self) { group in
            for day in 0...max(0, daysBefore) {
                let date = Calendar.current.date(byAdding: .day, value: -day, to: today)!
                group.addTask {
                    do {
                        return try await self.loadForecast(slug: slug, regionId: regionId, date: date)
                    } catch {
                        // Missing historical bulletins are normal; cancellation must still propagate.
                        try Task.checkCancellation()
                        if error is CancellationError { throw error }
                        if (error as? URLError)?.code == .cancelled { throw error }
                        return nil
                    }
                }
            }
            var result = [AvalancheWarningDetailed]()
            for try await warning in group {
                if let warning { result.append(warning) }
            }
            try Task.checkCancellation()
            return result.sorted { $0.ValidFrom < $1.ValidFrom }
        }

        guard !warnings.isEmpty else { throw LavinError.requestError }
        return warnings
    }

    private func loadForecast(slug: String, regionId: Int, date: Date?) async throws -> AvalancheWarningDetailed {
        let useSwedish = VarsomApiClient.currentLang() == .norwegian
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
            dateFormatter.dateFormat = "yyyy-MM-dd"
            urlString += "?forecast_date=\(dateFormatter.string(from: date))"
        }

        guard let url = URL(string: urlString) else { throw LavinError.invalidUrlError }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await transport.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw LavinError.requestError }

        let detail = try JSONDecoder().decode(LavinprognoserResponse.DetailResponse.self, from: data)
        return LavinprognoserMapper(date: now(), languageKey: langKey)
            .warning(from: detail.content.forecast, regionId: regionId)
    }

    func loadWarnings(regionId: Int, daysBefore: Int = 1) async throws -> [AvalancheWarningSimple] {
        let detailed = try await loadWarningsDetailed(regionId: regionId, daysBefore: daysBefore)
        return detailed.map(\.summary)
    }

}
