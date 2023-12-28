import SwiftUI

struct RegionListView<ViewModelType: RegionListViewModelProtocol>: View {
    @StateObject var vm: ViewModelType
    @State private var showAddRegion = false
    
    // Load warnings from yesterday
    let fromDays = -1
    
    // ... and two days ahead
    let toDays = 2

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
                    selectedWarning: vm.selectedWarning,
                    warnings: $vm.warnings)
                .onAppear() {
                    vm.warnings.removeAll()
                    Task {
                        await vm.loadWarnings(from: fromDays, to: toDays)
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
        .onOpenURL { url in
            let regionId = UrlUtils.extractParam(url: url, name: "id")
            if let regionId = regionId {
                Task {
                    await vm.selectRegionById(regionId: regionId)
                }
            }
        }
    }
    
    func removeFavorite(at offsets: IndexSet) {
        let id = vm.favoriteRegions[offsets.first!].id
        vm.removeFavorite(id: id)
    }
}

#Preview("Region List") {
    return RegionListView(vm: DesignTimeRegionListViewModel(
        state: .loaded,
        locationIsAuthorized: false,
        filteredRegions: testARegions))
}
