import SwiftUI
import CoreLocation
import CoreLocationUI

struct RegionList<ViewModelType: RegionListViewModelProtocol>: View {
    @StateObject var vm: ViewModelType

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
                    Section(header: Text("A-Regions")) {
                        ForEach(vm.filteredRegions) { region in
                            NavigationLink(value: region) {
                                RegionRow(region: region)
                            }.listRowInsets(rowInsets)
                        }
                    }
                }
                .navigationTitle("Regions")
                .listStyle(.insetGrouped)
                .searchable(text: $vm.searchTerm)
                .onChange(of: vm.selectedRegion) {
                    if let region = vm.selectedRegion {
                        print("New selected region: \(region.Name)")
                        Task {
                            await vm.loadWarnings(from: -5, to: 2)
                        }
                    } else {
                        print("Selected region set to nil")
                    }
                }
                Text("Data from the The Norwegian Avalanche Warning Service and www.varsom.no.")
                    .font(.caption2)
                    .padding()
            }
        } detail: {
            if  vm.selectedRegion != nil {
                RegionDetail(
                    selectedRegion: $vm.selectedRegion,
                    selectedWarning: $vm.selectedWarning,
                    warnings: $vm.warnings
                )
            } else {
                Text("Select a region")
            }
        }
        .refreshable {
            await vm.loadRegions()
        }
        .task {
            await vm.loadRegions()
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
