import SwiftUI
import DynamicColor

struct DangerGradient: View {
    var dangerLevel: DangerLevel
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(DynamicColor(Color("DangerLevel\(dangerLevel.rawValue)")).lighter(amount: 0.075)),
                Color(DynamicColor(Color("DangerLevel\(dangerLevel.rawValue)")).darkened(amount: 0.10))
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }
}
