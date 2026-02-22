import SwiftUI

struct MainWarningTextView: View {
    var selectedWarning: AvalancheWarningDetailed
    @Binding var isShowingSheet: Bool
    var body: some View {
        ScrollView {
            let pubTime = selectedWarning.PublishTime.formatted(date: .abbreviated, time: .shortened)
            VStack(alignment: .center, spacing: 14) {
                Text("Avalanche risk assessment")
                    .font(.title)
                    .speechLocale(selectedWarning.textLanguageCode)
                Text("Published: \(pubTime)")
                    .font(.caption)
                
                if let danger = selectedWarning.AvalancheDanger {
                    Text("\(selectedWarning.MainText)\n\(danger)")
                        .speechLocale(selectedWarning.textLanguageCode)
                } else {
                    Text(selectedWarning.MainText)
                        .speechLocale(selectedWarning.textLanguageCode)
                }
                Button(String(localized: "Dismiss"), action: { isShowingSheet.toggle() })
            }
            .padding()
        }
    }
}

#Preview("Main Warning Text View") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return MainWarningTextView(selectedWarning: warningDetailed[0], isShowingSheet: .constant(false))
}
