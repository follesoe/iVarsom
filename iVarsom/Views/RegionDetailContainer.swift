import SwiftUI

struct RegionDetailContainer<ViewModelType: RegionListViewModelProtocol>: View {
    @Bindable var vm: ViewModelType

    private var isFavorite: Bool {
        guard let selectedRegion = vm.selectedRegion else { return false }
        return vm.favoriteRegionIds.contains(selectedRegion.Id)
    }

    var body: some View {
        if let selectedRegion = vm.selectedRegion {
            if vm.warningLoadState == .loading {
                VStack {
                    ProgressView()
                    Text(String(format: NSLocalizedString("Loading warnings for %@", comment: "Loading warnings message with region name"), selectedRegion.Name))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.warningLoadState == .failed {
                VStack {
                    Text(String(format: NSLocalizedString("Error loading warnings for %@", comment: "Error message when loading warnings fails"), selectedRegion.Name))
                    Button(NSLocalizedString("Try Again", comment: "Button to retry loading data")) {
                        Task {
                            await vm.loadWarnings(from: WarningDateRange.defaultDaysBefore, to: WarningDateRange.defaultDaysAfter)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RegionDetail(
                    selectedRegion: $vm.selectedRegion,
                    selectedWarning: $vm.selectedWarning,
                    warnings: $vm.warnings
                )
            }
        } else {
            Text("Select a region")
        }
    }

    var favoriteButton: some View {
        Button {
            guard let selectedRegion = vm.selectedRegion else { return }
            if isFavorite {
                vm.removeFavorite(id: selectedRegion.Id)
            } else {
                vm.addFavorite(id: selectedRegion.Id)
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
        }
    }
}
