import SwiftUI

struct UseLocationRow: View {
    var updateLocationHandler: () -> ()
    
    var body: some View {
        VStack(alignment: .center) {
            Button(action: updateLocationHandler) {
                HStack {
                    Spacer()
                    Label("Use current location", systemImage: "location.circle")
                    Spacer()
                }
            }
            Text("Will enable location based warnings in Widgets")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 2)
        }
        
    }
}

struct UseLocationRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UseLocationRow() {}
            .previewLayout(.sizeThatFits)
            UseLocationRow() {}
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
        }
    }
}
