import SwiftUI

struct RegionListView<ViewModelType: RegionListViewModelProtocol>: View {
    enum Route: Hashable {
        case region(RegionSummary)
        case addRegion
    }
    
    @StateObject var vm: ViewModelType

    var body: some View {
        NavigationStack {
            VStack {
                if (vm.regionLoadState == .loading) {
                    VStack {
                        ProgressView()
                        Text("Loading Regions")
                            .font(.caption2)
                    }
                } else if (vm.regionLoadState == .failed) {
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
                            NavigationLink(value: Route.region(region)) {
                                RegionWatchRow(warning: region.AvalancheWarningList[0], isLocalRegion: isLocalRegion)
                            }
                            .listRowInsets(EdgeInsets(top: -0.1, leading: 0, bottom: -0.1, trailing: 0))
                            .listRowBackground(Color.clear)
                            .cornerRadius(20)
                        }
                        .onDelete(perform: removeFavorite)
                        NavigationLink(value: Route.addRegion) {
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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case let .region(region):
                    RegionDetailView(
                        loadingState: vm.warningLoadState,
                        selectedRegion: region,
                        selectedWarning: region.AvalancheWarningList[0],
                        warnings: $vm.warnings
                    )
                    .onAppear() {
                        vm.selectedRegion = region
                        vm.warnings.removeAll()
                        Task {
                            await vm.loadWarnings(from: -1, to: 1)
                        }
                    }
                case .addRegion:
                    SelectRegionListView<ViewModelType>()
                }
            }
            .task {
                if (vm.needsRefresh()) {
                    await vm.loadRegions()
                }
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
