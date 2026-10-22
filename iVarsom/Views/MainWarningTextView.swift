import SwiftUI

struct MainWarningTextView: View {
    var selectedWarning: AvalancheWarningDetailed
    @Binding var isShowingSheet: Bool
    var translatedTexts: [String: String] = [:]
    var translatedLanguageCode: String? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var dangerSymbolSize = 52.0

    private var langCode: String {
        translatedLanguageCode ?? selectedWarning.textLanguageCode
    }

    private var assessment: String? {
        guard let text = selectedWarning.AvalancheDanger,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return translatedTexts[text] ?? text
    }

    private var isSwedishForecast: Bool {
        Country.from(regionId: selectedWarning.RegionId) == .sweden
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    forecastHeading
                    forecastSummary

                    if selectedWarning.hasActiveEmergencyWarning,
                        let message = selectedWarning.EmergencyWarning
                    {
                        EmergencyWarningBanner(
                            message: message,
                            textLanguageCode: langCode,
                            translatedTexts: translatedTexts,
                            font: .body,
                            verticalPadding: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .accessibilityElement(children: .combine)
                    }

                    if let assessment {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Avalanche risk assessment")
                                .font(.title2.bold())
                                .accessibilityAddTraits(.isHeader)
                            Text(assessment)
                                .font(.body)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                                .speechLocale(langCode)
                        }
                    }

                    if !translatedTexts.isEmpty {
                        Label("Machine translated from English", systemImage: "translate")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    sourceFooter
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
                #if os(iOS)
                    .textSelection(.enabled)
                #endif
            }
            .background(.background.secondary)
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { isShowingSheet = false }
                }
            }
            .horizontalSheetBar()
        }
    }

    private var forecastHeading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Avalanche forecast", systemImage: "mountain.2")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(selectedWarning.RegionName)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
                .speechLocale(for: selectedWarning.RegionId)
                .accessibilityAddTraits(.isHeader)
            Text(selectedWarning.formattedForecastDate(.init(date: .complete, time: .omitted)))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var forecastSummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Give the rating the full width when accessibility text is large.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 16))
            layout {
                DangerIcon(dangerLevel: selectedWarning.DangerLevel)
                    .frame(width: dangerSymbolSize, height: dangerSymbolSize)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Danger level")
                        .font(.subheadline.weight(.medium))
                    Text("\(selectedWarning.DangerLevel.description) · \(selectedWarning.DangerLevel.localizedName)")
                        .font(.title2.bold())
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .foregroundStyle(selectedWarning.DangerLevel == .level5 ? .white : .black)
            .background(selectedWarning.DangerLevel.color)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Danger level \(selectedWarning.DangerLevel.description), \(selectedWarning.DangerLevel.localizedName)"))

            Text(translatedTexts[selectedWarning.MainText] ?? selectedWarning.MainText)
                .font(.body.weight(.medium))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .speechLocale(langCode)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var sourceFooter: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text(isSwedishForecast
                    ? "Data from Swedish Environmental Protection Agency."
                    : "Data from The Norwegian Avalanche Warning Service.")
                    .font(.footnote.weight(.medium))
                Text("Published: \(selectedWarning.PublishTime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Link(destination: selectedWarning.VarsomUrl) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(isSwedishForecast
                        ? "Read complete warning on lavinprognoser.se."
                        : "Read complete warning on Varsom.no.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.up.right")
                        .accessibilityHidden(true)
                }
                .font(.subheadline.weight(.semibold))
                .padding(16)
                .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .contentShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

#Preview("Forecast assessment") {
    let warnings: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    MainWarningTextView(selectedWarning: warnings[0], isShowingSheet: .constant(true))
}

#Preview("Dark • large text") {
    let warnings: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    MainWarningTextView(selectedWarning: warnings[0], isShowingSheet: .constant(true))
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility1)
}
