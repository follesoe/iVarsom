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
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 65, longitude: 14),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
        )
    )

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
                    Tab(role: .search) {
                        NavigationStack {
                            List {
                                ForEach(vm.filteredRegions) { region in
                                    NavigationLink(value: region) {
                                        RegionRow(region: region)
                                    }
                                }
                                ForEach(vm.filteredSwedenRegions) { region in
                                    NavigationLink(value: region) {
                                        RegionRow(region: region)
                                    }
                                }
                            }
                            .navigationTitle("Search")
                            .navigationDestination(for: RegionSummary.self) { region in
                                RegionDetailContainer<RegionListViewModel>(vm: vm)
                                    .onAppear {
                                        vm.selectedRegion = region
                                        Task {
                                            await vm.loadWarnings(from: WarningDateRange.defaultDaysBefore, to: WarningDateRange.defaultDaysAfter)
                                        }
                                    }
                            }
                        }
                        .searchable(text: $vm.searchTerm)
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
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
                        )
                    )
                }
            }
        }
    }
}
