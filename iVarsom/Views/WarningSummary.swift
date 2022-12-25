import SwiftUI
import DynamicColor

struct WarningSummary: View {
    var warning: AvalancheWarningSimple
    var mainTextFont: Font = .body
    var mainTextLineLimit: Int = .max
    var includeLocationIcon: Bool = false
    
    var textColor: Color {
        return warning.DangerLevel == .level2 ? .black : .white;
    }
    
    var body: some View {
        let icon = Text(Image(systemName: "location.fill")).font(.system(size: 16))
        
        ZStack {
            DangerGradient(dangerLevel: warning.DangerLevel)
            HStack {
                WarningSymbolLevel(dangerLevel: warning.DangerLevel)
                    .frame(width: 90)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                VStack(alignment: .leading) {
                    Spacer()
                    Text(warning.ValidFrom.formatted(date: .complete, time: .omitted))
                        .textCase(.uppercase)
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .padding(.top, 6)
                    #if os(iOS)
                        .textSelection(.enabled)
                    #endif
                    (includeLocationIcon ?
                     (icon + Text("\(warning.RegionName)")) :
                        Text("\(warning.RegionName))"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 2)
                    #if os(iOS)
                        .textSelection(.enabled)
                    #endif
                    Text(warning.MainText)
                        .font(mainTextFont)
                        .foregroundColor(textColor)
                        .padding(.bottom, 6)
                        .padding(.trailing, 4)
                    #if os(iOS)
                        .textSelection(.enabled)
                    #endif
                        .lineLimit(mainTextLineLimit)
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
                Spacer()
                DangerScale(dangerLevel: warning.DangerLevel)
                    .frame(width: 12)
            }
        }
    }
}

struct WarningSummary_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WarningSummary(warning: testWarningLevel0)
                .previewLayout(.fixed(width: 340, height: 180))
            
            WarningSummary(warning: testWarningLevel1, includeLocationIcon: true)
                .previewLayout(.fixed(width: 340, height: 180))
            
            WarningSummary(warning: testWarningLevel2)
                .previewLayout(.fixed(width: 340, height: 180))
            
            WarningSummary(warning: testWarningLevel3)
                .previewLayout(.fixed(width: 340, height: 180))
            
            WarningSummary(warning: testWarningLevel4)
                .previewLayout(.fixed(width: 340, height: 180))
        }
    }
}
