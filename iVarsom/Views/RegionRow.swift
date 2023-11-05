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

struct RegionRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegionRow(region: testARegions[0])
                .previewLayout(.fixed(width: 380, height: 48))
            
            RegionRow(region: testARegions[10])
                .preferredColorScheme(.dark)
                .previewLayout(.fixed(width: 380, height: 48))
        }
    }
}
