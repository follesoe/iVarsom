import SwiftUI

struct DangerIcon: View {
    var dangerLevel: DangerLevel
    var useTintable: Bool = false
    
    var iconName: String {
        switch dangerLevel {
        case .unknown:
            return "IconDangerLevel0"
        case .level1:
            return "IconDangerLevel1"
        case .level2:
            return "IconDangerLevel2"
        case .level3:
            return "IconDangerLevel3"
        case .level4, .level5:
            return "IconDangerLevel4"
        }
    }
    
    var body: some View {
        let icon = useTintable ? iconName + "Tintable" : iconName
        Image(icon)
            .resizable()
            .scaledToFit()
    }
}
