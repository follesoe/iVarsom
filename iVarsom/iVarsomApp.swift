import SwiftUI
import MapKit

@main
struct iVarsomApp: App {
    @State var vm = RegionListViewModel(
        client: VarsomApiClient(),
        locationManager: LocationManager())

    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
        }
    }
}

private struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Bindable var vm: RegionListViewModel
    @State private var sheetRegion: RegionSummary?
    @State private var cameraPosition: MapCameraPosition = AvalancheMapView<RegionListViewModel>.overviewPosition

    var body: some View {
        Group {
            if sizeClass == .regular {
                RegionList<RegionListViewModel>(vm: vm)
            } else {
                TabView {
                    Tab("Regions", systemImage: "list.bullet") {
                        RegionList<RegionListViewModel>(vm: vm)
                    }
                    Tab("Map", systemImage: "map") {
                        iPhoneMapTab
                    }
                }
            }
        }
        .onOpenURL { url in
            let regionId = UrlUtils.extractParam(url: url, name: "id")
            if let regionId = regionId {
                Task {
                    await vm.selectRegionById(regionId: regionId)
                }
            }
        }
    }

    private var iPhoneMapTab: some View {
        NavigationStack {
            AvalancheMapView<RegionListViewModel>(
                vm: vm,
                onRegionSelected: { region in
                    vm.selectedRegion = region
                    sheetRegion = region
                    Task {
                        await vm.loadWarnings(from: WarningDateRange.defaultDaysBefore, to: WarningDateRange.defaultDaysAfter)
                    }
                },
                cameraPosition: $cameraPosition
            )
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(item: $sheetRegion) { _ in
            NavigationStack {
                RegionDetailContainer<RegionListViewModel>(vm: vm)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                sheetRegion = nil
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
            await vm.requestLocationForMap()
            if let location = vm.userLocation {
                withAnimation {
                    cameraPosition = AvalancheMapView<RegionListViewModel>.userPosition(location)
                }
            }
        }
    }
}
