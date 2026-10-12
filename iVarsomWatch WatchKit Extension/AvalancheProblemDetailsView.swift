import SwiftUI

struct AvalancheProblemDetailsView: View {
    let problem: AvalancheProblem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(problem.TriggerSenitivityPropagationDestuctiveSizeText)
                    .font(.body)
                Text(problem.AvalCauseName)
                    .font(.footnote).italic()
            }
            .scenePadding()
        }
    }
}

#Preview("Avalanche Problem Details") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return AvalancheProblemDetailsView(problem: warningDetailed[0].AvalancheProblems![0])
}
