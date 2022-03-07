import SwiftUI

struct WarningSymbolLevel: View {
    var dangerLevel: DangerLevel
    
    var textColor: Color {
        return dangerLevel == .level2 ? .black : .white;
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack(alignment: .center) {
                DangerIcon(dangerLevel: dangerLevel)
                    .frame(width: 54, height: 54)
            }.frame(maxWidth: .infinity)
            Text("\(dangerLevel.description)")
                .font(.system(size: 54))
                .fontWeight(.heavy)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}

struct WarningSymbolLevel_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WarningSymbolLevel(dangerLevel: .unknown)
                .background(DangerGradient(dangerLevel: .unknown))
                .previewLayout(.fixed(width: 150, height: 150))
            
            WarningSymbolLevel(dangerLevel: .level1)
                .background(DangerGradient(dangerLevel: .level1))
                .previewLayout(.fixed(width: 150, height: 150))
            
            WarningSymbolLevel(dangerLevel: .level2)
                .background(DangerGradient(dangerLevel: .level2))
                .previewLayout(.fixed(width: 150, height: 150))
            
            WarningSymbolLevel(dangerLevel: .level3)
                .background(DangerGradient(dangerLevel: .level3))
                .previewLayout(.fixed(width: 150, height: 150))
            
            WarningSymbolLevel(dangerLevel: .level4)
                .background(DangerGradient(dangerLevel: .level4))
                .previewLayout(.fixed(width: 150, height: 150))
            
            WarningSymbolLevel(dangerLevel: .level5)
                .background(DangerGradient(dangerLevel: .level5))
                .previewLayout(.fixed(width: 150, height: 150))
            
            WarningSymbolLevel(dangerLevel: .level3)
                .background(DangerGradient(dangerLevel: .level3))
                .previewLayout(.fixed(width: 150, height: 300))
        }
    }
}
