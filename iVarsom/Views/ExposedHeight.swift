import SwiftUI

struct ExposedHeight: View {
    let exposedHeightFill: Int
    var body: some View {
        let imageName = switch exposedHeightFill {
        case 1: "ExposedTop"
        case 2: "ExposedBottom"
        case 3: "ExposedTopBottom"
        case 4: "ExposedMiddle"
        default: "ExposedTop"
        }
        Image(imageName)
            .resizable()
            .scaledToFit()
    }
}

struct ExposedHeight_Previews: PreviewProvider {
    static var previews: some View {
        ExposedHeight(exposedHeightFill: 1)
        ExposedHeight(exposedHeightFill: 2)
        ExposedHeight(exposedHeightFill: 3)
        ExposedHeight(exposedHeightFill: 4)
    }
}
