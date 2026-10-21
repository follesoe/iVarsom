import MapKit
import SwiftUI

@main
struct iVarsomApp: App {
    @State private var favorites: FavoritesService?

    init() {
        // Unit tests exercise injected services; their host must not start live
        // networking, location prompts or the user's iCloud/preferences store.
        let isUnitTestHost = ProcessInfo.processInfo.environment["SKREDVARSEL_UNIT_TESTS"] == "1"
        _favorites = State(initialValue: isUnitTestHost ? nil : FavoritesService())
    }

    var body: some Scene {
        WindowGroup {
            if let favorites {
                ContentView(favorites: favorites)
            } else {
                Color.clear
            }
        }
    }
}

private struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var vm: RegionBrowserModel

    init(favorites: FavoritesService) {
        _vm = State(initialValue: RegionBrowserModel(favorites: favorites))
    }
    @State private var browser = AdaptiveBrowserState()
    /// Shared by the compact Map tab and the regular-width detail map, so the
    /// map stays put when iPhone Duo folds or unfolds.
    @State private var cameraPosition: MapCameraPosition = AvalancheMapView.overviewPosition
    /// The map centers on the person's location once; afterwards it keeps the
    /// position they chose, across activations and folds.
    @State private var hasCenteredMap = false

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        // Folding or unfolding iPhone Duo switches between these layouts. State
        // that must survive the switch (selection, browser state, map camera and
        // the map's forecast sheet) lives here rather than in either layout.
        Group {
            if isRegular {
                RegionList(vm: vm, browser: $browser, cameraPosition: $cameraPosition)
            } else {
                TabView(selection: $browser.tab) {
                    Tab("Regions", systemImage: "list.bullet", value: BrowserTab.regions) {
                        RegionList(vm: vm, browser: $browser, cameraPosition: $cameraPosition)
                    }
                    Tab("Map", systemImage: "map", value: BrowserTab.map) {
                        compactMapTab
                    }
                }
            }
        }
        // Presented from the root so a forecast chosen on the map stays over the
        // map when iPhone Duo folds or unfolds.
        .sheet(isPresented: mapDetailPresentation) { mapDetailSheet }
        .onChange(of: isRegular) { _, isRegular in
            if isRegular {
                if browser.expand() { vm.selectedRegionID = nil }
            } else {
                browser.collapse(hasSelection: vm.selectedRegionID != nil)
            }
        }
        .task(id: scenePhase == .active ? vm.selectedRegionID : nil) {
            guard scenePhase == .active else { return }
            await vm.detail.load()
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await WidgetForecastRefresher.refresh()
        }
        // Runs on activation only, not when a fold rebuilds the layout.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await vm.refreshOnActivation()
            centerMapOnceOnLocation()
        }
        .task(id: scenePhase == .active ? ForecastNavigation.shared.request?.id : nil) {
            guard scenePhase == .active, let request = ForecastNavigation.shared.claimRequest() else { return }
            defer {
                if Task.isCancelled { ForecastNavigation.shared.release(request) }
                else { ForecastNavigation.shared.finish(request) }
            }
            await openRegion(request.regionID)
        }
        .onOpenURL { url in
            let regionId = UrlUtils.extractParam(url: url, name: "id")
            if let regionId = regionId {
                Task {
                    await openRegion(regionId)
                }
            }
        }
    }

    /// Only a person's dismissal clears the selection, returning to the map.
    /// Programmatic dismissals (choosing from the list, deep links) keep theirs.
    private var mapDetailPresentation: Binding<Bool> {
        Binding(
            get: { browser.isMapDetailPresented },
            set: { isPresented in
                if !isPresented { dismissMapDetail() }
            })
    }

    private func dismissMapDetail() {
        browser.dismissMapDetail()
        vm.selectedRegionID = nil
    }

    private func openRegion(_ id: Int) async {
        browser.openForecast()
        await vm.selectRegion(id: id)
    }

    /// Show My Location on either map. Centering on request uses up the
    /// automatic centering, so a later activation keeps the map where the
    /// person has since moved it.
    private func locate() async -> Location2D? {
        if vm.location.coordinate == nil {
            await vm.location.refresh(regions: vm.allRegions, requestPermission: true)
        }
        if vm.location.coordinate != nil { hasCenteredMap = true }
        return vm.location.coordinate
    }

    private func centerMapOnceOnLocation() {
        guard !hasCenteredMap, let location = vm.location.coordinate else { return }
        hasCenteredMap = true
        withAnimation {
            cameraPosition = AvalancheMapView.userPosition(location)
        }
    }

    private var mapDetailSheet: some View {
        NavigationStack {
            RegionDetailContainer(
                region: vm.selectedRegion, detail: vm.detail,
                isFavorite: vm.isSelectedRegionFavorite,
                showsActions: true, toggleFavorite: vm.toggleSelectedRegionFavorite
            )
            .toolbar {
                // Close is navigation, so it leads the bar (and tops a vertical
                // bar on iPhone Duo's outer display).
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismissMapDetail() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationPlacementBesideMap()
    }

    private var compactMapTab: some View {
        NavigationStack {
            AvalancheMapView(
                regions: vm.allRegions, searchTerm: vm.searchTerm,
                locate: locate,
                onRegionSelected: { region in
                    vm.selectedRegionID = region.id
                    browser.showMapDetail(isRegular: false)
                },
                cameraPosition: $cameraPosition
            )
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await vm.location.refresh(regions: vm.allRegions)
            centerMapOnceOnLocation()
        }
    }
}
