import SwiftUI

struct DayCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let dangerLevel: DangerLevel
    let date: Date
    let isSelected: Bool
    var hasEmergencyWarning: Bool = false

    var body: some View {
        VStack() {
            WarningLevelCell(dangerLevel: dangerLevel)
                .frame(width: 42, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary, lineWidth: isSelected ? 4 : 0)
                )
                .cornerRadius(8)
                .overlay(alignment: .topTrailing) {
                    if hasEmergencyWarning {
                        EmergencyWarningIcon(colorScheme: colorScheme)
                    }
                }
            Text(date.formatted(.dateTime.day(.twoDigits).month(.twoDigits)))
                .font(.system(size: 13))
                .fontWeight(isSelected ? .heavy : .regular)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(date.formatted(.dateTime.weekday(.wide).day(.twoDigits).month(.wide))), \(String(localized: "Danger level \(dangerLevel.description), \(dangerLevel.localizedName)"))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct EmergencyWarningIcon: View {
    let colorScheme: ColorScheme
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: size, weight: .bold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                colorScheme == .dark ? .black : .white,
                colorScheme == .dark ? .white : .black
            )
            .offset(x: size * 0.2, y: size * -0.2)
    }
}

struct DayCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DayCell(dangerLevel: .level1, date: Date.current, isSelected: false)
                .padding()
                .previewLayout(.sizeThatFits)
            
            DayCell(dangerLevel: .level2, date: Date.current, isSelected: true)
                .padding()
                .previewLayout(.sizeThatFits)
            
            DayCell(dangerLevel: .level3, date: Date.current, isSelected: true)
                .preferredColorScheme(.dark)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
