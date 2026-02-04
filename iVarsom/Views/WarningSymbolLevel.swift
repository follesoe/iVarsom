import SwiftUI

struct WarningSymbolLevel: View {
    var dangerLevel: DangerLevel
    var size = 54.0
    
    var textColor: Color {
        return dangerLevel == .level5 ? .white : .black
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack(alignment: .center) {
                DangerIcon(dangerLevel: dangerLevel)
                    .frame(width: size, height: size)
            }.frame(maxWidth: .infinity)
            Text("\(dangerLevel.description)")
                .font(.system(size: size))
                .fontWeight(.heavy)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}

#Preview("Unknown") {
    WarningSymbolLevel(dangerLevel: .unknown)
        .background(DangerGradient(dangerLevel: .unknown))
        .frame(width: 150, height: 150)
}

#Preview("Level 1") {
    WarningSymbolLevel(dangerLevel: .level1)
        .background(DangerGradient(dangerLevel: .level1))
        .frame(width: 150, height: 150)
}

#Preview("Level 2") {
    WarningSymbolLevel(dangerLevel: .level2)
        .background(DangerGradient(dangerLevel: .level2))
        .frame(width: 150, height: 150)
}

#Preview("Level 3") {
    WarningSymbolLevel(dangerLevel: .level3)
        .background(DangerGradient(dangerLevel: .level3))
        .frame(width: 150, height: 150)
}

#Preview("Level 4") {
    WarningSymbolLevel(dangerLevel: .level4)
        .background(DangerGradient(dangerLevel: .level4))
        .frame(width: 150, height: 150)
}

#Preview("Level 5") {
    WarningSymbolLevel(dangerLevel: .level5)
        .background(DangerGradient(dangerLevel: .level5))
        .frame(width: 150, height: 150)
}

#Preview("Level 3 Tall") {
    WarningSymbolLevel(dangerLevel: .level3)
        .background(DangerGradient(dangerLevel: .level3))
        .frame(width: 150, height: 300)
}
