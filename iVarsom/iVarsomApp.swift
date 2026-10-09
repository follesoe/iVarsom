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
    @State private var isMapDetailPresented = false
    @State private var cameraPosition: MapCameraPosition = AvalancheMapView.overviewPosition

    var body: some View {
        Group {
            if sizeClass == .regular {
                RegionList(vm: vm)
            } else {
                TabView {
                    Tab("Regions", systemImage: "list.bullet") {
                        RegionList(vm: vm)
                    }
                    Tab("Map", systemImage: "map") {
                        iPhoneMapTab
                    }
                }
            }
        }
        .task(id: scenePhase == .active ? vm.selectedRegionID : nil) {
            guard scenePhase == .active else { return }
            await vm.detail.load()
        }
        .onOpenURL { url in
            let regionId = UrlUtils.extractParam(url: url, name: "id")
            if let regionId = regionId {
                Task {
                    await vm.selectRegion(id: regionId)
                }
            }
        }
    }

    private func locate() async -> Location2D? {
        if let coordinate = vm.location.coordinate { return coordinate }
        await vm.location.refresh(regions: vm.allRegions, requestPermission: true)
        return vm.location.coordinate
    }

    private var iPhoneMapTab: some View {
        NavigationStack {
            AvalancheMapView(
                regions: vm.allRegions, searchTerm: vm.searchTerm,
                locate: locate,
                onRegionSelected: { region in
                    vm.selectedRegionID = region.id
                    isMapDetailPresented = true
                },
                cameraPosition: $cameraPosition
            )
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $isMapDetailPresented) {
            NavigationStack {
                RegionDetailContainer(region: vm.selectedRegion, detail: vm.detail)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                isMapDetailPresented = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            await vm.location.refresh(regions: vm.allRegions, requestPermission: true)
            if let location = vm.location.coordinate {
                withAnimation {
                    cameraPosition = AvalancheMapView.userPosition(location)
                }
            }
        }
    }
}
