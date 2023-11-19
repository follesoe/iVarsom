import SwiftUI

struct AvalancheProblemView: View {
    let problem: AvalancheProblem

    var body: some View {
        VStack(alignment: .leading) {
            Text(problem.AvalancheProblemTypeName)
                .padding()
            HStack(alignment: .center) {
                ExposedHeight(exposedHeightFill: problem.ExposedHeightFill)
                    .frame(width: 48, height: 48)
                    .padding()
                Expositions(
                    sectors: problem.ValidExpositionsBool)
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
