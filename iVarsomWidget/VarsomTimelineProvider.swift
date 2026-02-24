import WidgetKit
import AppIntents
import SwiftUI
import Intents
import CoreLocation

struct MissingLocationAuthorizationError: Error, LocalizedError {
    public var errorDescription: String? {
        return "Missing location authorization"
    }
}

struct Provider: AppIntentTimelineProvider {
    typealias Entry = WarningEntry
    
    typealias Intent = SelectRegion
    
    func placeholder(in context: Context) -> WarningEntry {
        let notAssessedText = NSLocalizedString("Not assessed", comment: "B-region with no avalanche rating")
        return WarningEntry(
            date: Date.current,
            currentWarning: AvalancheWarningSimple(
                RegId: 1,
                RegionId: 3020,
                RegionName: "Sør Trøndelag",
                RegionTypeName: "B",
                ValidFrom: Date.current,
                ValidTo: Date.current,
                NextWarningTime: Date.current,
                PublishTime: Date.current,
                DangerLevel: .unknown,
                MainText: notAssessedText,
                LangKey: 2),
            warnings: [AvalancheWarningSimple](),
            configuration: SelectRegion(),
            relevance: TimelineEntryRelevance(score: 0.0),
            hasError: false,
            errorMessage: nil)
    }
    
    func errorEntry(errorMessage: String) -> WarningEntry {
        let errorWarning = AvalancheWarningSimple(
            RegId: 1,
            RegionId: 0,
            RegionName: "Error",
            RegionTypeName: "A",
            ValidFrom: Date.current,
            ValidTo: Date.current,
            NextWarningTime: Date.current,
            PublishTime: Date.current,
            DangerLevel: .unknown,
            MainText: "There was an error updating the widget",
            LangKey: 2)
        
        return WarningEntry(
            date: Date.current,
            currentWarning: errorWarning,
            warnings: [AvalancheWarningSimple](),
            configuration: SelectRegion(),
            relevance: TimelineEntryRelevance(score: 0.0),
            hasError: true,
            errorMessage: errorMessage)
    }
    
    private func regionId(for configuration: SelectRegion) -> Int {
        if let region = configuration.region {
            // Prefer the id (always set) over @Property regionId (may not be hydrated)
            return Int(region.id) ?? region.regionId ?? RegionOption.defaultOption.id
        }
        return RegionOption.defaultOption.id
    }

    func snapshot(for configuration: SelectRegion, in context: Context) async -> WarningEntry {
        let regionId = regionId(for: configuration)

        let from = Calendar.current.date(byAdding: .day, value: WarningDateRange.widgetDaysBefore, to: Date.current)!
        let to = Calendar.current.date(byAdding: .day, value: WarningDateRange.widgetDaysAfter, to: Date.current)!

        do {
            let warnings = try await getWarnings(regionId: regionId, from: from, to: to)
            guard let firstWarning = warnings.first else {
                return errorEntry(errorMessage: "No warnings available")
            }
            return WarningEntry(
                date: Date.current,
                currentWarning: firstWarning,
                warnings: warnings,
                configuration: configuration,
                relevance: TimelineEntryRelevance(score: firstWarning.DangerLevelNumeric),
                hasError: false,
                errorMessage: nil)
        } catch {
            print("Unexpected error: \(error).")
            return errorEntry(errorMessage: "\(error)")
        }
    }

    func timeline(for configuration: SelectRegion, in context: Context) async -> Timeline<WarningEntry> {
        let regionId = regionId(for: configuration)
        do {
            let from = Calendar.current.date(byAdding: .day, value: WarningDateRange.widgetDaysBefore, to: Date.current)!
            let to = Calendar.current.date(byAdding: .day, value: WarningDateRange.widgetDaysAfter, to: Date.current)!
            let warnings = try await getWarnings(regionId: regionId, from: from, to: to)
            return createTimeline(warnings: warnings, configuration: configuration)
        } catch {
            print("Unexpected error: \(error).")
            let afterDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date.current)!
            return Timeline(entries: [errorEntry(errorMessage: "\(error)")], policy: .after(afterDate))
        }
    }
    
    func recommendations() -> [AppIntentRecommendation<SelectRegion>] {
        let favorites = FavoritesService().loadFavorites()
        let regions: [RegionOption]
        if favorites.isEmpty {
            regions = [RegionOption.currentPositionOption]
        } else {
            let favoriteRegions: [RegionOption] = favorites.compactMap { id -> RegionOption? in
                if let region = RegionOption.aRegions.first(where: { $0.id == id }) {
                    return region
                }
                if let region = RegionOption.swedenRegions.first(where: { $0.id == id }) {
                    return region
                }
                if id == RegionOption.currentPositionOption.id {
                    return RegionOption.currentPositionOption
                }
                return nil
            }
            regions = favoriteRegions.isEmpty ? [RegionOption.currentPositionOption] : favoriteRegions
        }
        return regions.map { region in
            let regionOption = RegionConfigOptionAppEntity(
                id: "\(region.id)",
                displayString: region.name)
            regionOption.regionId = region.id
            let intent = SelectRegion()
            intent.region = regionOption
            return AppIntentRecommendation(intent: intent, description: region.name)
        }
    }
    
    @MainActor
    func getWarnings(regionId: Int, from: Date, to: Date) async throws -> [AvalancheWarningSimple] {
        let locationManager = LocationManager()
        let apiClient = VarsomApiClient()
        var warnings:[AvalancheWarningSimple]
        let isAuthorized = locationManager.isAuthorizedForWidgetUpdates

        if (regionId == 1) {
            guard isAuthorized else {
                throw MissingLocationAuthorizationError()
            }

            let location = try await locationManager.updateLocation()
            guard let location = location else {
                throw MissingLocationAuthorizationError()
            }

            if let geoData = RegionGeoData.load(),
               let feature = geoData.findNearestRegion(at: location) {
                if Country.from(regionId: feature.id) == .sweden {
                    let swedenClient = LavinprognoserApiClient()
                    let daysBefore = abs(Calendar.current.dateComponents([.day], from: from, to: Date.current).day ?? 1)
                    warnings = try await swedenClient.loadWarnings(regionId: feature.id, daysBefore: max(daysBefore, 1))
                } else {
                    warnings = try await Self.loadDetailedAsSimple(
                        apiClient: apiClient, regionId: feature.id, from: from, to: to)
                }
            } else {
                throw MissingLocationAuthorizationError()
            }
        } else if Country.from(regionId: regionId) == .sweden {
            let swedenClient = LavinprognoserApiClient()
            let daysBefore = abs(Calendar.current.dateComponents([.day], from: from, to: Date.current).day ?? 1)
            warnings = try await swedenClient.loadWarnings(regionId: regionId, daysBefore: max(daysBefore, 1))
        } else {
            warnings = try await Self.loadDetailedAsSimple(
                apiClient: apiClient, regionId: regionId, from: from, to: to)
        }

        return warnings
    }

    private static func loadDetailedAsSimple(
        apiClient: VarsomApiClient, regionId: Int, from: Date, to: Date
    ) async throws -> [AvalancheWarningSimple] {
        let detailed = try await apiClient.loadWarningsDetailed(
            lang: VarsomApiClient.currentLang(),
            regionId: regionId,
            from: from,
            to: to)
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
    
    func createTimeline(warnings: [AvalancheWarningSimple], configuration: SelectRegion) -> Timeline<Entry> {
        // Find warning for today, or fall back to first warning
        let todayIndex = warnings.firstIndex { Calendar.current.isDate($0.ValidFrom, equalTo: Date.current, toGranularity: .day) }
        let index = todayIndex ?? (warnings.count - 1)

        guard index < warnings.count else {
            // No warnings available - return error timeline
            let afterDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date.current)!
            return Timeline(entries: [errorEntry(errorMessage: "No warnings available")], policy: .after(afterDate))
        }

        let currentWarning = warnings[index]
        let prevWarning = index > 0 ? warnings[index - 1] : currentWarning

        let entry = WarningEntry(
            date: currentWarning.ValidFrom,
            currentWarning: currentWarning,
            warnings: warnings,
            configuration: configuration,
            relevance: TimelineEntryRelevance(score: currentWarning.DangerLevelNumeric),
            hasError: false,
            errorMessage: nil)

        let afterDate = getNextUpdateTime(prevWarning: prevWarning, currentWarning: currentWarning)
        return Timeline(entries: [entry], policy: .after(afterDate))
    }
}
