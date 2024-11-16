import SwiftUI

struct RegionRow: View {
    var region: RegionSummary
    
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
    }
}

#Preview("Region Row") {
    RegionRow(region: testARegions[0])
}
