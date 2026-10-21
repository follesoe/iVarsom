import SwiftUI

struct ExposedHeightArrow: View {
    let exposedHeight1: Int
    let exposedHeight2: Int
    let exposedHeightFill: Int
    let fontSize: CGFloat

    private var heightDescription: String {
        let h1 = String(exposedHeight1)
        let h2 = String(exposedHeight2)
        switch exposedHeightFill {
        case 1: return String(localized: "Above \(h1) meters")
        case 2: return String(localized: "Below \(h1) meters")
        case 3: return String(localized: "Above \(h1) meters") + ", " + String(localized: "Below \(h2) meters")
        case 4: return String(localized: "Between \(h2) and \(h1) meters")
        default: return String(localized: "Above \(h1) meters")
        }
    }

    /// Arrows shown above and below the height. Unknown fill values fall back
    /// to "above", matching ExposedHeight and the accessibility label.
    private var arrows: (above: String?, below: String?) {
        switch exposedHeightFill {
        case 2: (nil, "arrow.down")
        case 3: ("arrow.up", "arrow.down")
        case 4: ("arrow.down", "arrow.up")
        default: ("arrow.up", nil)
        }
    }

    var body: some View {
        let heightText = exposedHeight1 == exposedHeight2 ?
            String(exposedHeight1) :
            "\(String(exposedHeight1))-\(String(exposedHeight2))"

        VStack {
            if let above = arrows.above {
                arrow(above)
            }

            Text(heightText)
                .font(.system(size: 13))
                .bold()
                #if os(watchOS)
                .shadow(color: .black, radius: 3)
                #endif

            if let below = arrows.below {
                arrow(below)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heightDescription)
    }

    /// Both arrows use the same size so the up and down arrows always match.
    private func arrow(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: fontSize))
            .bold()
            .foregroundColor(Color("DangerFill"))
            #if os(watchOS)
            .shadow(color: .black, radius: 3)
            #endif
    }
}

#Preview {
    ExposedHeightArrow(
        exposedHeight1: 600,
        exposedHeight2: 600,
        exposedHeightFill: 1,
        fontSize: 16)
}

#Preview {
    ExposedHeightArrow(
        exposedHeight1: 600,
        exposedHeight2: 600,
        exposedHeightFill: 2,
        fontSize: 16)
}

#Preview {
    ExposedHeightArrow(
        exposedHeight1: 600,
        exposedHeight2: 600,
        exposedHeightFill: 3,
        fontSize: 16)
}

#Preview {
    ExposedHeightArrow(
        exposedHeight1: 200,
        exposedHeight2: 600,
        exposedHeightFill: 4,
        fontSize: 16)
}
