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
                        let vm = RegionDetailViewModel(
                            client: client,
                            regionSummary: region)
                        NavigationLink() {
                            RegionDetailView(vm: vm)
                        } label: {
                            RegionWatchRow(warning: region.AvalancheWarningList[0])
                        }
                        .listRowInsets(EdgeInsets())
                        .cornerRadius(14)
                    }
                    .onDelete(perform: removeFavorite)
                    NavigationLink(destination: SelectRegionListView<ViewModelType>()) {
                        HStack {
                            Spacer()
                            Text("Add Region")
                            Spacer()
                        }
                        .padding(
                            EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5)
                        )
                    }
                    DataSourceView()
                        
                }.listStyle(.carousel)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegionListView(vm: DesignTimeRegionListViewModel(
                state: .loaded,
                locationIsAuthorized: false,
                filteredRegions: testARegions))
        }
    }
}
