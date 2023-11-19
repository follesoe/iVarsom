import SwiftUI

struct AvalancheProblemView: View {
    let problem: AvalancheProblem

    var body: some View {
        VStack {
            Text(problem.AvalancheProblemTypeName)
            HStack {
                ExposedHeight(exposedHeightFill: problem.ExposedHeightFill)
                    .frame(width: 128, height: 128)
                Expositions(sectors: problem.ValidExpositionsBool)
                    .frame(width: 128, height: 128)
            }
        }
    }
}
