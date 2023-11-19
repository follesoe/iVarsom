import SwiftUI

struct ExposedHeightArrow: View {
    let exposedHeight1: Int
    let exposedHeight2: Int
    let exposedHeightFill: Int
    
    var body: some View {
        let imageOneName = switch exposedHeightFill {
        case 1: "arrow.up"
        case 2: "arrow.down"
        case 3: "arrow.up"
        case 4: "arrow.down"
        default: "ExposedTop"
            
        }
        let imageTwoName = switch exposedHeightFill {
        case 1: "arrow.up"
        case 2: "arrow.down"
        case 3: "arrow.down"
        case 4: "arrow.up"
        default: "ExposedTop"
        }
        
        let heightText = exposedHeight1 == exposedHeight2 ?
            String(exposedHeight1) :
            "\(String(exposedHeight1))-\(String(exposedHeight2))"
        
        VStack {
            if (exposedHeightFill != 2) {
                Image(systemName: imageOneName)
                    .font(.system(size: 16))
                    .bold()
                    .foregroundColor(Color("DangerFill"))
                    .shadow(color: .black, radius: 3)
            }
                        
            Text(heightText).font(.system(size: 13)).bold()
                .shadow(color: .black, radius: 3)
            
            if (exposedHeightFill != 1) {
                Image(systemName: imageTwoName)
                    .font(.system(size: 16))
                    .bold()
                    .foregroundColor(Color("DangerFill"))
                    .shadow(color: .black, radius: 3)
            }
        }
    }
}

#Preview {
    ExposedHeightArrow(
        exposedHeight1: 600,
        exposedHeight2: 600,
        exposedHeightFill: 1)
}

#Preview {
    ExposedHeightArrow(
        exposedHeight1: 600,
        exposedHeight2: 600,
        exposedHeightFill: 2)
}

#Preview {
    ExposedHeightArrow(
        exposedHeight1: 600,
        exposedHeight2: 600,
        exposedHeightFill: 3)
}

#Preview {
    ExposedHeightArrow(
        exposedHeight1: 200,
        exposedHeight2: 600,
        exposedHeightFill: 4)
}
