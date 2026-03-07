import SwiftUI

struct MainWarningTextView: View {
    var selectedWarning: AvalancheWarningDetailed
    @Binding var isShowingSheet: Bool
    var translatedTexts: [String: String] = [:]
    var translatedLanguageCode: String? = nil

    private var langCode: String {
        translatedLanguageCode ?? selectedWarning.textLanguageCode
    }

    var body: some View {
        ScrollView {
            let pubTime = selectedWarning.PublishTime.formatted(date: .abbreviated, time: .shortened)
            let mainText = translatedTexts[selectedWarning.MainText] ?? selectedWarning.MainText

            VStack(alignment: .center, spacing: 14) {
                Text("Avalanche risk assessment")
                    .font(.title)
                    .speechLocale(langCode)
                Text("Published: \(pubTime)")
                    .font(.caption)

                if let danger = selectedWarning.AvalancheDanger {
                    let dangerText = translatedTexts[danger] ?? danger
                    Text("\(mainText)\n\(dangerText)")
                        .speechLocale(langCode)
                    #if os(iOS)
                        .textSelection(.enabled)
                    #endif
                } else {
                    Text(mainText)
                        .speechLocale(langCode)
                    #if os(iOS)
                        .textSelection(.enabled)
                    #endif
                }

                if !translatedTexts.isEmpty {
                    Text(NSLocalizedString("Machine translated from English", comment: "Indicator that text was machine translated from English"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
