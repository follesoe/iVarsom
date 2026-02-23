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

    #if os(iOS)
    var shareButton: some View {
        Menu {
            Button {
                shareWarning(includeProblems: false)
            } label: {
                Label(NSLocalizedString("Share summary", comment: "Share menu option for summary only"), systemImage: "square.and.arrow.up")
            }
            Button {
                shareWarning(includeProblems: true)
            } label: {
                Label(NSLocalizedString("Share with avalanche problems", comment: "Share menu option including avalanche problems"), systemImage: "square.and.arrow.up.fill")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }

    private func shareWarning(includeProblems: Bool) {
        guard let warning = vm.selectedWarning else { return }
        let view = ShareableWarningView(warning: warning, includeProblems: includeProblems)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: 390, height: nil)
        renderer.scale = 3
        if let image = renderer.uiImage {
            let date = warning.ValidFrom.formatted(.iso8601.year().month().day())
            let name = warning.RegionName
                .replacingOccurrences(of: " ", with: "-")
                .lowercased()
            ActivityViewPresenter.present(image: image, filename: "\(name)-\(date).png")
        }
    }
    #endif
}
