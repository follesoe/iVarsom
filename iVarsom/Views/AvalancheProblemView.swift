import SwiftUI

struct AvalancheProblemView: View {
    let problem: AvalancheProblem

    var body: some View {
        VStack {
            Text(problem.AvalancheProblemTypeName)
            ExposedHeight(exposedHeightFill: problem.ExposedHeightFill)
                .frame(width: 64, height: 64)
        }
    }
}
