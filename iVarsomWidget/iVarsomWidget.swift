import WidgetKit
import SwiftUI
import Intents
import CoreLocation

struct WarningEntry: TimelineEntry {
    let date: Date
    let currentWarning: AvalancheWarningSimple
    let warnings: [AvalancheWarningSimple]
    let configuration: SelectRegion
    var relevance: TimelineEntryRelevance?
    let hasError: Bool
    let errorMessage: String?
}

func getWidgetURL(entry: Provider.Entry) -> URL? {
#if os(watchOS)
    return URL(string: "no.follesoe.iVarsom.watchkitapp://region?id=\(entry.currentWarning.RegionId)")
#else
    return URL(string: "no.follesoe.iVarsom://region?id=\(entry.currentWarning.RegionId)")
#endif
}

struct LocationIconText: View {
    var text: String
    var config: SelectRegion
    var body: some View {
        Text(config.region?.regionId == 1 ?
            "\(Image(systemName: "location.fill")) \(text)" :
            "\(text)")
    }
}

struct SmallWarningWidgetView: View {
    var entry: Provider.Entry
    
    var textColor: Color {
        return entry.currentWarning.DangerLevel == .level2 ? .black : .white;
    }

    var body: some View {
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
            LocationIconText(text: entry.date.getDayName(), config: entry.configuration)
                .textCase(.uppercase)
                .font(.caption2)
                .foregroundColor(textColor)
            Text(entry.currentWarning.RegionName)
                .font(.system(size: 18))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

        }
        .padding()
        .containerBackground(for: .widget) {
            DangerGradient(dangerLevel: entry.currentWarning.DangerLevel)
        }
        .widgetURL(getWidgetURL(entry: entry))
    }
}

struct MediumWarningWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        WarningSummary(
            warning: entry.currentWarning,
            mainTextFont: .system(size: 13),
            mainTextLineLimit: 4,
            includeLocationIcon: entry.configuration.region?.regionId == 1)
        .containerBackground(for: .widget) {
            DangerGradient(dangerLevel: entry.currentWarning.DangerLevel)
        }
        .widgetURL(getWidgetURL(entry: entry))
    }
}

struct LargeWarningWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            WarningSummary(
                warning: entry.currentWarning,
                mainTextFont: .system(size: 15),
                includeLocationIcon: entry.configuration.region?.regionId == 1)
                .frame(height: 274)
            Spacer()
            HStack {
                ForEach(entry.warnings) { warning in
                    let isToday = Calendar.current.isDate(warning.ValidFrom, equalTo: Date.current, toGranularity: .day)
                    DayCell(
                        dangerLevel: warning.DangerLevel,
                        date: warning.ValidFrom,
                        isSelected: isToday)
                }
            }
            Spacer()
        }
        .containerBackground(for: .widget) {
            DangerGradient(dangerLevel: entry.currentWarning.DangerLevel)
        }
        .widgetURL(getWidgetURL(entry: entry))
    }
}

struct InlineWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        ViewThatFits {
            Text("\(entry.currentWarning.RegionName): \(entry.currentWarning.DangerLevelName)")
            Text("\(entry.currentWarning.RegionName): \(entry.currentWarning.DangerLevel.description)")
        }
        .widgetURL(getWidgetURL(entry: entry))
    }
}

struct CircleWidgetView: View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    var entry: Provider.Entry
    
    var body: some View {
        Gauge(value: entry.currentWarning.DangerLevelNumeric, in: 1...5) {
        } currentValueLabel: {
            DangerIcon(dangerLevel: entry.currentWarning.DangerLevel,
                       useTintable: widgetRenderingMode != .fullColor)
            .padding(2)
        } minimumValueLabel: {
            Text("1").foregroundColor(DangerLevel.level1.color)
        } maximumValueLabel: {
            Text("5").foregroundColor(DangerLevel.level4.color)
        }
        #if os(watchOS)
        .widgetLabel {
            Text(entry.currentWarning.RegionName)
        }
        .gaugeStyle(CircularGaugeStyle(tint: Gradient(colors: [
            DangerLevel.level1.color,
            DangerLevel.level2.color,
            DangerLevel.level3.color,
            DangerLevel.level4.color,
            DangerLevel.level4.color])))
        #else
        .gaugeStyle(.accessoryCircular)
        #endif
        .widgetURL(getWidgetURL(entry: entry))
        .containerBackground(for: .widget) {}
    }
}

struct RectangleWidgetView: View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    @Environment(\.widgetContentMargins) var widgetContentMargins
    
    var entry: Provider.Entry
    var body: some View {
        let filteredWarnings = entry.warnings.filter {
            let daysBetween = Calendar.current.numberOfDaysBetween(Date.current, and: $0.ValidFrom)
            return daysBetween >= -1 && daysBetween <= 2;
        }
        
        let todayWarning = filteredWarnings.first(where: {
            Calendar.current.isDate($0.ValidFrom, equalTo: Date.current, toGranularity: .day)
        })

        VStack(alignment: .leading, spacing: 0) {
            if (entry.hasError){
                Text("Error")
                    .font(.caption2)
                Text(entry.errorMessage ?? entry.currentWarning.MainText)
                    .font(.system(size: 14))
            } else {
                LocationIconText(text: entry.currentWarning.RegionName, config: entry.configuration)
                    .font(.system(size: 11))
                    .fontWeight(.bold)
                    .widgetAccentable()
                HStack(spacing: 0) {
                    ForEach(filteredWarnings) { warning in
                        let isToday = Calendar.current.isDate(warning.ValidFrom, equalTo: Date.current, toGranularity: .day)
                        VStack(spacing: 0) {
                            Text(warning.ValidFrom.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                .font(.system(size: 9))
                                .fontWeight(isToday ? .heavy : .regular)
                            DangerIcon(dangerLevel: warning.DangerLevel, useTintable: widgetRenderingMode != .fullColor)
                                .padding(2)
                            Text(warning.DangerLevel.description)
                                .font(.system(size: 11))
                                .fontWeight(isToday ? .heavy : .regular)
                        }
                        .frame(maxWidth: .infinity)
                        if (warning.RegId != filteredWarnings.last?.RegId) {
                            Divider()
                        }
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            if let level = todayWarning?.DangerLevel {
                DangerGradient(dangerLevel: level)
            } else {
                DangerGradient(dangerLevel: DangerLevel.unknown)
            }
        }
        .padding(widgetContentMargins)
        .widgetURL(getWidgetURL(entry: entry))
    }
}

struct CornerWidgetView: View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            DangerIcon(dangerLevel: entry.currentWarning.DangerLevel,
                       useTintable: widgetRenderingMode != .fullColor)
        }.widgetLabel {
            Text(entry.currentWarning.RegionName)
                .widgetAccentable()
        }
        .containerBackground(for: .widget) {}
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
            CircleWidgetView(entry: entry)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangleWidgetView(entry: entry)
#if os(watchOS)
        case .accessoryCorner:
            CornerWidgetView(entry: entry)
#endif
        default:
            SmallWarningWidgetView(entry: entry)
        }
    }
}

@main
struct iVarsomWidget: Widget {
    let kind: String = "iVarsomWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectRegion.self,
            provider: Provider()) { entry in
                WarningWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Avalanche Danger Level")
        .description("Display today's avalanche danger level for selected regions in Norway.")
        .contentMarginsDisabled()
        #if os(watchOS)
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryCorner, .accessoryRectangular])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        #endif
    }
}
