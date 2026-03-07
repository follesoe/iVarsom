import SwiftUI

#if os(iOS)
private struct SharePreviewData: Identifiable {
    let id = UUID()
    let image: UIImage
    let filename: String
}
#endif

struct RegionDetailContainer<ViewModelType: RegionListViewModelProtocol>: View {
    @Bindable var vm: ViewModelType
    #if os(iOS)
    @State private var sharePreview: SharePreviewData? = nil
    #endif

    private var isFavorite: Bool {
        guard let selectedRegion = vm.selectedRegion else { return false }
        return vm.favoriteRegionIds.contains(selectedRegion.Id)
    }

    var body: some View {
        Group {
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
        #if os(iOS)
        .sheet(item: $sharePreview) { preview in
            NavigationStack {
                ScrollView {
                    Image(uiImage: preview.image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(NSLocalizedString("Share preview", comment: "Title for share preview sheet"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            sharePreview = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            ActivityViewPresenter.present(image: preview.image, filename: preview.filename)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        #endif
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
                Label(NSLocalizedString("Share with avalanche problems", comment: "Share menu option including avalanche problems"), systemImage: "square.and.arrow.up")
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
            sharePreview = SharePreviewData(image: image, filename: "\(name)-\(date).png")
        }
    }
    #endif
}
