import SwiftUI
import Foundation

struct Expositions: View {
    let sectors: [Bool]
        
    var body: some View {
        let nSectors = sectors.count
        let sectorDeg = 360.0 / Double(nSectors)
        let halfSectorDeg = sectorDeg / 2.0
        let lineWidth = 1.0
        let doubleLineWidth = lineWidth * 2.0
        let strokeColor = Color("LightStroke")
        
        Canvas { context, size in
            context.translateBy(x: size.width * 0.5, y: size.height * 0.5)
            
            var pieContext = context
            pieContext.rotate(by: .degrees(-90))
            
            let radius = min(size.width, size.height) * 0.41
            var startAngle = Angle(degrees: -halfSectorDeg)
            
            for sector in sectors {
                let angle = Angle(degrees: sectorDeg)
                let endAngle = startAngle + angle
                let path = Path { p in
                    p.move(to: .zero)
                    p.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    p.closeSubpath()
                }
                
                pieContext.fill(path, with: .color(Color(sector ? "DangerFill" : "NoDangerFill")))
                pieContext.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)
                startAngle = endAngle
            }
            
            pieContext.rotate(by: .degrees(90))
        
            let headingRadius = radius / 4
            let elipseRect = CGRect(
                x: -headingRadius,
                y: -(size.height / 2) + 2,
                width: headingRadius * 2,
                height: headingRadius * 2)
            
            let path = Path { p in
                p.addEllipse(in: elipseRect)
            }
            pieContext.fill(path, with: .color(.white))
            pieContext.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)
                        
            let resolvedN = context.resolve(
                Text("N")
                    .font(.system(size: headingRadius * 1.5))
                    .bold()
                    .foregroundStyle(.black)
            )
            
            let sizeN = resolvedN.measure(in: elipseRect.size)
            
            pieContext.draw(
                resolvedN,
                at: CGPoint(
                    x: elipseRect.midX,
                    y: elipseRect.midY - (sizeN.height / elipseRect.height)), anchor: .center)

            pieContext.rotate(by: .degrees(90))
            
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview("Default view") {
    Expositions(sectors: [
        true, true, true, false, false, false, false, false
    ])
}

#Preview("Small view") {
    Expositions(sectors: [
        true, true, true, false, false, false, false, false
    ]).frame(width: 64, height: 64)
}
