import WidgetKit
import SwiftUI
import Intents
import CoreLocation

struct MissingLocationAuthorizationError: Error, LocalizedError {
    public var errorDescription: String? {
        return "Missing location authorization"
    }
}

struct Provider: IntentTimelineProvider {
    func recommendations() -> [IntentRecommendation<SelectRegionIntent>] {
        RegionOption.allOptions.map { region in
            let regionOption = RegionConfigOption(
                identifier: "\(region.id)",
                display: region.name)
            regionOption.regionId = NSNumber(value: region.id)
            let intent = SelectRegionIntent()
            intent.region = regionOption
            return IntentRecommendation(intent: intent, description: region.name)
        }
    }
    
    func placeholder(in context: Context) -> WarningEntry {
        return WarningEntry(
            date: Date.now(),
            currentWarning: testWarningLevel0,
            warnings: [AvalancheWarningSimple](),
            configuration: SelectRegionIntent(),
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
            configuration: SelectRegionIntent(),
            relevance: TimelineEntryRelevance(score: 0.0),
            hasError: true,
            errorMessage: errorMessage)
    }
    
    func getSnapshot(for configuration: SelectRegionIntent, in context: Context, completion: @escaping (WarningEntry) -> ()) {
        
        let regionId = Int(truncating: configuration.region?.regionId ??
                        NSNumber(value: RegionOption.defaultOption.id))
        
        let from = Date.now()
        let to = Calendar.current.date(byAdding: .day, value: 2, to: from)!
        
        Task {
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
                    completion(entry)
                } else {
                    completion(errorEntry(errorMessage: "No warnings available"))
                }
            } catch {
                print("Unexpected error: \(error).")
                completion(errorEntry(errorMessage: "\(error)"))
            }
        }
    }
    
    func getTimeline(for configuration: SelectRegionIntent, in context: Context, completion: @escaping (Timeline<WarningEntry>) -> ()) {
        
        let regionId = Int(truncating: configuration.region?.regionId ??
                           NSNumber(value: RegionOption.defaultOption.id))
                
        Task {
            do {
                let from = Calendar.current.date(byAdding: .day, value: -3, to: Date.now())!
                let to = Calendar.current.date(byAdding: .day, value: 2, to: Date.now())!
                let warnings = try await getWarnings(regionId: regionId, from: from, to: to)
                let timeline = createTimeline(warnings: warnings, configuration: configuration)
                completion(timeline)
            } catch {
                print("Unexpected error: \(error).")
                let afterDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date.now())!
                let errorTimeline = Timeline(entries: [errorEntry(errorMessage: "\(error)")], policy: .after(afterDate))
                completion(errorTimeline)
            }
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
    
    func createTimeline(warnings: [AvalancheWarningSimple], configuration: SelectRegionIntent) -> Timeline<Entry> {
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
