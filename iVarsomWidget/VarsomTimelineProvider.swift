import WidgetKit
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
        return WarningEntry(
            date: Date.now(),
            currentWarning: testWarningLevel0,
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
            ValidFrom: Date.now(),
            ValidTo: Date.now(),
            NextWarningTime: Date.now(),
            PublishTime: Date.now(),
            DangerLevel: .unknown,
            MainText: "There was an error updating the widget",
            LangKey: 2)
        
        return WarningEntry(
            date: Date.now(),
            currentWarning: errorWarning,
            warnings: [AvalancheWarningSimple](),
            configuration: SelectRegion(),
            relevance: TimelineEntryRelevance(score: 0.0),
            hasError: true,
            errorMessage: errorMessage)
    }
    
    func snapshot(for configuration: SelectRegion, in context: Context) async -> WarningEntry {
        let regionId = configuration.region?.regionId ?? RegionOption.defaultOption.id
        
        let from = Date.now()
        let to = Calendar.current.date(byAdding: .day, value: 2, to: from)!
        
        do {
            let warnings = try await getWarnings(regionId: regionId, from: from, to: to)
            if (warnings.count > 0) {
                let entry = WarningEntry(
                    date: Date.now(),
                    currentWarning: warnings[0],
                    warnings: warnings,
                    configuration: configuration,
                    relevance: TimelineEntryRelevance(score: warnings[0].DangerLevelNumeric),
                    hasError: false,
                    errorMessage: nil)
                return entry
            } else {
                return errorEntry(errorMessage: "No warnings available")
            }
        } catch {
            print("Unexpected error: \(error).")
            return errorEntry(errorMessage: "\(error)")
        }
    }
    
    func timeline(for configuration: SelectRegion, in context: Context) async -> Timeline<WarningEntry> {
        let regionId = configuration.region?.regionId ?? RegionOption.defaultOption.id
        do {
            let from = Calendar.current.date(byAdding: .day, value: -3, to: Date.now())!
            let to = Calendar.current.date(byAdding: .day, value: 2, to: Date.now())!
            let warnings = try await getWarnings(regionId: regionId, from: from, to: to)
            let timeline = createTimeline(warnings: warnings, configuration: configuration)
            return timeline
        } catch {
            print("Unexpected error: \(error).")
            let afterDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date.now())!
            let errorTimeline = Timeline(entries: [errorEntry(errorMessage: "\(error)")], policy: .after(afterDate))
            return errorTimeline
        }
    }
    
    func recommendations() -> [AppIntentRecommendation<SelectRegion>] {
        RegionOption.allOptions.map { region in
            let regionOption = RegionConfigOptionAppEntity(
                id: "\(region.id)",
                displayString: region.name)
            regionOption.regionId = region.id
            let intent = SelectRegion()
            intent.region = regionOption
            return AppIntentRecommendation(intent: intent, description: region.name)
        }
    }
    
    func getWarnings(regionId: Int, from: Date, to: Date) async throws -> [AvalancheWarningSimple] {
        let locationManager = LocationManager()
        let apiClient = VarsomApiClient()
        var warnings:[AvalancheWarningSimple]
        let isAuthorized = locationManager.isAuthorizedForWidgetUpdates
        
        if (regionId == 1) {
            if (isAuthorized) {
                let location = try await locationManager.updateLocation()
                warnings = try await apiClient.loadWarnings(
                    lang: VarsomApiClient.currentLang(),
                    coordinate: location,
                    from: from,
                    to: to)
            } else {
                throw MissingLocationAuthorizationError();
            }
        } else {
            warnings = try await apiClient.loadWarnings(
                lang: VarsomApiClient.currentLang(),
                regionId: regionId,
                from: from,
                to: to)
        }
        
        return warnings
    }
    
    func createTimeline(warnings: [AvalancheWarningSimple], configuration: SelectRegion) -> Timeline<Entry> {
        var entries: [WarningEntry] = []
    
        let currentIndex = warnings.firstIndex { Calendar.current.isDate($0.ValidFrom, equalTo: Date.now(), toGranularity: .day) }!
        
        let currentWarning = warnings[currentIndex]
        let prevWarning = currentIndex > 0 ? warnings[currentIndex - 1] : currentWarning
        
        let entry = WarningEntry(
            date: currentWarning.ValidFrom,
            currentWarning: currentWarning,
            warnings: warnings,
            configuration: configuration,
            relevance: TimelineEntryRelevance(score: currentWarning.DangerLevelNumeric),
            hasError: false,
            errorMessage: nil)
        entries.append(entry)
        
        let afterDate = getNextUpdateTime(prevWarning: prevWarning, currentWarning: currentWarning)
        print("Update policy after \(afterDate)")
        return Timeline(entries: entries, policy: .after(afterDate))
    }
}
