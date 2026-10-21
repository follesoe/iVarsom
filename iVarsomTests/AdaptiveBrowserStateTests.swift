import Testing

@testable import Skredvarsel

/// Folding and unfolding iPhone Duo switches between compact and regular width.
struct AdaptiveBrowserStateTests {
    private func makeState(tab: BrowserTab = .regions, keepsSheet: Bool = true) -> AdaptiveBrowserState {
        AdaptiveBrowserState(tab: tab, isMapDetailPresented: false, keepsMapDetailInRegularWidth: keepsSheet)
    }

    @Test func unfoldingFromMapShowsMapInsteadOfEarlierForecast() {
        var state = makeState(tab: .map)
        let clearsSelection = state.expand()
        #expect(clearsSelection)
        // Folding again with nothing selected returns to the map.
        state.collapse(hasSelection: false)
        #expect(state.tab == .map)
    }

    @Test func mapForecastStaysOverMapWhenUnfoldingAndFolding() {
        var state = makeState()
        let presentsSheet = state.showMapDetail(isRegular: false)
        #expect(presentsSheet)
        let clearsSelection = state.expand()
        #expect(!clearsSelection)
        #expect(state.isMapDetailPresented)
        #expect(state.detailShowsMap(hasSelection: true))
        state.collapse(hasSelection: true)
        #expect(state.tab == .map)
        #expect(state.isMapDetailPresented)
    }

    @Test(arguments: [true, false])
    func choosingOnRegularMapUsesSheetOnlyWhenPlacementIsSupported(keepsSheet: Bool) {
        var state = makeState(keepsSheet: keepsSheet)
        let presentsSheet = state.showMapDetail(isRegular: true)
        #expect(presentsSheet == keepsSheet)
        #expect(state.detailShowsMap(hasSelection: true) == keepsSheet)
        // Folding returns to the map either way: as a sheet over it, or (when
        // the forecast filled the detail column) the Regions tab.
        state.collapse(hasSelection: true)
        #expect(state.tab == (keepsSheet ? .map : .regions))
    }

    @Test func withoutSheetPlacementUnfoldingMovesMapForecastToDetailColumn() {
        var state = makeState(keepsSheet: false)
        state.showMapDetail(isRegular: false)
        let clearsSelection = state.expand()
        #expect(!clearsSelection)
        #expect(!state.isMapDetailPresented)
        #expect(!state.detailShowsMap(hasSelection: true))
        state.collapse(hasSelection: true)
        #expect(state.tab == .regions)
    }

    @Test func dismissingMapForecastReturnsToMap() {
        var state = makeState()
        state.showMapDetail(isRegular: true)
        state.dismissMapDetail()
        #expect(!state.isMapDetailPresented)
        #expect(state.detailShowsMap(hasSelection: false))
        state.collapse(hasSelection: false)
        #expect(state.tab == .map)
    }

    @Test func choosingFromListReplacesMapForecast() {
        var state = makeState()
        state.showMapDetail(isRegular: true)
        state.selectFromList()
        #expect(!state.isMapDetailPresented)
        #expect(!state.detailShowsMap(hasSelection: true))
        state.collapse(hasSelection: true)
        #expect(state.tab == .regions)
    }

    @Test func unfoldingFromRegionsKeepsSelection() {
        var state = makeState()
        let clearsSelection = state.expand()
        #expect(!clearsSelection)
        state.collapse(hasSelection: false)
        #expect(state.tab == .regions)
    }

    @Test func returningToMapInRegularWidthFoldsToMapTab() {
        var state = makeState()
        _ = state.expand()
        state.returnToMap()
        state.collapse(hasSelection: false)
        #expect(state.tab == .map)
    }

    @Test func openingForecastShowsRegionsTabWithoutSheet() {
        var state = makeState(tab: .map)
        state.showMapDetail(isRegular: false)
        state.openForecast()
        #expect(state.tab == .regions)
        #expect(!state.isMapDetailPresented)
    }
}
