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
        .background(
            DangerGradient(dangerLevel: dangerLevel)
        )
    }
}

struct WarningLevelCell_Previews: PreviewProvider {
    static var previews: some View {
        WarningLevelCell(dangerLevel: .level3)
            .previewLayout(.fixed(width: 40, height: 40))
    }
}
