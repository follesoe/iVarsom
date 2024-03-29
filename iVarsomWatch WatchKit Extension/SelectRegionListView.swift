import SwiftUI

struct SelectRegionListView<ViewModelType: RegionListViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: ViewModelType

    var body: some View {
        List {
            ForEach(RegionOption.allOptions) { option in
                Text(option.name)
                    .onTapGesture {
                        Task {
                            print(option.name)
                            if (option.id == RegionOption.currentPositionOption.id) {
                                await vm.updateLocation()
                            }
                            
                            vm.addFavorite(id: option.id)
                            dismiss()
                        }
                    }
            }
        }
    }
}

#Preview("Select Region List View") {
    return SelectRegionListView<RegionListViewModel>()
}
