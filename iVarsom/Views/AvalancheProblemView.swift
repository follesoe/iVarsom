import SwiftUI

struct AvalancheProblemView: View {
    let problem: AvalancheProblem
    var textLanguageCode: String = "nb"

    var body: some View {
        HStack {
            Rectangle()
                .fill(problem.DangerLevelEnum.color)
                .frame(width: 8)
                .padding(.trailing, 8)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(problem.AvalancheProblemTypeName)
                    .font(.subheadline)
                    .bold()
                    .speechLocale(textLanguageCode)
                #if os(iOS)
                    .textSelection(.enabled)
                #endif
                HStack {
                    Image(problem.AvalancheProblemTypeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                        .frame(width: 78, height: 78)
                        .accessibilityLabel(problem.AvalancheProblemTypeName)
                        .accessibilityRemoveTraits(.isImage)
                        .speechLocale(textLanguageCode)
                    Expositions(sectors: problem.ValidExpositionsBool)
                        .frame(width: 78, height: 78)
                        .speechLocale(textLanguageCode)
                    ExposedHeight(exposedHeightFill: problem.ExposedHeightFill)
                        .frame(width: 54, height: 54)
                        .speechLocale(textLanguageCode)
                    if problem.ExposedHeight1 != 0 || problem.ExposedHeight2 != 0 {
                        ExposedHeightArrow(
                            exposedHeight1: problem.ExposedHeight1,
                            exposedHeight2: problem.ExposedHeight2,
                            exposedHeightFill: problem.ExposedHeightFill,
                            fontSize: 24)
                        .padding(.leading, 10)
                        .speechLocale(textLanguageCode)
                    }
                    Spacer()
                }

                Text(problem.TriggerSenitivityPropagationDestuctiveSizeText)
                    .speechLocale(textLanguageCode)
                #if os(iOS)
                    .textSelection(.enabled)
                #endif
            }
        }
    }
}

#Preview("Avalanche Problem", traits: .fixedLayout(width: 300, height: 100)) {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return AvalancheProblemView(problem: warningDetailed[0].AvalancheProblems![0])
}
