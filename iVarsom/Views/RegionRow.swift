import SwiftUI

struct RegionRow: View {
    var region: RegionSummary

    private var dangerLevelsSummary: String {
        region.AvalancheWarningList.map { warning in
            let day = warning.ValidFrom.formatted(.dateTime.weekday(.wide))
            return "\(day) \(warning.DangerLevel.localizedName)"
        }.joined(separator: ", ")
    }

    private var accessibilityDescription: String {
        if let trend = region.dangerTrend {
            return "\(trend.localizedDescription), \(region.Name), \(dangerLevelsSummary)"
        }
        return "\(region.Name), \(dangerLevelsSummary)"
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(region.Name)
                .font(.body)
            Spacer()
            if let trend = region.dangerTrend {
                DangerTrendIndicator(trend: trend)
            }
            ForEach(region.AvalancheWarningList) { warning in
                WarningLevelCell(dangerLevel: warning.DangerLevel)
                    .frame(width: 32, height: 32)
                    .cornerRadius(8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
}

#Preview("Region Row") {
    RegionRow(region: testARegions[0])
}
