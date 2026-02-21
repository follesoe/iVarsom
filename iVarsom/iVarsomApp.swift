import SwiftUI

@main
struct iVarsomApp: App {
    @State var vm = RegionListViewModel(
        client: VarsomApiClient(),
        locationManager: LocationManager())

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Regions", systemImage: "list.bullet") {
                    RegionList<RegionListViewModel>(vm: vm)
                }
                Tab("Map", systemImage: "map") {
                    AvalancheMapView<RegionListViewModel>(vm: vm)
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
            .onOpenURL { url in
                let regionId = UrlUtils.extractParam(url: url, name: "id")
                if let regionId = regionId {
                    Task {
                        await vm.selectRegionById(regionId: regionId)
                    }
                }
            }
        }
    }
}
