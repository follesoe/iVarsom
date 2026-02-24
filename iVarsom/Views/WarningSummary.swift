import SwiftUI

struct WarningSummary: View {
    var warning: any AvalancheWarningProtocol
    var mainTextFont: Font = .body
    var regionNameFont: Font = .title3
    var mainTextLineLimit: Int = .max
    var includeLocationIcon: Bool = false
    var compact: Bool = false
    
    var textColor: Color {
        return warning.DangerLevel == .level5 ? .white : .black
    }
    
    var body: some View {        
        let warningDate = warning.ValidFrom.formatted(date: .complete, time: .omitted)
        HStack {
            WarningSymbolLevel(dangerLevel: warning.DangerLevel, size: compact ? 38 : 54)
                .frame(width: compact ? 70 : 90)
                .padding(.top, compact ? 4 : 8)
                .padding(.bottom, compact ? 4 : 8)
                .speechLocale(warning.textLanguageCode)
            VStack(alignment: .leading) {
                if !compact { Spacer() }
                Text(includeLocationIcon ?
                     "\(Image(systemName: "location.fill")) \(warningDate)" :
                        "\(warningDate)")
                    .textCase(.uppercase)
                    .font(.caption2)
                    .foregroundColor(textColor)
                    .padding(.top, compact ? 2 : 6)
                #if os(iOS)
                    .textSelection(.enabled)
                #endif
                Text(warning.RegionName)
                    .font(regionNameFont)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)
                #if os(iOS)
                    .textSelection(.enabled)
                #endif
                    .speechLocale(for: warning.RegionId)
                Text(warning.MainText)
                    .font(mainTextFont)
                    .foregroundColor(textColor)
                    .padding(.bottom, compact ? 2 : 6)
                    .padding(.trailing, 4)
                #if os(iOS)
                    .textSelection(.enabled)
                #endif
                    .lineLimit(mainTextLineLimit)
                    .speechLocale(warning.textLanguageCode)
                if !compact { Spacer() }
            }
            .padding(.top, compact ? 4 : 12)
            .padding(.bottom, compact ? 4 : 12)
            Spacer()
            DangerScale(dangerLevel: warning.DangerLevel)
                .frame(width: 12)
        }
        .background(DangerGradient(dangerLevel: warning.DangerLevel))
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
