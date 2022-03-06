import SwiftUI

struct DayCell: View {
    let dangerLevel: DangerLevel
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        VStack() {
            WarningLevelCell(dangerLevel: dangerLevel)
                .frame(width: 42, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary, lineWidth: isSelected ? 4 : 0)
                )
                .cornerRadius(8)
            Text(date.formatted(.dateTime.day(.twoDigits).month(.twoDigits)))
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
    }
}

struct DayCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DayCell(dangerLevel: .level1, date: Date(), isSelected: false)
                .padding()
                .previewLayout(.sizeThatFits)
            
            DayCell(dangerLevel: .level2, date: Date(), isSelected: true)
                .padding()
                .previewLayout(.sizeThatFits)
            
            DayCell(dangerLevel: .level3, date: Date(), isSelected: true)
                .preferredColorScheme(.dark)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
