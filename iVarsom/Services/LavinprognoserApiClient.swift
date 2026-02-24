import Foundation

@MainActor
class LavinprognoserApiClient {

    enum LavinError: Error {
        case requestError
        case invalidUrlError
        case parseError
    }

    private let baseUrl = "https://lavinprognoser.se"


    // MARK: - Private Codable Response Models

    private struct OverviewResponse: Codable {
        let content: OverviewContent
    }

    private struct OverviewContent: Codable {
        let areaPageLinksArea: AreaPageLinksArea
    }

    private struct AreaPageLinksArea: Codable {
        let areaPageLinks: [AreaPageLink]
    }

    private struct AreaPageLink: Codable {
        let areaName: String
        let areaId: Int
        let risk: Int
        let url: String
        let riskText: String?
    }

    private struct DetailResponse: Codable {
        let content: DetailContent
    }

    private struct DetailContent: Codable {
        let forecast: LavinForecast
    }

    private struct LavinForecast: Codable {
        let id: Int
        let risk: Int
        let riskLabel: String?
        let areaId: Int
        let validTo: String
        let validFrom: String
        let changeDate: String?
        let publishedDate: String
        let location: String
        let recommendation: String?
        let assessmentContent: String?
        let avalancheProblem: LavinAvalancheProblemContainer?
    }

    private struct LavinAvalancheProblemContainer: Codable {
        let problems: [LavinProblem]?
    }

    private struct LavinProblem: Codable {
        let index: Int
        let problemId: Int
        let direction: LavinDirection
        let altitude: LavinAltitude
        let spread: LavinSpread?
        let description: LavinProblemDescription?
        let position: LavinPosition?
        let information: [LavinInformation]?
    }

    private struct LavinDirection: Codable {
        let northPanel: LavinPanel
        let northEastPanel: LavinPanel
        let eastPanel: LavinPanel
        let southEastPanel: LavinPanel
        let southPanel: LavinPanel
        let southWestPanel: LavinPanel
        let westPanel: LavinPanel
        let northWestPanel: LavinPanel
    }

    private struct LavinPanel: Codable {
        let state: Bool
    }

    private struct LavinAltitude: Codable {
        let altitudeMeterAboveTreeline: LavinAltitudeLevel
        let altitudeMeterTreeline: LavinAltitudeLevel
        let altitudeMeterBelowTreeline: LavinAltitudeLevel
    }

    private struct LavinAltitudeLevel: Codable {
        let state: Bool
    }

    private struct LavinSpread: Codable {
        let spreadId: Int?
        let sensitivityId: Int?
        let sizeMeterValue: Int?
        let spread: String?
        let sensitivity: String?
    }

    private struct LavinProblemDescription: Codable {
        let title: String?
    }

    private struct LavinPosition: Codable {
        let content: String?
    }

    private struct LavinInformation: Codable {
        let text: String?
        let description: String?
    }

    // MARK: - Public Methods

    func loadRegions() async throws -> [RegionSummary] {
        let useSwedish = VarsomApiClient.currentLang() == .norwegian
        let overviewPath = useSwedish ? "\(baseUrl)/.json" : "\(baseUrl)/en.json"
        let langKey = useSwedish ? 3 : 2  // 3=Swedish, 2=English
        guard let url = URL(string: overviewPath) else { throw LavinError.invalidUrlError }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw LavinError.requestError }

        let overview = try JSONDecoder().decode(OverviewResponse.self, from: data)
        return overview.content.areaPageLinksArea.areaPageLinks
            .filter { $0.areaId > 0 }
            .map { link in
                let syntheticId = Country.syntheticId(from: link.areaId)
                let dangerLevel = DangerLevel(rawValue: String(link.risk)) ?? .unknown
                let warning = AvalancheWarningSimple(
                    RegId: syntheticId,
                    RegionId: syntheticId,
                    RegionName: link.areaName,
                    RegionTypeName: "A",
                    ValidFrom: Date.current,
                    ValidTo: Calendar.current.date(byAdding: .day, value: 1, to: Date.current)!,
                    NextWarningTime: Calendar.current.date(byAdding: .day, value: 1, to: Date.current)!,
                    PublishTime: Date.current,
                    DangerLevel: dangerLevel,
                    MainText: link.riskText ?? "",
                    LangKey: langKey)
                return RegionSummary(
                    Id: syntheticId,
                    Name: link.areaName,
                    TypeName: "A",
                    AvalancheWarningList: [warning])
            }
    }

    func loadWarningsDetailed(regionId: Int, daysBefore: Int = 1) async throws -> [AvalancheWarningDetailed] {
        guard let slug = Country.swedishSlug(for: regionId) else { throw LavinError.invalidUrlError }

        // Fetch today + previous days by explicit date to avoid gaps.
        // The "current" (no date) endpoint returns the active forecast which
        // may be tomorrow's after 18:00, skipping today entirely.
        var tasks = [(day: Int, task: Task<AvalancheWarningDetailed, Error>)]()
        for day in 0...daysBefore {
            let date = Calendar.current.date(byAdding: .day, value: -day, to: Date.current)!
            let task = Task { try await self.loadForecast(slug: slug, regionId: regionId, date: date) }
            tasks.append((day, task))
        }

        var warnings = [AvalancheWarningDetailed]()
        // Add in chronological order (oldest first)
        for (_, task) in tasks.reversed() {
            if let warning = try? await task.value {
                warnings.append(warning)
            }
        }

        guard !warnings.isEmpty else { throw LavinError.requestError }
        return warnings
    }

    private func loadForecast(slug: String, regionId: Int, date: Date?) async throws -> AvalancheWarningDetailed {
        let useSwedish = VarsomApiClient.currentLang() == .norwegian
        let langKey = useSwedish ? 3 : 2  // 3=Swedish, 2=English
        let basePath = useSwedish
            ? "\(baseUrl)/oversikt-alla-omraden/\(slug)"
            : "\(baseUrl)/en/current-avalanche-bulletins/\(slug)"

        var urlString = "\(basePath)/index.json"
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            urlString += "?forecast_date=\(dateFormatter.string(from: date))"
        }

        guard let url = URL(string: urlString) else { throw LavinError.invalidUrlError }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw LavinError.requestError }

        let detail = try JSONDecoder().decode(DetailResponse.self, from: data)
        let forecast = detail.content.forecast

        let validTo = parseSwedishDate(forecast.validTo) ?? Calendar.current.date(byAdding: .day, value: 1, to: Date.current)!
        // Swedish forecasts are valid from 18:00 the previous day to 18:00 the forecast day.
        // Use validTo as the display date so the day picker shows the correct forecast day.
        let validFrom = validTo
        let publishDate = forecast.changeDate.flatMap { parseSwedishDate($0) }
            ?? parsePublishedDate(forecast.publishedDate)
            ?? Date.current

        let dangerLevel = DangerLevel(rawValue: String(forecast.risk)) ?? .unknown
        // assessmentContent is the forecaster-written text shown on the web page.
        // recommendation is a generic canned text for the danger level.
        // Use assessmentContent as the main text, falling back to recommendation.
        let mainText = forecast.assessmentContent.map { stripHtml($0) }
            ?? stripHtml(forecast.recommendation ?? "")

        let problems = forecast.avalancheProblem?.problems?.enumerated().map { (index, problem) in
            mapProblem(problem, index: index, dangerLevel: forecast.risk)
        }

        // Use forecast id combined with regionId for unique RegId
        let regId = regionId + forecast.id

        return AvalancheWarningDetailed(
            PreviousWarningRegId: nil,
            DangerLevelName: forecast.riskLabel,
            UtmZone: 0,
            UtmEast: 0,
            UtmNorth: 0,
            Author: nil,
            AvalancheDanger: nil,
            EmergencyWarning: nil,
            SnowSurface: nil,
            CurrentWeaklayers: nil,
            LatestAvalancheActivity: nil,
            LatestObservations: nil,
            ExposedHeightFill: 0,
            ExposedHeight1: 0,
            AvalancheProblems: problems,
            AvalancheAdvices: nil,
            RegId: regId,
            RegionId: regionId,
            RegionName: forecast.location,
            RegionTypeId: 0,
            RegionTypeName: "A",
            DangerLevel: dangerLevel,
            ValidFrom: validFrom,
            ValidTo: validTo,
            NextWarningTime: validTo,
            PublishTime: publishDate,
            MainText: mainText,
            LangKey: langKey)
    }

    func loadWarnings(regionId: Int, daysBefore: Int = 1) async throws -> [AvalancheWarningSimple] {
        let detailed = try await loadWarningsDetailed(regionId: regionId, daysBefore: daysBefore)
        return detailed.map { d in
            AvalancheWarningSimple(
                RegId: d.RegId,
                RegionId: d.RegionId,
                RegionName: d.RegionName,
                RegionTypeName: d.RegionTypeName,
                ValidFrom: d.ValidFrom,
                ValidTo: d.ValidTo,
                NextWarningTime: d.NextWarningTime,
                PublishTime: d.PublishTime,
                DangerLevel: d.DangerLevel,
                MainText: d.MainText,
                LangKey: d.LangKey,
                EmergencyWarning: d.EmergencyWarning)
        }
    }

    // MARK: - Mapping Helpers

    private func mapProblem(_ problem: LavinProblem, index: Int, dangerLevel: Int) -> AvalancheProblem {
        let typeId = mapProblemTypeId(problem.problemId)
        let typeName = problem.description?.title ?? mapProblemTypeName(problem.problemId)
        let expositions = mapExpositions(problem.direction)
        let (heightFill, height1, height2) = mapAltitude(problem.altitude)

        let spreadName = problem.spread?.spread ?? ""
        let sensitivityName = problem.spread?.sensitivity ?? ""

        // Use information descriptions for a more meaningful summary
        let triggerText = problem.information?
            .compactMap { $0.description }
            .map { stripHtml($0) }
            .filter { !$0.isEmpty }
            .joined(separator: " ") ?? [sensitivityName, spreadName].filter { !$0.isEmpty }.joined(separator: ", ")

        // Use position.content (risk management + characteristics) stripped of HTML
        let causeText = stripHtml(problem.position?.content ?? "")

        return AvalancheProblem(
            AvalancheProblemId: index + 1,
            AvalancheExtId: 0,
            AvalancheExtName: "",
            AvalCauseId: 0,
            AvalCauseName: causeText,
            AvalProbabilityId: 0,
            AvalProbabilityName: "",
            AvalTriggerSimpleId: 0,
            AvalTriggerSimpleName: "",
            AvalTriggerSensitivityId: problem.spread?.sensitivityId ?? 0,
            AvalTriggerSensitivityName: sensitivityName,
            DestructiveSizeExtId: 0,
            DestructiveSizeExtName: "",
            AvalPropagationId: problem.spread?.spreadId ?? 0,
            AvalPropagationName: spreadName,
            AvalancheTypeId: 0,
            AvalancheTypeName: "",
            AvalancheProblemTypeId: typeId,
            AvalancheProblemTypeName: typeName,
            ValidExpositions: expositions,
            ExposedHeight1: height1,
            ExposedHeight2: height2,
            ExposedHeightFill: heightFill,
            TriggerSenitivityPropagationDestuctiveSizeText: triggerText,
            DangerLevel: dangerLevel,
            DangerLevelName: "")
    }

    /// Map Swedish EAWS problemId to Norwegian TypeId for icon selection
    private func mapProblemTypeId(_ problemId: Int) -> Int {
        switch problemId {
        case 1: return 3   // New snow → AvalancheProblemNewSnow
        case 2: return 10  // Wind slab → AvalancheProblemDriftingSnow
        case 3: return 30  // Persistent slab → AvalancheProblemOldSnow
        case 4: return 5   // Wet snow → AvalancheProblemWetSnow
        case 5: return 50  // Glide snow → AvalancheProblemGlidingSnow
        case 6: return 10  // Wind slab (alternate ID) → AvalancheProblemDriftingSnow
        case 7: return 7   // Favourable situation → AvalancheProblemNewSnow
        default: return 0
        }
    }

    private func mapProblemTypeName(_ problemId: Int) -> String {
        switch problemId {
        case 1: return "New snow"
        case 2: return "Wind slab"
        case 3: return "Persistent slab"
        case 4: return "Wet snow"
        case 5: return "Glide snow"
        case 6: return "Wind slab"
        case 7: return "Favourable situation"
        default: return "Unknown"
        }
    }

    /// Convert 8 direction panels to ValidExpositions string "10101010" format
    /// Order: N, NE, E, SE, S, SW, W, NW
    private func mapExpositions(_ direction: LavinDirection) -> String {
        let panels = [
            direction.northPanel.state,
            direction.northEastPanel.state,
            direction.eastPanel.state,
            direction.southEastPanel.state,
            direction.southPanel.state,
            direction.southWestPanel.state,
            direction.westPanel.state,
            direction.northWestPanel.state
        ]
        return panels.map { $0 ? "1" : "0" }.joined()
    }

    /// Map treeline booleans to ExposedHeightFill
    /// 1 = above only (top), 2 = below only (bottom), 4 = middle band
    private func mapAltitude(_ altitude: LavinAltitude) -> (fill: Int, height1: Int, height2: Int) {
        let above = altitude.altitudeMeterAboveTreeline.state
        let treeline = altitude.altitudeMeterTreeline.state
        let below = altitude.altitudeMeterBelowTreeline.state

        if above && !below {
            return (1, 0, 0) // Top section
        } else if below && !above {
            return (2, 0, 0) // Bottom section
        } else if treeline && !above && !below {
            return (4, 0, 0) // Middle band
        } else {
            // All active or mixed - show full mountain
            return (1, 0, 0)
        }
    }

    /// Parse Swedish date format "Saturday 21/02-2026 18:00"
    private func parseSwedishDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")

        // Try English format: "Saturday 21/02-2026 18:00"
        formatter.dateFormat = "EEEE dd/MM-yyyy HH:mm"
        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try Swedish format: "lördag 21/02-2026 18:00"
        formatter.locale = Locale(identifier: "sv_SE")
        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try Norwegian format: same pattern but different locale
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.date(from: dateString)
    }

    /// Parse "2026-02-20" publishedDate format
    private func parsePublishedDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.date(from: dateString)
    }

    /// Strip HTML tags, Word metadata, and inline styles/scripts from assessment content.
    /// Swedish forecasters sometimes paste from MS Word, embedding conditional comments
    /// like `<!--[if gte mso 9]><xml>...<w:View>Normal</w:View>...</xml><![endif]-->`
    /// that leave junk text when only tags are stripped.
    private func stripHtml(_ html: String) -> String {
        var result = html
        // Remove MS Word conditional comments: <!--[if ...]>...<![endif]-->
        result = result.replacingOccurrences(
            of: "(?s)<!--\\[if[^\\]]*\\]>.*?<!\\[endif\\]-->",
            with: "",
            options: .regularExpression)
        // Remove remaining HTML comments: <!--...-->
        result = result.replacingOccurrences(
            of: "(?s)<!--.*?-->",
            with: "",
            options: .regularExpression)
        // Remove <style>...</style> and <script>...</script> blocks entirely
        for tag in ["style", "script"] {
            result = result.replacingOccurrences(
                of: "(?s)<\(tag)[^>]*>.*?</\(tag)>",
                with: "",
                options: [.regularExpression, .caseInsensitive])
        }
        // Remove remaining HTML tags
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return result
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#45;", with: "-")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
