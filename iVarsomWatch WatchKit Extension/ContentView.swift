import SwiftUI

struct ContentView<ViewModelType: RegionListViewModelProtocol>: View {
    @StateObject var vm: ViewModelType
    let client = VarsomApiClient()

    var body: some View {
        VStack {
            List {
                ForEach(vm.filteredRegions) { region in
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
                NavigationLink(destination: SelectRegionListView()) {
                    Text("Add Region")
                        .padding()
                }
            }.listStyle(.carousel)
        }.navigationTitle("Skredvarsel")
        .task {
            await vm.loadRegions()
        }
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
