import SwiftUI

struct RegionWatchRow: View {
    var warning: AvalancheWarningSimple
    
    var textColor: Color {
        return warning.DangerLevel == .level2 ? .black : .white;
    }
    
    var body: some View {
        ZStack {
            DangerGradient(dangerLevel: warning.DangerLevel)
            HStack {
                WarningSymbolLevel(dangerLevel: warning.DangerLevel, size: 48.0)
                    .frame(width: 60)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .padding(.leading, 8)
                VStack(alignment: .leading) {
                    Text(warning.ValidFrom.getDayName())
                        .foregroundColor(textColor)
                        .textCase(.uppercase)
                        .font(.caption2)
                    Text(warning.RegionName)
                        .foregroundColor(textColor)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }
}

struct RegionWatchRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegionWatchRow(warning: testWarningLevel4)
            RegionWatchRow(warning: testWarningLevel2)
        }
    }
}