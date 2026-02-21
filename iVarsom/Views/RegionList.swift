import SwiftUI
import CoreLocation
import CoreLocationUI
import MapKit
import WidgetKit

struct RegionList<ViewModelType: RegionListViewModelProtocol>: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Bindable var vm: ViewModelType
    @State private var navigatedRegion: RegionSummary?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 65, longitude: 14),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
        )
    )

    let rowInsets = EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 14)

    var body: some View {
        NavigationSplitView {
            VStack {
                List(selection: $vm.selectedRegion) {
                    Section(header: Text("Local Warnings")) {
                        if let localRegion = vm.localRegion {
                            NavigationLink(value: localRegion) {
                                RegionRow(region: localRegion)
                            }.listRowInsets(rowInsets)
                        }
                        else if (!vm.locationIsAuthorized) {
                            UseLocationRow(updateLocationHandler: {
                                Task {
                                    await vm.updateLocation()
                                }
                            }).listRowInsets(rowInsets)
                        }
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
                    if let region = vm.selectedRegion {
                        if sizeClass == .regular {
                            navigatedRegion = region
                        }
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
                NavigationStack {
                    AvalancheMapView<ViewModelType>(
                        vm: vm,
                        onRegionSelected: { region in
                            vm.selectedRegion = region
                        },
                        cameraPosition: $cameraPosition
                    )
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .navigationDestination(item: $navigatedRegion) { _ in
                        RegionDetailContainer<ViewModelType>(vm: vm)
                    }
                }
            } else {
                RegionDetailContainer<ViewModelType>(vm: vm)
            }
        }
        .onChange(of: navigatedRegion) {
            if navigatedRegion == nil && sizeClass == .regular {
                vm.selectedRegion = nil
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
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
                        )
                    )
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
    private var norwaySection: some View {
        Section(header: Text("Norway")) {
            ForEach(vm.filteredRegions) { region in
                NavigationLink(value: region) {
                    RegionRow(region: region)
                }.listRowInsets(rowInsets)
            }
        }
    }

    private var swedenSection: some View {
        Section(header: Text("Sweden")) {
            ForEach(vm.filteredSwedenRegions) { region in
                NavigationLink(value: region) {
                    RegionRow(region: region)
                }.listRowInsets(rowInsets)
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
