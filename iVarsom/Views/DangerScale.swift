import SwiftUI

struct DangerScale: View {
    var dangerLevel: DangerLevel
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color("DangerLevel5").opacity(dangerLevel == .level5 ? 0 : 1))
            Rectangle().fill(Color("DangerLevel4").opacity(dangerLevel == .level4 ? 0 : 1))
            Rectangle().fill(Color("DangerLevel3").opacity(dangerLevel == .level3 ? 0 : 1))
            Rectangle().fill(Color("DangerLevel2").opacity(dangerLevel == .level2 ? 0 : 1))
            Rectangle().fill(Color("DangerLevel1").opacity(dangerLevel == .level1 ? 0 : 1))
        }
    }
}
