import SwiftUI

struct MainWarningTextView: View {
    var selectedWarning: AvalancheWarningDetailed
    var body: some View {
        ScrollView {
            let pubTime = selectedWarning.PublishTime.formatted(date: .abbreviated, time: .shortened)
            VStack {
                Text(selectedWarning.MainText)
                Text("Published: \(pubTime)")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .padding(.vertical)
            }.padding()
        }
    }
}


#Preview {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return MainWarningTextView(selectedWarning: warningDetailed[0])
}
