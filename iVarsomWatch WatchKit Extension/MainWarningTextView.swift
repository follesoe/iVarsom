import SwiftUI

struct MainWarningTextView: View {
    var selectedWarning: AvalancheWarningDetailed
    var body: some View {
        ScrollView {
            let pubTime = selectedWarning.PublishTime.formatted(date: .abbreviated, time: .shortened)
            VStack(alignment: .leading) {
                Text(selectedWarning.MainText)
                    .padding()
                if let danger = selectedWarning.AvalancheDanger {
                    Text(danger)
                        .padding()
                }
                Text("Published: \(pubTime)")
                    .font(.system(size: 11))
                    .padding()
            }
        }
    }
}

#Preview {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return MainWarningTextView(selectedWarning: warningDetailed[0])
}
