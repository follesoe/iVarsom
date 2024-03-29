import SwiftUI

struct AvalancheProblemView: View {
    let problem: AvalancheProblem

    var body: some View {
        VStack(alignment: .leading) {
            Text(problem.AvalancheProblemTypeName)
                .padding(.horizontal)
            HStack(alignment: .center) {
                Expositions(sectors: problem.ValidExpositionsBool)
                    .padding(.trailing, 10)
                ExposedHeight(exposedHeightFill: problem.ExposedHeightFill)
                    .frame(width: 42, height: 42)
                ExposedHeightArrow(
                    exposedHeight1: problem.ExposedHeight1,
                    exposedHeight2: problem.ExposedHeight2,
                    exposedHeightFill: problem.ExposedHeightFill,
                    fontSize: 16)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Avalanche Problem") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return AvalancheProblemView(problem: warningDetailed[0].AvalancheProblems![0])
}
