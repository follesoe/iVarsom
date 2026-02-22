import SwiftUI

struct ExposedHeight: View {
    let exposedHeightFill: Int

    private var heightLabel: String {
        switch exposedHeightFill {
        case 1: return String(localized: "Above treeline")
        case 2: return String(localized: "Below treeline")
        case 3: return String(localized: "Above and below treeline")
        case 4: return String(localized: "Near treeline")
        default: return String(localized: "Above treeline")
        }
    }

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
            .accessibilityLabel(heightLabel)
            .accessibilityRemoveTraits(.isImage)
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
