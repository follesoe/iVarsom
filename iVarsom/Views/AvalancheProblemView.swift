import SwiftUI

struct AvalancheProblemView: View {
    let problem: AvalancheProblem

    var body: some View {
        HStack {
            Rectangle()
                .fill(problem.DangerLevelEnum.color)
                .frame(width: 8)
                .padding(.trailing, 8)
            VStack(alignment: .leading) {
                Text(problem.AvalancheProblemTypeName)
                    .font(.subheadline)
                    .bold()
                HStack {
                    Expositions(sectors: problem.ValidExpositionsBool)
                        .frame(width: 78, height: 78)
                    ExposedHeight(exposedHeightFill: problem.ExposedHeightFill)
                        .frame(width: 54, height: 54)
                    ExposedHeightArrow(
                        exposedHeight1: problem.ExposedHeight1,
                        exposedHeight2: problem.ExposedHeight2,
                        exposedHeightFill: problem.ExposedHeightFill,
                        fontSize: 24)
                    .padding(.leading, 10)
                    Spacer()
                }
                
                Text(problem.TriggerSenitivityPropagationDestuctiveSizeText)
            }
        }
    }
}

#Preview("Avalanche Problem", traits: .fixedLayout(width: 300, height: 100)) {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return AvalancheProblemView(problem: warningDetailed[0].AvalancheProblems![0])
}
