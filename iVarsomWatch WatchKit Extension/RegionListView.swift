import SwiftUI

struct RegionListView<ViewModelType: RegionListViewModelProtocol>: View {
    @StateObject var vm: ViewModelType
    let client = VarsomApiClient()

    var body: some View {
        VStack {
            if (vm.state == .loading) {
                VStack {
                    ProgressView()
                    Text("Loading Regions")
                        .font(.caption2)
                }
            } else if (vm.state == .failed) {
                VStack {
                    Text("Error Loading Regions")
                        .font(.caption2)
                        .padding()
                    Button("Try Again") {
                        Task {
                            await vm.loadRegions()
                        }
                    }.padding()
                }
            } else {
                List {
                    ForEach(vm.favoriteRegions) { region in
                        let isLocalRegion = region.Id == vm.localRegion?.Id
                        let vm = RegionDetailViewModel(
                            client: client,
                            regionSummary: region,
                            isLocalRegion: isLocalRegion)
                        NavigationLink() {
                            RegionDetailView(vm: vm)
                        } label: {
                            RegionWatchRow(warning: region.AvalancheWarningList[0], isLocalRegion: isLocalRegion)
                        }
                        .listRowInsets(EdgeInsets(top: -0.1, leading: 0, bottom: -0.1, trailing: 0))
                        .listRowBackground(Color.clear)
                        .cornerRadius(20)
                    }
                    .onDelete(perform: removeFavorite)
                    NavigationLink(destination: SelectRegionListView<ViewModelType>()) {
                        HStack {
                            Spacer()
                            Text("Add Region")
                            Spacer()
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0))
                    DataSourceView()
                        
                }
                .listStyle(.carousel)
            }
        }
        .navigationTitle("Skredvarsel")
        .navigationBarTitleDisplayMode(.inline)
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
