import SwiftUI

struct WarningSummary: View {
    var selectedWarning: AvalancheWarningDetailed
    @ScaledMetric(relativeTo: .title2) private var symbolSize = 36.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        DangerIcon(dangerLevel: selectedWarning.DangerLevel)
                            .frame(width: symbolSize, height: symbolSize)
                        Spacer()
                        Text(selectedWarning.DangerLevel.description)
                            .font(.title.weight(.heavy))
                    }
                    Text(selectedWarning.DangerLevel.localizedName)
                        .font(.headline)
                }
                .padding(12)
                .foregroundStyle(selectedWarning.DangerLevel == .level5 ? .white : .black)
                .background(selectedWarning.DangerLevel.color, in: .rect(cornerRadius: 16))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "Danger level \(selectedWarning.DangerLevel.description), \(selectedWarning.DangerLevel.localizedName)"))

                Text(selectedWarning.formattedForecastDate(
                    .dateTime.day().weekday(.wide).month(.abbreviated)))
                    .font(.headline)
                if selectedWarning.hasActiveEmergencyWarning {
                    Label("Emergency warning", systemImage: "exclamationmark.circle.fill")
                        .font(.headline)
                }
                Text(selectedWarning.MainText)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .speechLocale(selectedWarning.textLanguageCode)
            }
            .scenePadding()
        }
    }
}

#Preview("Warning Summary") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return WarningSummary(selectedWarning: warningDetailed[0])
}
