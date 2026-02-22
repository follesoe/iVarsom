import SwiftUI

struct RegionRow: View {
    var region: RegionSummary

    private var dangerLevelsSummary: String {
        region.AvalancheWarningList.map { warning in
            let day = warning.ValidFrom.formatted(.dateTime.weekday(.wide))
            return "\(day) \(warning.DangerLevel.localizedName)"
        }.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(region.Name)
                .font(.body)
            Spacer()
            ForEach(region.AvalancheWarningList) { warning in
                WarningLevelCell(dangerLevel: warning.DangerLevel)
                    .frame(width: 32, height: 32)
                    .cornerRadius(8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(region.Name), \(dangerLevelsSummary)")
    }
}

#Preview("Region Row") {
    RegionRow(region: testARegions[0])
}
