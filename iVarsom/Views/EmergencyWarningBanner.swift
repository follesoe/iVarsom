import SwiftUI

struct EmergencyWarningBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: String
    var textLanguageCode: String = "nb"

    private var backgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var foregroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(foregroundColor)
            Text(message.warningTextSpeechLanguage(textLanguageCode))
                .foregroundColor(foregroundColor)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor)
    }
}

#Preview("Emergency Warning Banner", traits: .sizeThatFitsLayout) {
    EmergencyWarningBanner(message: "Medium sized natural avalanches")
}
