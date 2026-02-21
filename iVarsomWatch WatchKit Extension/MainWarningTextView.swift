import SwiftUI

struct MainWarningTextView: View {
    var selectedWarning: AvalancheWarningDetailed

    private var hasEmergencyWarning: Bool {
        guard let warning = selectedWarning.EmergencyWarning else { return false }
        return !warning.isEmpty && warning != "Not given" && warning != "Ikke gitt"
    }

    var body: some View {
        ScrollView {
            let pubTime = selectedWarning.PublishTime.formatted(date: .abbreviated, time: .shortened)
            VStack(alignment: .leading) {
                if hasEmergencyWarning, let emergencyWarning = selectedWarning.EmergencyWarning {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(emergencyWarning)
                            .fontWeight(.bold)
                    }
                    .padding()
                }
                Text(selectedWarning.MainText)
                    .padding()
                if let danger = selectedWarning.AvalancheDanger {
                    Text(danger)
                        .padding()
                }
                Text("Published: \(pubTime)")
                    .font(.system(size: 11))
                    .padding()
            }
        }
    }
}

#Preview("Main Warning Text View") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return MainWarningTextView(selectedWarning: warningDetailed[0])
}
