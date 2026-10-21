#if os(iOS)
    import SwiftUI
    import WidgetKit

    /// The tall extra-large widget (iOS 27): today's forecast followed by the coming
    /// days' forecast text, which other sizes have no room for.
    struct ExtraLargePortraitWarningWidgetView: View {
        var entry: Provider.Entry

        private var textColor: Color {
            entry.currentWarning.DangerLevel == .level5 ? .white : .black
        }

        var body: some View {
            VStack(spacing: 0) {
                WarningSummary(
                    warning: entry.currentWarning,
                    mainTextFont: .system(size: 17),
                    mainTextLineLimit: 8,
                    includeLocationIcon: entry.configuration.region?.regionId == 1)
                    .fixedSize(horizontal: false, vertical: true)
                ForecastDownloadLabel(entry: entry)
                if entry.currentWarning.hasActiveEmergencyWarning,
                    let emergencyWarning = entry.currentWarning.EmergencyWarning
                {
                    EmergencyWarningBanner(
                        message: emergencyWarning,
                        textLanguageCode: entry.currentWarning.textLanguageCode,
                        font: .caption,
                        verticalPadding: 6)
                }
                VStack(spacing: 4) {
                    ForEach(entry.upcomingWarnings) { warning in
                        UpcomingForecastRow(warning: warning, now: entry.date, textColor: textColor)
                    }
                }
                .padding(.vertical, 8)
                Spacer(minLength: 0)
                WidgetDayStrip(entry: entry)
                    .padding(.bottom, 16)
            }
            .containerBackground(for: .widget) {
                DangerGradient(dangerLevel: entry.currentWarning.DangerLevel)
            }
            .widgetURL(getWidgetURL(entry: entry))
        }
    }

    private struct UpcomingForecastRow: View {
        let warning: AvalancheWarningSimple
        let now: Date
        let textColor: Color

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                WarningLevelCell(dangerLevel: warning.DangerLevel)
                    .frame(width: 36, height: 36)
                    .clipShape(.rect(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(ForecastSelection.dayLabel(warning.ValidFrom, regionID: warning.RegionId, now: now))
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                    Text(warning.MainText)
                        .font(.system(size: 14))
                        .lineLimit(3)
                }
                .foregroundStyle(textColor)
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    extension WarningEntry {
        /// The next two published forecasts after the current one.
        var upcomingWarnings: [AvalancheWarningSimple] {
            Array(warnings.filter { $0.ValidFrom > currentWarning.ValidFrom }.prefix(2))
        }

        /// The summary plus the coming days, matching the tall widget's content.
        var extendedAccessibilitySummary: String {
            guard !hasError else { return accessibilitySummary }
            let upcoming = upcomingWarnings.map { warning in
                let day = ForecastSelection.dayLabel(warning.ValidFrom, regionID: warning.RegionId, now: date)
                let level = String(
                    localized: "Danger level \(warning.DangerLevel.description), \(warning.DangerLevel.localizedName)")
                return "\(day): \(level). \(warning.MainText)"
            }
            return ([accessibilitySummary] + upcoming).joined(separator: " ")
        }
    }
#endif
