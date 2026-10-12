import AppIntents
import Foundation
import WidgetKit

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

    func errorEntry(errorMessage: String, configuration: SelectRegion = SelectRegion(), date: Date = Date.current) -> WarningEntry {
        let regionID = regionId(for: configuration)
        let errorWarning = AvalancheWarningSimple(
            RegId: 1,
            RegionId: regionID,
            RegionName: configuration.region?.displayString ?? RegionOption.defaultOption.name,
            RegionTypeName: "A",
            ValidFrom: date,
            ValidTo: date,
            NextWarningTime: date,
            PublishTime: date,
            DangerLevel: .unknown,
            MainText: errorMessage,
            LangKey: 2)

        return WarningEntry(
            date: date,
            currentWarning: errorWarning,
            warnings: [AvalancheWarningSimple](),
            configuration: configuration,
            relevance: TimelineEntryRelevance(score: 0.0),
            hasError: true,
            errorMessage: errorMessage)
    }

    private func regionId(for configuration: SelectRegion) -> Int {
        Int(configuration.region?.id ?? "") ?? configuration.region?.regionId ?? RegionOption.defaultOption.id
    }

    func snapshot(for configuration: SelectRegion, in context: Context) async -> WarningEntry {
        if context.isPreview { return placeholder(in: context) }
        return await loadTimeline(for: configuration).entries[0]
    }

    func timeline(for configuration: SelectRegion, in context: Context) async -> Timeline<WarningEntry> {
        await loadTimeline(for: configuration)
    }

    private func loadTimeline(for configuration: SelectRegion) async -> Timeline<WarningEntry> {
        let now = Date.current
        do {
            let resolvedID = try await ForecastRegionResolver.resolve(regionId(for: configuration))
            let loaded = try await ForecastService().load(regionID: resolvedID)
            return createTimeline(loaded: loaded, configuration: configuration, now: now)
        } catch {
            let entry = errorEntry(errorMessage: error.localizedDescription, configuration: configuration, date: now)
            return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(15 * 60)))
        }
    }

    func recommendations() -> [AppIntentRecommendation<SelectRegion>] {
        #if os(watchOS)
        // watchOS 26 presents region/day configuration when no fixed presets
        // are supplied. Smart Stack suggestions still come from relevance().
        return []
        #else
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
        #endif
    }

    func createTimeline(loaded: LoadedForecast, configuration: SelectRegion, now: Date) -> Timeline<Entry> {
        let snapshot = loaded.snapshot
        let plan = ForecastTimeline(loaded: loaded, day: configuration.day, now: now)
        let entries = plan.entries.map { moment in
            let date = moment.date
            let warning = moment.warning
            let unavailable = AvalancheWarningSimple(
                RegId: 0, RegionId: snapshot.regionID,
                RegionName: RegionOption.getName(id: snapshot.regionID, def: ""), RegionTypeName: "A",
                ValidFrom: date, ValidTo: date, NextWarningTime: date, PublishTime: date,
                DangerLevel: .unknown, MainText: String(localized: "No forecast available for this day"), LangKey: 2)
            return WarningEntry(date: date, currentWarning: warning ?? unavailable,
                warnings: moment.warnings, configuration: configuration,
                relevance: warning.map { TimelineEntryRelevance(score: $0.DangerLevelNumeric,
                    duration: max(0, $0.validityEnd.timeIntervalSince(date))) },
                hasError: warning == nil,
                errorMessage: warning == nil ? String(localized: "No forecast available for this day") : nil,
                downloadedAt: snapshot.downloadedAt, isCached: moment.isCached)
        }
        return Timeline(entries: entries, policy: .after(plan.refreshAfter))
    }
}
