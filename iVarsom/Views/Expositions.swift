import SwiftUI
import Foundation

struct Expositions: View {
    let sectors: [Bool]
    
    let headings = ["N", "Ø", "S", "V"]
    
    var body: some View {
        let strokeColor = Color("LightStroke")
        
        Canvas { context, size in
            context.translateBy(x: size.width * 0.5, y: size.height * 0.5)
            var pieContext = context
            pieContext.rotate(by: .degrees(-90))
            let radius = min(size.width, size.height) * 0.42
            var startAngle = Angle(degrees: -22.5)
            for sector in sectors {
                let angle = Angle(degrees: 45)
                let endAngle = startAngle + angle
                let path = Path { p in
                    p.move(to: .zero)
                    p.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    p.closeSubpath()
                }
                
                pieContext.fill(path, with: .color(Color(sector ? "DangerFill" : "NoDangerFill")))
                pieContext.stroke(path, with: .color(strokeColor), lineWidth: 1)
                startAngle = endAngle
            }
            
            pieContext.rotate(by: .degrees(90))
            
            for heading in headings {
                let headingRadius = radius / 5
                let path = Path { p in
                    p.addEllipse(in: CGRect(
                        x: -headingRadius,
                        y: -(size.height / 2) + 2,
                        width: headingRadius * 2,
                        height: headingRadius * 2))
                }
                pieContext.fill(path, with: .color(.white))
                pieContext.stroke(path, with: .color(strokeColor), lineWidth: 1)
                
                pieContext.draw(
                    Text(heading)
                        .font(.system(size: headingRadius * 1.4))
                        .foregroundStyle(.black),
                    at: CGPoint(x: 0, y: -(size.height / 2) + headingRadius * 1.05))

                pieContext.rotate(by: .degrees(90))
            }
            
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct Expositions_Previews: PreviewProvider {
    static var previews: some View {
        Expositions(sectors: [
            true, true, true, false, false, false, false, false
        ])
    }
}
