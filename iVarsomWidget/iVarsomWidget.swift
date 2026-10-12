import WidgetKit
import SwiftUI

struct WarningEntry: TimelineEntry {
    let date: Date
    let currentWarning: AvalancheWarningSimple
    let warnings: [AvalancheWarningSimple]
    let configuration: SelectRegion
    var relevance: TimelineEntryRelevance?
    let hasError: Bool
    let errorMessage: String?
    var downloadedAt: Date? = nil
    var isCached = false

    var accessibilitySummary: String {
        if hasError { return "\(currentWarning.RegionName). \(errorMessage ?? String(localized: "No warning available"))" }
        return currentWarning.accessibilitySummary(downloadedAt: downloadedAt, isCached: isCached)
    }
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
        Text(config.region?.id == "1" ?
            "\(Image(systemName: "location.fill")) \(text)" :
            "\(text)")
    }
}

struct SmallWarningWidgetView: View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    @Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground
    @Environment(\.colorScheme) private var colorScheme
    var entry: Provider.Entry

    var textColor: Color {
        // In vibrant mode (Lock Screen, StandBy night), use primary color
        if widgetRenderingMode == .vibrant {
            return .primary
        }
        // In StandBy day mode or CarPlay (no background), use primary for visibility
        if !showsWidgetContainerBackground {
            return .primary
        }
        // Normal mode with background - use contrast colors
        return entry.currentWarning.DangerLevel == .level5 ? .white : .black
    }

    var useTintableIcon: Bool {
        widgetRenderingMode != .fullColor || !showsWidgetContainerBackground
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                DangerIcon(dangerLevel: entry.currentWarning.DangerLevel,
                           useTintable: useTintableIcon)
                    .frame(width: 54, height: 54)
                Spacer()
                Text("\(entry.currentWarning.DangerLevel.description)")
                    .font(.system(size: 54))
                    .fontWeight(.heavy)
                    .foregroundColor(textColor)

            }
            Spacer()
            LocationIconText(text: entry.currentWarning.formattedForecastDate(.dateTime.weekday(.abbreviated).day().month(.abbreviated)), config: entry.configuration)
                .textCase(.uppercase)
                .font(.caption2)
                .foregroundColor(textColor)
            if entry.isCached {
                Label("Saved forecast", systemImage: "clock.arrow.circlepath")
                    .font(.caption2)
                    .foregroundStyle(textColor)
            }
            Text(entry.currentWarning.RegionName)
                .font(.system(size: 18))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

        }
        .padding()
        .overlay(alignment: .bottomTrailing) {
            if entry.currentWarning.hasActiveEmergencyWarning {
                EmergencyWarningIcon(colorScheme: colorScheme, size: 22)
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }
        }
        .containerBackground(for: .widget) {
            DangerGradient(dangerLevel: entry.currentWarning.DangerLevel)
        }
        .widgetURL(getWidgetURL(entry: entry))
    }
}

struct MediumWarningWidgetView: View {
    var entry: Provider.Entry

    private var hasEmergency: Bool {
        entry.currentWarning.hasActiveEmergencyWarning
    }

    var body: some View {
        VStack(spacing: 0) {
            WarningSummary(
                warning: entry.currentWarning,
                mainTextFont: .system(size: 13),
                regionNameFont: .title3,
                mainTextLineLimit: hasEmergency ? 3 : 4,
                includeLocationIcon: entry.configuration.region?.regionId == 1,
                compact: hasEmergency)
            ForecastDownloadLabel(entry: entry)
            if entry.currentWarning.hasActiveEmergencyWarning,
               let emergencyWarning = entry.currentWarning.EmergencyWarning {
                EmergencyWarningBanner(message: emergencyWarning,
                                       textLanguageCode: entry.currentWarning.textLanguageCode,
                                       font: .system(size: 11),
                                       verticalPadding: 4)
                    .layoutPriority(1)
            }
        }
        .containerBackground(for: .widget) {
            DangerGradient(dangerLevel: entry.currentWarning.DangerLevel)
        }
        .widgetURL(getWidgetURL(entry: entry))
    }
}

struct StandardWarningWidgetView: View {
    var entry: Provider.Entry
    var mainTextFont: Font
    var summaryHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            WarningSummary(
                warning: entry.currentWarning,
                mainTextFont: mainTextFont,
                includeLocationIcon: entry.configuration.region?.regionId == 1)
                .frame(height: summaryHeight)
            ForecastDownloadLabel(entry: entry)
            if entry.currentWarning.hasActiveEmergencyWarning,
               let emergencyWarning = entry.currentWarning.EmergencyWarning {
                EmergencyWarningBanner(message: emergencyWarning,
                                       textLanguageCode: entry.currentWarning.textLanguageCode,
                                       font: .caption,
                                       verticalPadding: 6)
            }
            Spacer(minLength: 0)
            HStack {
                ForEach(entry.warnings) { warning in
                    let isToday = warning.RegId == entry.currentWarning.RegId
                    DayCell(
                        dangerLevel: warning.DangerLevel,
                        date: warning.ValidFrom,
                        isSelected: isToday,
                        regionID: warning.RegionId)
                }
            }
            .padding(.bottom, 16)
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            DangerGradient(dangerLevel: entry.currentWarning.DangerLevel)
        }
        .widgetURL(getWidgetURL(entry: entry))
    }
}

struct LargeWarningWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        StandardWarningWidgetView(
            entry: entry,
            mainTextFont: .system(size: 15),
            summaryHeight: 274)
    }
}

struct ExtraLargeWarningWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        StandardWarningWidgetView(
            entry: entry,
            mainTextFont: .system(size: 18),
            summaryHeight: 285)
    }
}

struct InlineWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        ViewThatFits {
            Text("\(entry.isCached ? "↻ " : "")\(entry.currentWarning.RegionName): \(entry.currentWarning.DangerLevelName)")
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
        // The timeline owns the date window; this compact view shows four days.
        let filteredWarnings = Array(entry.warnings.suffix(4))
        
        let todayWarning = filteredWarnings.first(where: {
            $0.RegId == entry.currentWarning.RegId
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
                if entry.isCached { Text("Saved forecast").font(.system(size: 9)) }
                HStack(spacing: 0) {
                    ForEach(filteredWarnings) { warning in
                        let isToday = warning.RegId == entry.currentWarning.RegId
                        VStack(spacing: 0) {
                            Text(warning.formattedForecastDate(.dateTime.weekday(.abbreviated)).uppercased())
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
    
    var body: some View {
        Group {
            if entry.hasError {
                UnavailableForecastWidgetView(entry: entry)
            } else {
                content
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.accessibilitySummary)
        .widgetURL(getWidgetURL(entry: entry))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            SmallWarningWidgetView(entry: entry)
        case .systemMedium:            
            MediumWarningWidgetView(entry: entry)
        case .systemLarge:
            LargeWarningWidgetView(entry: entry)
        #if os(iOS)
        case .systemExtraLarge:
            ExtraLargeWarningWidgetView(entry: entry)
        #endif
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

struct iVarsomWidget: Widget {
    let kind: String = "iVarsomWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectRegion.self,
            provider: Provider()) { entry in
                WarningWidgetView(entry: entry)
                    .environment(\.accessibilityBridgeDisabled, true)
        }
        .configurationDisplayName("Avalanche forecast")
        .description("Current or tomorrow's published forecast for Norway and Sweden.")
        .contentMarginsDisabled()
        #if os(watchOS)
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryCorner, .accessoryRectangular])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        #endif
    }
}

private struct ForecastDownloadLabel: View {
    let entry: WarningEntry

    var body: some View {
        if let downloadedAt = entry.downloadedAt {
            HStack(spacing: 4) {
                if entry.isCached { Image(systemName: "clock.arrow.circlepath") }
                Text(entry.isCached ? "Saved forecast" : "Downloaded")
                Text(downloadedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
            }
            .font(.caption2)
            .foregroundStyle(entry.currentWarning.DangerLevel == .level5 ? .white : .black)
            .padding(.bottom, 3)
        }
    }
}

private struct UnavailableForecastWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WarningEntry

    private var isCompact: Bool {
        #if os(watchOS)
        return family == .accessoryCircular || family == .accessoryCorner
        #else
        return family == .accessoryCircular
        #endif
    }

    var body: some View {
        Group {
            if family == .accessoryInline {
                Text("\(entry.currentWarning.RegionName): —")
            } else if isCompact {
                Image(systemName: "exclamationmark.triangle")
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.currentWarning.RegionName).font(.headline)
                    Text(entry.configuration.day == .tomorrow ? "Tomorrow" : "Current forecast")
                        .font(.caption)
                    Text(entry.errorMessage ?? String(localized: "No warning available"))
                        .font(.caption)
                        .minimumScaleFactor(0.8)
                }
                .padding()
            }
        }
        .containerBackground(for: .widget) { Color.gray.opacity(0.15) }
    }
}

@main
struct AvalancheWidgetBundle: WidgetBundle {
    var body: some Widget {
        iVarsomWidget()
        #if !targetEnvironment(macCatalyst)
        OpenForecastControl()
        #endif
    }
}
