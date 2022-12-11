import WidgetKit
import SwiftUI
import Intents
import CoreLocation
import DynamicColor

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
            date: Date(),
            currentWarning: testWarningLevel0,
            warnings: [AvalancheWarningSimple](),
            configuration: SelectRegionIntent(),
            relevance: TimelineEntryRelevance(score: 0.0))
    }
    
    func errorEntry() -> WarningEntry {
        let errorWarning = AvalancheWarningSimple(
            RegId: 1,
            RegionId: 0,
            RegionName: "Error",
            RegionTypeName: "A",
            ValidFrom: Date(),
            ValidTo: Date(),
            NextWarningTime: Date(),
            PublishTime: Date(),
            DangerLevel: .unknown,
            MainText: "There was an error updating the widget",
            LangKey: 2)
        
        return WarningEntry(
            date: Date(),
            currentWarning: errorWarning,
            warnings: [AvalancheWarningSimple](),
            configuration: SelectRegionIntent(),
            relevance: TimelineEntryRelevance(score: 0.0))
    }
    
    func getSnapshot(for configuration: SelectRegionIntent, in context: Context, completion: @escaping (WarningEntry) -> ()) {
        
        let regId = Int(truncating: configuration.region?.regionId ??
                        NSNumber(value: RegionOption.defaultOption.id))
        
        let from = Date()
        let to = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        
        Task {
            do {
                let warnings = try await VarsomApiClient().loadWarnings(
                    lang: VarsomApiClient.currentLang(),
                    regionId: regId,
                    from: from,
                    to: to)
                if (warnings.count > 0) {
                    let entry = WarningEntry(
                        date: Date(),
                        currentWarning: warnings[0],
                        warnings: warnings,
                        configuration: configuration,
                        relevance: TimelineEntryRelevance(score: warnings[0].DangerLevelNumeric))
                    completion(entry)
                } else {
                    completion(errorEntry())
                }
            } catch {
                print("Unexpected error: \(error).")
                completion(errorEntry())
            }
        }
    }
    
    func getTimeline(for configuration: SelectRegionIntent, in context: Context, completion: @escaping (Timeline<WarningEntry>) -> ()) {
        
        let regionId = Int(truncating: configuration.region?.regionId ??
                        NSNumber(value: RegionOption.defaultOption.id))
        
        let locationManager = LocationManager()
        let apiClient = VarsomApiClient()
        
        Task {
            do {
                var warnings:[AvalancheWarningSimple]
                let from = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
                let to = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
                
                if (configuration.region?.regionId == 1 && locationManager.isAuthorizedForWidgetUpdates) {
                    let location = try await locationManager.updateLocation()
                    warnings = try await apiClient.loadWarnings(
                        lang: VarsomApiClient.currentLang(),
                        coordinate: location,
                        from: from,
                        to: to)
                } else {
                    warnings = try await apiClient.loadWarnings(
                        lang: VarsomApiClient.currentLang(),
                        regionId: regionId,
                        from: from,
                        to: to)
                }
                
                let timeline = createTimeline(warnings: warnings, configuration: configuration)
                completion(timeline)
            } catch {
                print("Unexpected error: \(error).")
                let afterDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
                let errorTimeline = Timeline(entries: [errorEntry()], policy: .after(afterDate))
                completion(errorTimeline)
            }
        }
    }
    
    func createTimeline(warnings: [AvalancheWarningSimple], configuration: SelectRegionIntent) -> Timeline<Entry> {
        var entries: [WarningEntry] = []
    
        let currentIndex = warnings.firstIndex { Calendar.current.isDate($0.ValidFrom, equalTo: Date(), toGranularity: .day) }!
        
        let currentWarning = warnings[currentIndex]
        let prevWarning = currentIndex > 0 ? warnings[currentIndex - 1] : currentWarning
        
        let entry = WarningEntry(
            date: currentWarning.ValidFrom,
            currentWarning: currentWarning,
            warnings: warnings,
            configuration: configuration,
            relevance: TimelineEntryRelevance(score: currentWarning.DangerLevelNumeric))
        entries.append(entry)
        
        let afterDate = getNextUpdateTime(prevWarning: prevWarning, currentWarning: currentWarning)
        print("Update policy after \(afterDate)")
        return Timeline(entries: entries, policy: .after(afterDate))
    }
}
