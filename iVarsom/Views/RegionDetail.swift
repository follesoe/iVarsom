import SwiftUI
import Translation

struct RegionDetail: View {
    let selectedRegion: RegionSummary
    @Binding var selectedWarningID: Int?
    let warnings: [AvalancheWarningDetailed]
    @State private var showWarningText = false
    @State private var translation = WarningTranslationModel()

    private var selectedWarning: AvalancheWarningDetailed? {
        warnings.first { $0.id == selectedWarningID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let selectedWarning = selectedWarning {
                    if translation.isAvailable {
                        translateButton
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    VStack(spacing: 0) {
                        WarningSummary(
                            warning: selectedWarning,
                            includeLocationIcon: false,
                            translatedTexts: translation.texts,
                            translatedLanguageCode: translation.isTranslated ? translation.languageCode : nil)
                        if selectedWarning.hasActiveEmergencyWarning,
                            let emergencyWarning = selectedWarning.EmergencyWarning
                        {
                            EmergencyWarningBanner(
                                message: emergencyWarning,
                                textLanguageCode: translation.isTranslated
                                    ? translation.languageCode : selectedWarning.textLanguageCode,
                                translatedTexts: translation.texts)
                        }
                    }
                    .frame(maxWidth: 600)
                    .cornerRadius(10)
                    .padding()
                    .sheet(
                        isPresented: $showWarningText,
                        content: {
                            MainWarningTextView(
                                selectedWarning: selectedWarning,
                                isShowingSheet: $showWarningText,
                                translatedTexts: translation.texts,
                                translatedLanguageCode: translation.isTranslated ? translation.languageCode : nil)
                        }
                    )
                    .onTapGesture(perform: {
                        showWarningText = true
                    })
                }

                if warnings.count > 1 {
                    WarningDayPicker(warnings: warnings, selectedWarningID: $selectedWarningID)
                        .padding()
                }
                if let selectedWarning = selectedWarning {
                    if let problems = selectedWarning.AvalancheProblems {
                        VStack(alignment: .leading) {
                            Text("Avalanche problems").font(.headline)
                                .padding(.horizontal)
                            ForEach(problems) { problem in
                                AvalancheProblemView(
                                    problem: problem,
                                    textLanguageCode: translation.isTranslated
                                        ? translation.languageCode : selectedWarning.textLanguageCode,
                                    translatedTexts: translation.texts
                                )
                                .padding()
                            }
                        }
                        .frame(maxWidth: 600)
                    }
                    if Country.from(regionId: selectedWarning.RegionId) == .sweden {
                        Link("Read complete warning on lavinprognoser.se.", destination: selectedWarning.VarsomUrl)
                            .padding()
                    } else {
                        Link("Read complete warning on Varsom.no.", destination: selectedWarning.VarsomUrl)
                            .padding()
                    }
                }
            }
        }
        .translationTask(translation.configuration) { session in
            await translation.translate(using: session)
        }
        .onChange(of: selectedWarning.map(WarningIdentity.init), initial: true) { _, _ in
            translation.select(selectedWarning)
        }
        .navigationTitle(selectedRegion.Name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var translateButton: some View {
        HStack {
            if translation.isTranslating {
                ProgressView()
                    .controlSize(.small)
                Text(NSLocalizedString("Translating...", comment: "Translation in progress indicator"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    translation.toggle()
                } label: {
                    Label(
                        translation.isTranslated
                            ? NSLocalizedString("Show Original", comment: "Button to show original untranslated text")
                            : NSLocalizedString("Translate", comment: "Button to translate warning text"),
                        systemImage: "translate"
                    )
                    .font(.subheadline)
                }
            }
            Spacer()
            if translation.isTranslated {
                Text(
                    NSLocalizedString(
                        "Machine translated from English",
                        comment: "Indicator that text was machine translated from English")
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }

}

#Preview("Region Detail") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return NavigationStack {
        RegionDetail(
            selectedRegion: testRegions[1],
            selectedWarningID: .constant(warningDetailed[0].id),
            warnings: warningDetailed)
    }
}
