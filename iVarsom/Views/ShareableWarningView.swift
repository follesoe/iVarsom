import SwiftUI

struct ShareableWarningView: View {
    let warning: AvalancheWarningDetailed
    var includeProblems: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                WarningSummary(warning: warning)
                if warning.hasActiveEmergencyWarning,
                   let emergencyWarning = warning.EmergencyWarning {
                    EmergencyWarningBanner(message: emergencyWarning, textLanguageCode: warning.textLanguageCode)
                }
            }
            .cornerRadius(10)
            .padding(includeProblems ? [.horizontal, .top] : .all)

            if includeProblems, let problems = warning.AvalancheProblems, !problems.isEmpty {
                VStack(alignment: .leading) {
                    ForEach(problems) { problem in
                        AvalancheProblemView(problem: problem, textLanguageCode: warning.textLanguageCode)
                            .padding()
                    }
                }
            }
        }
        .frame(width: 390)
        .fixedSize(horizontal: false, vertical: true)
        .if(!includeProblems) { $0.background(.clear) }
        .if(includeProblems) { $0.background(.white) }
        .environment(\.accessibilityBridgeDisabled, true)
    }
}

private extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition { transform(self) } else { self }
    }
}
