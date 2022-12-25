import SwiftUI
import CoreLocation
import CoreLocationUI

struct RegionList<ViewModelType: RegionListViewModelProtocol>: View {
    @StateObject var vm: ViewModelType
    let client = VarsomApiClient()

    let rowInsets = EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 14)
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Local Warnings")) {
                        if let localRegion = vm.localRegion {
                            NavigationLink() {
                                RegionDetail(
                                    vm: RegionDetailViewModel(
                                        client: client,
                                        regionSummary: localRegion,
                                        isLocalRegion: true))
                            } label: {
                                RegionRow(region: localRegion)
                                    .listRowInsets(rowInsets)
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
                            NavigationLink() {
                                RegionDetail(
                                    vm: RegionDetailViewModel(
                                        client: client,
                                        regionSummary: region,
                                        isLocalRegion: false))
                            } label: {
                                RegionRow(region: region)
                            }.listRowInsets(rowInsets)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $vm.searchTerm)
                .navigationTitle("Regions")
                Text("Data from the The Norwegian Avalanche Warning Service and www.varsom.no.")
                    .font(.caption2)
                    .padding()
            }
            Text("Select a region")
        }
        .refreshable {
            await vm.loadRegions()
        }
        .task {
            await vm.loadRegions()
        }
    }
}

struct RegionList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegionList(vm: DesignTimeRegionListViewModel())
            RegionList(vm: DesignTimeRegionListViewModel(
                state: .loaded,
                locationIsAuthorized: false,
                filteredRegions: testARegions))
                .preferredColorScheme(.dark)
            RegionList(vm: DesignTimeRegionListViewModel(
                state: .loaded,
                locationIsAuthorized: false,
                filteredRegions: testARegions))
                .preferredColorScheme(.dark)
                .environment(\.locale, Locale(identifier: "no"))
        }
    }
}
