import SwiftUI

struct SelectRegionListView: View {
    @Environment(\.dismiss) private var dismiss
    var addFavorite: (Int) async -> Void

    var body: some View {
        List {
            Section("Norway") {
                options(RegionOption.allOptions.filter { Country.from(regionId: $0.id) != .sweden })
            }
            Section("Sweden") { options(RegionOption.swedenRegions) }
        }
    }

    private func options(_ values: [RegionOption]) -> some View {
        ForEach(values) { option in
            Button(option.name) {
                Task {
                    await addFavorite(option.id)
                    dismiss()
                }
            }
        }
    }
}

#Preview("Select Region List") {
    SelectRegionListView { _ in }
}
