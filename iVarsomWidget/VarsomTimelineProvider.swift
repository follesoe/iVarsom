import AppIntents
import CoreLocation
import Intents
import SwiftUI
import WidgetKit

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
            guard let index = warnings.currentWarningIndex(on: Date.current) else {
                return errorEntry(errorMessage: "No warnings available")
            }
            let firstWarning = warnings[index]
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
            let from = Calendar.current.date(
                byAdding: .day, value: WarningDateRange.widgetDaysBefore, to: Date.current)!
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
        let favorites = FavoritesService.savedFavorites()
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
        var resolvedID = regionId
        if regionId == RegionOption.currentPositionOption.id {
            let locationManager = LocationManager()
            guard try await locationManager.checkWidgetAuthorization(),
                let location = try await locationManager.updateLocation(),
                let feature = RegionGeoData.load()?.findNearestRegion(at: location)
            else {
                throw MissingLocationAuthorizationError()
            }
            resolvedID = feature.id
        }
        let request = WarningRequest(regionID: resolvedID, from: from, to: to, relativeTo: Date.current)
        let loaded = try await WarningRepository(cache: nil).loadWarnings(request, cachePolicy: .networkOnly)
        return loaded.warnings.map(\.summary)
    }

    func createTimeline(warnings: [AvalancheWarningSimple], configuration: SelectRegion) -> Timeline<Entry> {
        guard let index = warnings.currentWarningIndex(on: Date.current) else {
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
