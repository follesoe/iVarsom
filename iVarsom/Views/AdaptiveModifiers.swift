import SwiftUI

// Presentation adjustments for resizable layouts and iPhone Duo. Each modifier
// falls back to the unmodified view on earlier systems. The iOS 27.1 APIs are
// not in the Mac Catalyst 27.0 SDK, so they are compiled for iOS only.

extension View {
    /// Keeps the bar of a sheet with a single Close button horizontal on iPhone
    /// Duo's outer display, leaving the sheet's full width for its content.
    @ViewBuilder
    func horizontalSheetBar() -> some View {
        #if os(iOS) && !targetEnvironment(macCatalyst)
            if #available(iOS 27.1, *) {
                toolbarVerticalBehavior(.disabled)
            } else {
                self
            }
        #else
            self
        #endif
    }

    /// Places a sheet presented over the map on the leading edge, keeping the map
    /// visible beside it. The system also keeps sheets clear of iPhone Duo's fold.
    @ViewBuilder
    func presentationPlacementBesideMap() -> some View {
        #if os(iOS)
            if #available(iOS 27, *) {
                presentationPlacement(.leading)
            } else {
                self
            }
        #else
            self
        #endif
    }
}
