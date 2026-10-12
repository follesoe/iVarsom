import SwiftUI

struct RegionRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var badgeSize = 32.0
    var region: RegionSummary

    private var dangerLevelsSummary: String {
        region.AvalancheWarningList.map { warning in
            let day = warning.formattedForecastDate(.dateTime.weekday(.wide))
            return "\(day) \(warning.DangerLevel.localizedName)"
        }.joined(separator: ", ")
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Text(region.Name)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    ForEach(region.AvalancheWarningList) { warning in
                        VStack(spacing: 4) {
                            dayLabel(for: warning)
                            dangerBadge(for: warning)
                        }
                    }
                }
                .fixedSize()

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(region.AvalancheWarningList) { warning in
                        HStack(spacing: 8) {
                            dangerBadge(for: warning)
                            dayLabel(for: warning)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(region.Name), \(dangerLevelsSummary)")
    }

    private func dayLabel(for warning: AvalancheWarningSimple) -> some View {
        Text(warning.formattedForecastDate(.dateTime.weekday(.abbreviated)))
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func dangerBadge(for warning: AvalancheWarningSimple) -> some View {
        WarningLevelCell(dangerLevel: warning.DangerLevel)
            .frame(width: badgeSize, height: badgeSize)
            .clipShape(.rect(cornerRadius: 8))
    }
}

#Preview("Region Row") {
    RegionRow(region: testARegions[0])
}

#Preview("Narrow Row — Largest Text") {
    RegionRow(region: testARegions[0])
        .frame(width: 220)
        .environment(\.dynamicTypeSize, .accessibility5)
        .padding()
}
