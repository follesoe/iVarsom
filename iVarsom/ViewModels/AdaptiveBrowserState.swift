import Foundation

/// Tabs shown in compact width: an iPhone, iPhone Duo's outer display, or a
/// narrow iPad window.
enum BrowserTab: String, Hashable, Sendable {
    case regions
    case map
}

/// Keeps people looking at the same content when a window changes between
/// compact and regular width, such as when iPhone Duo folds or unfolds.
///
/// Regular width shows the region list beside a detail column holding either
/// the map or a forecast chosen from the list. Compact width splits the same
/// content into tabs. A forecast chosen on the map appears in a sheet over the
/// map, in both widths where the system can place that sheet beside the map.
struct AdaptiveBrowserState: Equatable, Sendable {
    /// The compact tab, remembered while the window is regular width.
    var tab: BrowserTab = .regions
    /// A forecast chosen on the map is presented over the map.
    var isMapDetailPresented = false
    /// Whether regular width keeps a map forecast in a sheet beside the map.
    /// Without leading sheet placement (before iOS 27, or on the Mac), the
    /// forecast moves to the detail column instead.
    var keepsMapDetailInRegularWidth = AdaptiveBrowserState.supportsMapDetailSheetInRegularWidth

    static var supportsMapDetailSheetInRegularWidth: Bool {
        #if targetEnvironment(macCatalyst)
            return false
        #else
            if #available(iOS 27, *) { return true }
            return false
        #endif
    }

    /// Whether the regular-width detail column shows the map.
    func detailShowsMap(hasSelection: Bool) -> Bool {
        !hasSelection || isMapDetailPresented
    }

    /// Called when the window becomes regular width.
    ///
    /// - Returns: Whether to clear the region selection, so the detail column
    ///   shows the map that filled the screen instead of an earlier forecast.
    mutating func expand() -> Bool {
        if isMapDetailPresented {
            if !keepsMapDetailInRegularWidth { isMapDetailPresented = false }
            return false
        }
        return tab == .map
    }

    /// Called when the window becomes compact width.
    mutating func collapse(hasSelection: Bool) {
        if isMapDetailPresented {
            tab = .map  // Keep the forecast over the map.
        } else if hasSelection {
            tab = .regions  // A forecast in the detail column continues full screen.
        }
    }

    /// A region was chosen on the map.
    ///
    /// - Parameter isRegular: The current width. Returns whether the forecast
    ///   is presented over the map rather than in the detail column.
    @discardableResult
    mutating func showMapDetail(isRegular: Bool) -> Bool {
        tab = .map
        isMapDetailPresented = !isRegular || keepsMapDetailInRegularWidth
        return isMapDetailPresented
    }

    /// The person dismissed the forecast over the map. The caller clears the
    /// selection, so the map stays in view.
    mutating func dismissMapDetail() {
        isMapDetailPresented = false
    }

    /// A region was chosen in the list, which shows its forecast in the
    /// detail column (regular) or the Regions tab (compact).
    mutating func selectFromList() {
        tab = .regions
        isMapDetailPresented = false
    }

    /// The detail column switched back to the map in regular width.
    mutating func returnToMap() {
        tab = .map
    }

    /// Deep links, widgets and Shortcuts open the forecast in the Regions tab.
    mutating func openForecast() {
        tab = .regions
        isMapDetailPresented = false
    }
}
