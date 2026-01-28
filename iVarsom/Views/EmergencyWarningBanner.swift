import SwiftUI

struct EmergencyWarningBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black)
    }
}

#Preview("Emergency Warning Banner", traits: .sizeThatFitsLayout) {
    EmergencyWarningBanner(message: "Medium sized natural avalanches")
}
