import SwiftUI

struct DangerGradient: View {
    var dangerLevel: DangerLevel
    var body: some View {
        Rectangle()
            .fill(dangerLevel.color.gradient)
    }
}
