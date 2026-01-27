import SwiftUI

struct UseLocationRow: View {
    var updateLocationHandler: () -> ()

    var body: some View {
        VStack(alignment: .center) {
            Button(action: updateLocationHandler) {
                HStack {
                    Spacer()
                    Label("Use current location", systemImage: "location.circle")
                        .labelStyle(.titleAndIcon)
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

#Preview("Use Location Row") {
    return UseLocationRow() {}
}
