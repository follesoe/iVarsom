import SwiftUI

struct RegionWatchRow: View {
    var warning: AvalancheWarningSimple
    var isLocalRegion:Bool
    @ScaledMetric(relativeTo: .title2) private var symbolSize = 32.0
    
    var textColor: Color {
        return warning.DangerLevel == .level5 ? .white : .black
    }
    
    private var regionName: String {
        RegionOption.getName(id: warning.RegionId, def: warning.RegionName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                DangerIcon(dangerLevel: warning.DangerLevel)
                    .frame(width: symbolSize, height: symbolSize)
                Text(warning.DangerLevel.description)
                    .font(.title2.weight(.heavy))
                Spacer(minLength: 0)
                let warningDate = warning.formattedForecastDate(.dateTime.weekday(.wide))
                Text(isLocalRegion ?
                     "\(Image(systemName: "location.fill")) \(warningDate)" :
                        "\(warningDate)")
                    .font(.caption2)
            }
            Text(regionName)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .foregroundStyle(textColor)
        .background(warning.DangerLevel.color.gradient)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(regionName), \(warning.formattedForecastDate(.dateTime.weekday(.wide))), \(String(localized: "Danger level \(warning.DangerLevel.description), \(warning.DangerLevel.localizedName)"))")
        .accessibilityValue(isLocalRegion ? String(localized: "Current position") : "")
    }
}

#Preview("Level 4 Row") {
    return RegionWatchRow(warning: testWarningLevel4, isLocalRegion: false)
}

#Preview("Level 2 Local Row") {
    return RegionWatchRow(warning: testWarningLevel2, isLocalRegion: true)
}
