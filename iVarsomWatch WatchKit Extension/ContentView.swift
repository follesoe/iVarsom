import SwiftUI

struct ContentView<ViewModelType: RegionListViewModelProtocol>: View {
    @StateObject var vm: ViewModelType
    let client = VarsomApiClient()

    var body: some View {
        VStack {
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
                    .padding()
                }
                Text("Data from the The Norwegian Avalanche Warning Service and www.varsom.no.")
                    .font(.system(size: 11))
                    .padding()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
            }.listStyle(.carousel)
        }
        .navigationTitle("Skredvarsel")
        .task {
            await vm.loadRegions()
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
            ContentView(vm: DesignTimeRegionListViewModel(
                state: .loaded,
                locationIsAuthorized: false,
                filteredRegions: testARegions))
        }
    }
}
