import WidgetKit
import SwiftUI
import Intents
import CoreLocation
import DynamicColor

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
        case .accessoryCircular:
            Gauge(value: entry.currentWarning.DangerLevelNumeric, in: 1...5) {
            } currentValueLabel: {
                Text(entry.currentWarning.DangerLevel.description)
            } minimumValueLabel: {
                Text("1")
            } maximumValueLabel: {
                Text("5")
            }
            .gaugeStyle(.accessoryCircular)
        case .accessoryInline:
            ViewThatFits {
                Text("\(Image(systemName: "mountain.2")) \(entry.currentWarning.RegionName): \(entry.currentWarning.DangerLevelName)")
                Text("\(Image(systemName: "mountain.2")) \(entry.currentWarning.RegionName): \(entry.currentWarning.DangerLevel.description)")
                    .truncationMode(.middle)
                Text("\(Image(systemName: "mountain.2")) \(entry.currentWarning.RegionName): \(entry.currentWarning.DangerLevel.description)")
                    .truncationMode(.middle)
            }
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
        #if os(watchOS)
        .supportedFamilies([.accessoryInline, .accessoryCircular])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular])
        #endif
    }
}
