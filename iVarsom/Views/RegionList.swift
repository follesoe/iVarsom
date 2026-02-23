import SwiftUI
import CoreLocation
import CoreLocationUI
import MapKit
import WidgetKit

struct RegionList<ViewModelType: RegionListViewModelProtocol>: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Bindable var vm: ViewModelType
    @State private var cameraPosition: MapCameraPosition = AvalancheMapView<ViewModelType>.overviewPosition

    let rowInsets = EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 14)

    var body: some View {
        NavigationSplitView {
            VStack {
                List(selection: $vm.selectedRegion) {
                    Section(header: Text("Local Warnings")) {
                        if let localRegion = vm.localRegion {
                            NavigationLink(value: localRegion) {
                                RegionRow(region: localRegion)
                            }
                            .speechLocale(for: localRegion.Id)
                            .listRowInsets(rowInsets)
                        }
                        else if (!vm.locationIsAuthorized) {
                            UseLocationRow(updateLocationHandler: {
                                Task {
                                    await vm.updateLocation()
                                }
                            }).listRowInsets(rowInsets)
                        }
                    }
                    if !vm.favoriteRegions.isEmpty {
                        favoritesSection
                    }
                    if Locale.current.identifier.starts(with: "sv") {
                        swedenSection
                        norwaySection
                    } else {
                        norwaySection
                        swedenSection
                    }
                }
                .navigationTitle("Regions")
                .searchable(text: $vm.searchTerm)
                .listStyle(.insetGrouped)
                .onChange(of: vm.selectedRegion) {
                    if vm.selectedRegion != nil {
                        Task {
                            await vm.loadWarnings(from: WarningDateRange.defaultDaysBefore, to: WarningDateRange.defaultDaysAfter)
                        }
                    }
                }
                Text("Data from The Norwegian Avalanche Warning Service and Swedish Environmental Protection Agency.")
                    .font(.caption2)
                    .padding()
            }
        } detail: {
            if sizeClass == .regular {
                Group {
                    if vm.selectedRegion != nil {
                        let detail = RegionDetailContainer<ViewModelType>(vm: vm)
                        detail
                            .toolbar {
                                ToolbarItem(placement: .navigation) {
                                    Button {
                                        vm.selectedRegion = nil
                                    } label: {
                                        Label("Map", systemImage: "map")
                                    }
                                }
                                ToolbarItem(placement: .primaryAction) {
                                    detail.favoriteButton
                                }
                                #if os(iOS)
                                ToolbarSpacer(.fixed, placement: .primaryAction)
                                ToolbarItem(placement: .primaryAction) {
                                    detail.shareButton
                                }
                                #endif
                            }
                            .transition(.opacity)
                    } else {
                        AvalancheMapView<ViewModelType>(
                            vm: vm,
                            onRegionSelected: { region in
                                vm.selectedRegion = region
                            },
                            cameraPosition: $cameraPosition
                        )
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: vm.selectedRegion)
            } else {
                let detail = RegionDetailContainer<ViewModelType>(vm: vm)
                detail
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            detail.favoriteButton
                        }
                        #if os(iOS)
                        ToolbarSpacer(.fixed, placement: .primaryAction)
                        ToolbarItem(placement: .primaryAction) {
                            detail.shareButton
                        }
                        #endif
                    }
            }
        }
        .refreshable {
            await vm.loadRegions()
        }
        .task {
            await vm.loadRegions()
            await vm.requestLocationForMap()
            if let location = vm.userLocation {
                withAnimation {
                    cameraPosition = AvalancheMapView<ViewModelType>.userPosition(location)
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase == .background {
                WidgetCenter.shared.reloadAllTimelines()
                Task {
                    if (vm.needsRefresh()) {
                        await vm.loadRegions()
                    }
                }
            }
        }
    }
    private var favoritesSection: some View {
        Section(header: Text("Favorites")) {
            ForEach(vm.favoriteRegions) { region in
                NavigationLink(value: region) {
                    RegionRow(region: region)
                }
                .speechLocale(for: region.Id)
                .listRowInsets(rowInsets)
            }
        }
    }

    private var norwaySection: some View {
        Section(header: Text("Norway")) {
            ForEach(vm.filteredRegions.filter { !vm.favoriteRegionIds.contains($0.id) }) { region in
                NavigationLink(value: region) {
                    RegionRow(region: region)
                }
                .speechLocale(for: region.Id)
                .listRowInsets(rowInsets)
            }
        }
    }

    private var swedenSection: some View {
        Section(header: Text("Sweden")) {
            ForEach(vm.filteredSwedenRegions.filter { !vm.favoriteRegionIds.contains($0.id) }) { region in
                NavigationLink(value: region) {
                    RegionRow(region: region)
                }
                .speechLocale(for: region.Id)
                .listRowInsets(rowInsets)
            }
        }
    }
}

#Preview("Region List Empty") {
    RegionList(vm: DesignTimeRegionListViewModel())
}

#Preview("Region List Dark") {
    RegionList(vm: DesignTimeRegionListViewModel(
        state: .loaded,
        locationIsAuthorized: false,
        filteredRegions: testARegions))
        .preferredColorScheme(.dark)
}

#Preview("Region List Dark Norwegian") {
    RegionList(vm: DesignTimeRegionListViewModel(
        state: .loaded,
        locationIsAuthorized: false,
        filteredRegions: testARegions))
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "no"))
}
