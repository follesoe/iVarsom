import SwiftUI

struct AvalancheProblemDetailsView: View {
    let problem: AvalancheProblem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(problem.TriggerSenitivityPropagationDestuctiveSizeText).padding()
                Text(problem.AvalCauseName)
                    .font(.system(size: 12)).italic().padding()
            }
        }
    }
}

#Preview {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return AvalancheProblemDetailsView(problem: warningDetailed[0].AvalancheProblems![0])
}
