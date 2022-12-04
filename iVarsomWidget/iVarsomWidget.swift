import WidgetKit
import SwiftUI
import Intents
import CoreLocation
import DynamicColor

struct Provider: IntentTimelineProvider {
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
    
    func getTimeline(for configuration: SelectRegionIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
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

class WidgetLocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    private var handler: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.locationManager.delegate = self
    }
    
    func fetchLocation(handler: @escaping (CLLocation) -> Void) {
        self.handler = handler
        if let loc = self.locationManager.location {
            self.handler!(loc)
        } else {
            self.locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("\(locations)")
        self.handler!(locations.last!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

struct WarningEntry: TimelineEntry {
    let date: Date
    let currentWarning: AvalancheWarningSimple
    let warnings: [AvalancheWarningSimple]
    let configuration: SelectRegionIntent
    var relevance: TimelineEntryRelevance?
}

struct SmallWarningWidgetView: View {
    var entry: Provider.Entry
    
    var textColor: Color {
        return entry.currentWarning.DangerLevel == .level2 ? .black : .white;
    }

    var body: some View {
        ZStack {
            DangerGradient(dangerLevel: entry.currentWarning.DangerLevel)
            VStack(alignment: .leading) {
                HStack {
                    DangerIcon(dangerLevel: entry.currentWarning.DangerLevel)
                        .frame(width: 54, height: 54)
                    Spacer()
                    Text("\(entry.currentWarning.DangerLevel.description)")
                        .font(.system(size: 54))
                        .fontWeight(.heavy)
                        .foregroundColor(textColor)

                }
                Spacer()
                Text(entry.date.getDayName())
                    .textCase(.uppercase)
                    .font(.caption2)
                    .foregroundColor(textColor)
                Text(entry.currentWarning.RegionName)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

            }.padding()
        }.widgetURL(URL(string: "no.follesoe.iVarsom://region?id=\(entry.currentWarning.RegionId)"))
    }
}

struct MediumWarningWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        WarningSummary(
            warning: entry.currentWarning,
            mainTextFont: .system(size: 13),
            mainTextLineLimit: 4)
            .widgetURL(URL(string: "no.follesoe.iVarsom://region?id=\(entry.currentWarning.RegionId)"))
    }
}

struct LargeWarningWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            WarningSummary(
                warning: entry.currentWarning,
                mainTextFont: .system(size: 15))
                .frame(height: 274)
            Spacer()
            HStack {
                ForEach(entry.warnings) { warning in
                    let isToday = Calendar.current.isDate(warning.ValidFrom, equalTo: Date(), toGranularity: .day)
                    DayCell(
                        dangerLevel: warning.DangerLevel,
                        date: warning.ValidFrom,
                        isSelected: isToday)
                }
            }
            Spacer()
        }
        .widgetURL(URL(string: "no.follesoe.iVarsom://region?id=\(entry.currentWarning.RegionId)"))
    }
}

struct WarningWidgetView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: Provider.Entry
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWarningWidgetView(entry: entry)
        case .systemMedium:            
            MediumWarningWidgetView(entry: entry)
        case .systemLarge:
            LargeWarningWidgetView(entry: entry)
        default:
            SmallWarningWidgetView(entry: entry)
        }
    }
}

@main
struct iVarsomWidget: Widget {
    let kind: String = "iVarsomWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: SelectRegionIntent.self,
            provider: Provider()) { entry in
                WarningWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Avalanche Danger Level")
        .description("Display today's avalanche danger level for selected regions in Norway.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct iVarsomWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SmallWarningWidgetView(entry: Provider().errorEntry())
                .previewDisplayName("Error State Small")
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            SmallWarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel2,
                    warnings: [testWarningLevel2],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Level 2 Small")
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            SmallWarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel3,
                    warnings: [testWarningLevel3],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Level 3 Small")
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            MediumWarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel4,
                    warnings: [testWarningLevel4],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Level 4 Medium")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            MediumWarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel0,
                    warnings: [testWarningLevel0],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Level 0 Medium")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            LargeWarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel2,
                    warnings: [
                        testWarningLevel0,
                        testWarningLevel1,
                        testWarningLevel2,
                        testWarningLevel3,
                        testWarningLevel4],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Large")
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
