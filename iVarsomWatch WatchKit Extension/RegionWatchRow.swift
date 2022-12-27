import SwiftUI

struct RegionWatchRow: View {
    var warning: AvalancheWarningSimple
    var isLocalRegion:Bool
    
    var textColor: Color {
        return warning.DangerLevel == .level2 ? .black : .white;
    }
    
    var body: some View {
        ZStack {
            DangerGradient(dangerLevel: warning.DangerLevel)
            HStack {
                WarningSymbolLevel(dangerLevel: warning.DangerLevel, size: 46.0)
                    .frame(width: 56)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .padding(.leading, 5)
                VStack(alignment: .leading) {
                    let warningDate = warning.ValidFrom.getDayName()
                    Text(isLocalRegion ?
                         "\(Image(systemName: "location.fill")) \(warningDate)" :
                            "\(warningDate)")
                        .foregroundColor(textColor)
                        .textCase(.uppercase)
                        .font(.caption2)
                    Text(RegionOption.getName(id: warning.RegionId, def: warning.RegionName))
                        .foregroundColor(textColor)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(3)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
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
            RegionWatchRow(warning: testWarningLevel4, isLocalRegion: false)
            RegionWatchRow(warning: testWarningLevel2, isLocalRegion: true)
        }
    }
}
