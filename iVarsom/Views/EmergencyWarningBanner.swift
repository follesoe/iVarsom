import SwiftUI

struct EmergencyWarningBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: String
    var textLanguageCode: String = "nb"
    var font: Font = .subheadline
    var verticalPadding: CGFloat = 10

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
                .font(font)
            Text(message)
                .foregroundColor(foregroundColor)
                .font(font)
                .fontWeight(.medium)
                .speechLocale(textLanguageCode)
            Spacer()
        }
        .padding(.leading, 22)
        .padding(.trailing, 12)
        .padding(.vertical, verticalPadding)
        .background(backgroundColor)
    }
}

#Preview("Emergency Warning Banner", traits: .sizeThatFitsLayout) {
    EmergencyWarningBanner(message: "Medium sized natural avalanches")
}
