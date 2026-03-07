import SwiftUI
import Translation

struct RegionDetail: View {
    @Binding var selectedRegion: RegionSummary?
    @Binding var selectedWarning: AvalancheWarningDetailed?
    @Binding var warnings: [AvalancheWarningDetailed]
    @State private var showWarningText = false
    @State private var translatedTexts: [String: String] = [:]
    @State private var isTranslating = false
    @State private var downloadConfig: TranslationSession.Configuration?

    private var isTranslated: Bool { !translatedTexts.isEmpty }

    private let sourceLanguage = Locale.Language(identifier: "en")

    private var targetLanguage: Locale.Language {
        guard let preferred = Locale.preferredLanguages.first else {
            return Locale.Language(identifier: "en")
        }
        return Locale(identifier: preferred).language
    }

    private var targetLanguageCode: String {
        targetLanguage.languageCode?.identifier ?? "en"
    }

    private var showTranslateButton: Bool {
        let code = targetLanguageCode
        return code != "nb" && code != "nn" && code != "sv" && code != "en"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let selectedWarning = selectedWarning {
                    if showTranslateButton {
                        translateButton
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    VStack(spacing: 0) {
                        WarningSummary(
                            warning: selectedWarning,
                            includeLocationIcon: false,
                            translatedTexts: translatedTexts,
                            translatedLanguageCode: isTranslated ? targetLanguageCode : nil)
                        if selectedWarning.hasActiveEmergencyWarning,
                       let emergencyWarning = selectedWarning.EmergencyWarning {
                            EmergencyWarningBanner(
                                message: emergencyWarning,
                                textLanguageCode: isTranslated ? targetLanguageCode : selectedWarning.textLanguageCode,
                                translatedTexts: translatedTexts)
                        }
                    }
                    .frame(maxWidth: 600)
                    .cornerRadius(10)
                    .padding()
                    .sheet(isPresented: $showWarningText, content: {
                        MainWarningTextView(
                            selectedWarning: selectedWarning,
                            isShowingSheet: $showWarningText,
                            translatedTexts: translatedTexts,
                            translatedLanguageCode: isTranslated ? targetLanguageCode : nil)
                    })
                    .onTapGesture(perform: {
                        showWarningText = true
                    })
                }

                if warnings.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader { value in
                            HStack(spacing: 8) {
                                ForEach(warnings) { warning in
                                    let action = {
                                        withAnimation {
                                            self.selectedWarning = warning
                                            value.scrollTo(warning.id)
                                        }
                                    }

                                    let isSelected = selectedWarning?.RegId == warning.RegId

                                    let cell = DayCell(
                                        dangerLevel: warning.DangerLevel,
                                        date: warning.ValidFrom,
                                        isSelected: isSelected,
                                        hasEmergencyWarning: warning.hasActiveEmergencyWarning)
                                            .padding(.top, 5)
                                            .id(warning.id)

                                    Button(action: action) { cell }
                                        .buttonStyle(.plain)
                                        .speechLocale(for: warning.RegionId)
                                }
                                .onAppear {
                                    if !warnings.isEmpty, let lastWarning = warnings.filter({ $0.id > 0 }).last {
                                        print("Scroll to \(lastWarning.id)")
                                        value.scrollTo(lastWarning.id)
                                    }
                                }
                            }
                        }
                    }
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
                                    textLanguageCode: isTranslated ? targetLanguageCode : selectedWarning.textLanguageCode,
                                    translatedTexts: translatedTexts)
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
        .translationTask(downloadConfig) { session in
            await performTranslation(session: session)
        }
        .onChange(of: selectedWarning?.RegId) { _, _ in
            translatedTexts = [:]
        }
        .navigationTitle(selectedRegion?.Name ?? "Region")
        .navigationBarTitleDisplayMode(.large)
    }

    private var translateButton: some View {
        HStack {
            if isTranslating {
                ProgressView()
                    .controlSize(.small)
                Text(NSLocalizedString("Translating...", comment: "Translation in progress indicator"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    if isTranslated {
                        translatedTexts = [:]
                    } else {
                        Task {
                            await translateContent()
                        }
                    }
                } label: {
                    Label(
                        isTranslated
                            ? NSLocalizedString("Show Original", comment: "Button to show original untranslated text")
                            : NSLocalizedString("Translate", comment: "Button to translate warning text"),
                        systemImage: "translate"
                    )
                    .font(.subheadline)
                }
            }
            Spacer()
            if isTranslated {
                Text(NSLocalizedString("Machine translated from English", comment: "Indicator that text was machine translated from English"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func translateContent() async {
        let availability = LanguageAvailability()
        let status = await availability.status(from: sourceLanguage, to: targetLanguage)

        switch status {
        case .installed:
            // Language pack available — translate silently
            let session = TranslationSession(
                installedSource: sourceLanguage,
                target: targetLanguage
            )
            await performTranslation(session: session)

        case .supported:
            // Language pack needs download — show system dialog
            downloadConfig = .init(source: sourceLanguage, target: targetLanguage)

        default:
            break
        }
    }

    private func performTranslation(session: TranslationSession) async {
        guard let warning = selectedWarning else { return }
        isTranslating = true
        defer { isTranslating = false }

        nonisolated(unsafe) let session = session
        var requests: [TranslationSession.Request] = []
        requests.append(.init(sourceText: warning.MainText))
        if let danger = warning.AvalancheDanger, !danger.isEmpty {
            requests.append(.init(sourceText: danger))
        }
        if let emergency = warning.EmergencyWarning, !emergency.isEmpty {
            requests.append(.init(sourceText: emergency))
        }
        if let problems = warning.AvalancheProblems {
            for problem in problems {
                requests.append(.init(sourceText: problem.AvalancheProblemTypeName))
                if !problem.TriggerSenitivityPropagationDestuctiveSizeText.isEmpty {
                    requests.append(.init(sourceText: problem.TriggerSenitivityPropagationDestuctiveSizeText))
                }
            }
        }

        do {
            let responses = try await session.translations(from: requests)
            var texts: [String: String] = [:]
            for response in responses {
                texts[response.sourceText] = response.targetText
            }
            translatedTexts = texts
        } catch {
            // Translation failed
        }
    }
}

#Preview("Region Detail") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return NavigationView {
        RegionDetail(
            selectedRegion: .constant(testRegions[1]),
            selectedWarning: .constant(warningDetailed[0]),
            warnings: .constant(warningDetailed))
    }
}
