import SwiftUI

struct WarningLevelCell: View {
    let dangerLevel: DangerLevel
    
    var body: some View {
        VStack {
            Text("\(dangerLevel.description)")
                .foregroundColor(.white)
                .font(.headline)
                .fontWeight(.semibold)
                .shadow(color: .gray, radius: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DangerGradient(dangerLevel: dangerLevel))
    }
}

#Preview("Warning Level Cell") {
    WarningLevelCell(dangerLevel: .level3)
        .frame(width: 40, height: 40)
}
