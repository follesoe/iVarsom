import SwiftUI

struct SelectRegionListView<ViewModelType: RegionListViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ViewModelType.self) var vm: ViewModelType

    var body: some View {
        List {
            Section("Norway") {
                ForEach(RegionOption.allOptions.filter { Country.from(regionId: $0.id) != .sweden }) { option in
                    Text(option.name)
                        .onTapGesture {
                            Task {
                                if (option.id == RegionOption.currentPositionOption.id) {
                                    await vm.updateLocation()
                                }

                                vm.addFavorite(id: option.id)
                                dismiss()
                            }
                        }
                }
            }
            Section("Sweden") {
                ForEach(RegionOption.swedenRegions) { option in
                    Text(option.name)
                        .onTapGesture {
                            Task {
                                vm.addFavorite(id: option.id)
                                dismiss()
                            }
                        }
                }
            }
        }
    }
}

#Preview("Select Region List View") {
    return SelectRegionListView<RegionListViewModel>()
}
