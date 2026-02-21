import SwiftUI
import WidgetKit

struct RegionListView<ViewModelType: RegionListViewModelProtocol>: View {
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var vm: ViewModelType
    @State private var showAddRegion = false

    // Load warnings from yesterday
    let fromDays = -1

    // ... and two days ahead
    let toDays = 2

    var norwayFavorites: [RegionSummary] {
        vm.favoriteRegions.filter { Country.from(regionId: $0.Id) == .norway }
    }

    var swedenFavorites: [RegionSummary] {
        vm.favoriteRegions.filter { Country.from(regionId: $0.Id) == .sweden }
    }

    var hasBothCountries: Bool {
        !norwayFavorites.isEmpty && !swedenFavorites.isEmpty
    }

    var favoriteDataSource: DataSourceType {
        if hasBothCountries { return .both }
        if !swedenFavorites.isEmpty { return .sweden }
        return .norway
    }

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
                        if hasBothCountries {
                            Section("Norway") {
                                favoriteRows(for: norwayFavorites)
                            }
                            Section("Sweden") {
                                favoriteRows(for: swedenFavorites)
                            }
                        } else {
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
                        }

                        HStack {
                            Spacer()
                            Text("Add Region")
                            Spacer()
                        }.onTapGesture {
                            showAddRegion = true
                        }
                        DataSourceView(source: favoriteDataSource)
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
        .onOpenURL { url in
            let regionId = UrlUtils.extractParam(url: url, name: "id")
            if let regionId = regionId {
                Task {
                    await vm.selectRegionById(regionId: regionId)
                }
            }
        }
    }

    private func favoriteRows(for regions: [RegionSummary]) -> some View {
        ForEach(regions) { region in
            let isLocalRegion = region.Id == vm.localRegion?.Id
            NavigationLink(value: region) {
                RegionWatchRow(warning: region.AvalancheWarningList[0], isLocalRegion: isLocalRegion)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .cornerRadius(20)
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
