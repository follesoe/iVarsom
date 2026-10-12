import SwiftUI

struct UseLocationRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var title: LocalizedStringKey = "Use current location"
    var systemImage = "location"
    var isRefreshing = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if dynamicTypeSize.isAccessibilitySize {
                    Text(title)
                } else {
                    Label(title, systemImage: systemImage)
                        .labelStyle(.titleAndIcon)
                }
                if isRefreshing {
                    Spacer()
                    ProgressView()
                        .accessibilityHidden(true)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .disabled(isRefreshing)
    }
}

#Preview("Use Location Row") {
    List {
        Section {
            UseLocationRow() {}
        } header: {
            Text("Local warnings")
        } footer: {
            Text("Show forecasts for the nearest region.")
        }
    }
}
