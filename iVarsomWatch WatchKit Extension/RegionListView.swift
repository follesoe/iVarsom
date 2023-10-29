import SwiftUI

struct RegionListView<ViewModelType: RegionListViewModelProtocol>: View {
    @StateObject var vm: ViewModelType
    @State private var showAddRegion = false

    var body: some View {
        NavigationSplitView {
            VStack {
                if (vm.regionLoadState == .loading) {
                    VStack {
                        ProgressView()
                        Text("Loading Regions")
                            .font(.caption2)
                    }
                } else {
                    List(selection: $vm.selectedRegion) { 
                        ForEach(vm.favoriteRegions) { region in
                            let isLocalRegion = region.Id == vm.localRegion?.Id
                            NavigationLink(value: region) {
                                RegionWatchRow(warning: region.AvalancheWarningList[0], isLocalRegion: isLocalRegion)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .cornerRadius(20)
                        }
                        .onDelete(perform: removeFavorite)
                        
                        HStack {
                            Spacer()
                            Text("Add Region")
                            Spacer()
                        }.onTapGesture {
                            showAddRegion = true
                        }
                        DataSourceView()
                    }
                    .listStyle(.carousel)
                }
            }
        } detail: {
            if  let selectedRegion = vm.selectedRegion {
                RegionDetailView(
                    loadingState: vm.warningLoadState,
                    selectedRegion: selectedRegion,
                    selectedWarning: selectedRegion.AvalancheWarningList[0],
                    warnings: $vm.warnings)
                .onAppear() {
                    vm.warnings.removeAll()
                    Task {
                        await vm.loadWarnings(from: -1, to: 1)
                    }
                }
            } else {
                Text("No selected region")
            }
        }
        .sheet(isPresented: $showAddRegion, content: {
            SelectRegionListView<ViewModelType>()
        })
        .task {
           if (vm.needsRefresh()) {
               await vm.loadRegions()
           }
       }
    }
    
    func removeFavorite(at offsets: IndexSet) {
        let id = vm.favoriteRegions[offsets.first!].id
        vm.removeFavorite(id: id)
    }
}

struct RegionListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegionListView(vm: DesignTimeRegionListViewModel(
                    state: .loaded,
                    locationIsAuthorized: false,
                    filteredRegions: testARegions))
            .previewDisplayName("41 mm")
            .previewDevice("Apple Watch Series 8 (41mm)")
            
            RegionListView(vm: DesignTimeRegionListViewModel(
                    state: .loaded,
                    locationIsAuthorized: false,
                    filteredRegions: testARegions))
            .previewDisplayName("45 mm")
            .previewDevice("Apple Watch Series 8 (45mm)")
            
            RegionListView(vm: DesignTimeRegionListViewModel(
                    state: .loaded,
                    locationIsAuthorized: false,
                    filteredRegions: testARegions))
            .previewDisplayName("49 mm")
            .previewDevice("Apple Watch Ultra (49mm)")
        }
    }
}
