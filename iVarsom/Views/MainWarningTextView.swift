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
        // A navigation container gives the close button standard bar placement.
        // With only Close, a horizontal bar leaves the text the sheet's full
        // width on iPhone Duo's outer display.
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) { isShowingSheet = false }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .horizontalSheetBar()
        }
    }

    private var content: some View {
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
            }
            .padding()
        }
    }
}

#Preview("Main Warning Text View") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return MainWarningTextView(selectedWarning: warningDetailed[0], isShowingSheet: .constant(false))
}
