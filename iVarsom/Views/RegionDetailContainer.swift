import SwiftUI

struct RegionDetailContainer: View {
    let region: RegionSummary?
    @Bindable var detail: WarningDetailModel
    var isFavorite = false
    var showsActions = false
    var toggleFavorite: () -> Void = {}
    @State private var sharePreview: ShareImage?

    var body: some View {
        Group {
            if let selectedRegion = region {
                if detail.state.phase == .loading {
                    VStack {
                        ProgressView()
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "Loading warnings for %@", comment: "Loading warnings message with region name"),
                                selectedRegion.Name))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if detail.state.phase == .failed {
                    VStack {
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "Error loading warnings for %@",
                                    comment: "Error message when loading warnings fails"), selectedRegion.Name))
                        Button(NSLocalizedString("Try Again", comment: "Button to retry loading data")) {
                            Task {
                                await detail.load(
                                    from: WarningDateRange.defaultDaysBefore, to: WarningDateRange.defaultDaysAfter)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if detail.state.phase == .loaded && detail.warnings.isEmpty {
                    Text("No warning available")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    RegionDetail(
                        selectedRegion: selectedRegion,
                        selectedWarningID: $detail.selectedWarningID,
                        warnings: detail.warnings
                    )
                }
            } else {
                Text("Select a region")
            }
        }
        .toolbar {
            if showsActions {
                if #available(iOS 27, *) {
                    // Favoriting is the frequent action; sharing overflows first
                    // when a narrow or vertical bar runs out of room.
                    ToolbarItem(placement: .primaryAction) { favoriteButton }
                        .visibilityPriority(.high)
                    ToolbarSpacer(.fixed, placement: .primaryAction)
                    ToolbarItem(placement: .primaryAction) { shareButton }
                        .visibilityPriority(.low)
                } else {
                    ToolbarItem(placement: .primaryAction) { favoriteButton }
                    ToolbarSpacer(.fixed, placement: .primaryAction)
                    ToolbarItem(placement: .primaryAction) { shareButton }
                }
            }
        }
        .sheet(item: $sharePreview) { SharePreviewView(item: $0) }
    }

    // Toolbar items carry a title as well as an icon: iPhone Duo shows icons in
    // vertical bars and titles in the overflow menu.
    var favoriteButton: some View {
        Button(action: toggleFavorite) {
            Label(
                isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: isFavorite ? "star.fill" : "star")
        }
    }

    #if os(iOS)
        var shareButton: some View {
            Menu {
                Button {
                    shareWarning(includeProblems: false)
                } label: {
                    Label(
                        NSLocalizedString("Share summary", comment: "Share menu option for summary only"),
                        systemImage: "square.and.arrow.up")
                }
                Button {
                    shareWarning(includeProblems: true)
                } label: {
                    Label(
                        NSLocalizedString(
                            "Share with avalanche problems", comment: "Share menu option including avalanche problems"),
                        systemImage: "square.and.arrow.up")
                }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }

        private func shareWarning(includeProblems: Bool) {
            guard let warning = detail.selectedWarning else { return }
            let view = ShareableWarningView(warning: warning, includeProblems: includeProblems)
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = ProposedViewSize(width: 390, height: nil)
            renderer.scale = 3
            if let image = renderer.uiImage {
                let date = warning.forecastDateIdentifier
                let name = warning.RegionName
                    .replacingOccurrences(of: " ", with: "-")
                    .lowercased()
                sharePreview = ShareImage(image: image, filename: "\(name)-\(date).png")
            }
        }
    #endif
}
