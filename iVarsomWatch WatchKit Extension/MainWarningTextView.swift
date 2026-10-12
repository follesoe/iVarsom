import SwiftUI

struct MainWarningTextView: View {
    var selectedWarning: AvalancheWarningDetailed

    var body: some View {
        ScrollView {
            let pubTime = selectedWarning.PublishTime.formatted(date: .abbreviated, time: .shortened)
            VStack(alignment: .leading, spacing: 16) {
                if selectedWarning.hasActiveEmergencyWarning, let emergencyWarning = selectedWarning.EmergencyWarning {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .accessibilityHidden(true)
                        Text(emergencyWarning)
                            .fontWeight(.bold)
                    }
                }
                Text(selectedWarning.MainText)
                if let danger = selectedWarning.AvalancheDanger {
                    Text(danger)
                }
                Text("Published: \(pubTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.body)
            .scenePadding()
            .speechLocale(selectedWarning.textLanguageCode)
        }
    }
}

#Preview("Main Warning Text View") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return MainWarningTextView(selectedWarning: warningDetailed[0])
}
