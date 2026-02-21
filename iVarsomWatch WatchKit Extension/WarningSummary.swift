import SwiftUI

struct WarningSummary: View {
    var selectedWarning: AvalancheWarningDetailed

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private var hasEmergencyWarning: Bool {
        guard let warning = selectedWarning.EmergencyWarning else { return false }
        return !warning.isEmpty && warning != "Not given" && warning != "Ikke gitt"
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                DangerIcon(dangerLevel: selectedWarning.DangerLevel)
                    .frame(width: 36, height: 36)
                Spacer()
                Text("\(selectedWarning.DangerLevel.description)")
                    .font(.system(size: 36))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
            }
            HStack {
                Text(selectedWarning.ValidFrom.formatted(
                    Date.FormatStyle()
                        .day(.defaultDigits)
                        .weekday(.wide)
                        .month(.abbreviated))
                    .firstUppercased
                )
                .fontWeight(.bold)
                .foregroundColor(.white)
                if hasEmergencyWarning {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            Text(selectedWarning.MainText)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }
}

#Preview("Warning Summary") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return WarningSummary(selectedWarning: warningDetailed[0])
}
