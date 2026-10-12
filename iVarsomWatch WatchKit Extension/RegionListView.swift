import SwiftUI

struct RegionListView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var vm: RegionBrowserModel
    @State private var showAddRegion = false
    @State private var widgetRefreshID: UUID?

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
                if vm.state.phase == .loading {
                    VStack {
                        ProgressView()
                        Text("Loading Regions")
                            .font(.caption2)
                    }
                } else {
                    List(selection: $vm.selectedRegionID) {
                        if hasBothCountries {
                            Section("Norway") {
                                favoriteRows(for: norwayFavorites)
                            }
                            Section("Sweden") {
                                favoriteRows(for: swedenFavorites)
                            }
                        } else {
                            ForEach(vm.favoriteRegions) { region in
                                let isLocalRegion = region.Id == vm.location.region?.Id
                                NavigationLink(value: region.id) {
                                    if let warning = region.AvalancheWarningList.first {
                                        RegionWatchRow(warning: warning, isLocalRegion: isLocalRegion)
                                    } else {
                                        Text(region.Name)
                                    }
                                }
                                .speechLocale(for: region.Id)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .cornerRadius(20)
                            }
                            .onDelete(perform: removeFavorite)
                        }

                        Button {
                            showAddRegion = true
                        } label: {
                            Label("Add Region", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        NavigationLink {
                            AvalancheWatchMapView(
                                regions: vm.allRegions,
                                selectRegion: { vm.selectedRegionID = $0.id },
                                locate: {
                                    await vm.location.refresh(regions: vm.allRegions, requestPermission: true)
                                    return vm.location.coordinate
                                })
                        } label: {
                            HStack {
                                Spacer()
                                Label("Map", systemImage: "map")
                                Spacer()
                            }
                        }
                        DataSourceView(source: favoriteDataSource)
                    }
                    .listStyle(.carousel)
                }
            }
        } detail: {
            if let selectedRegion = vm.selectedRegion {
                RegionDetailView(
                    loadingState: vm.detail.state.phase,
                    selectedRegion: selectedRegion,
                    selectedWarning: vm.detail.selectedWarning,
                    warnings: vm.detail.warnings)
            } else {
                Text("No selected region")
            }
        }
        .sheet(
            isPresented: $showAddRegion,
            content: {
                SelectRegionListView { id in
                    if id == RegionOption.currentPositionOption.id {
                        await vm.location.refresh(regions: vm.allRegions, requestPermission: true)
                    }
                    vm.favorites.addFavorite(id)
                }
            }
        )
        .task(id: scenePhase == .active ? vm.selectedRegionID : nil) {
            guard scenePhase == .active else { return }
            await vm.detail.load(from: fromDays, to: toDays)
        }
        .refreshable {
            await vm.loadRegions()
            await vm.detail.load(from: fromDays, to: toDays)
            guard !Task.isCancelled else { return }
            widgetRefreshID = UUID()
        }
        .task(id: widgetRefreshID) {
            guard let request = widgetRefreshID else { return }
            await WidgetForecastRefresher.refresh(forceRefresh: true)
            if widgetRefreshID == request { widgetRefreshID = nil }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await vm.refreshOnActivation()
            await WidgetForecastRefresher.refresh()
        }
        .task(id: scenePhase == .active ? ForecastNavigation.shared.request?.id : nil) {
            guard scenePhase == .active, let request = ForecastNavigation.shared.claimRequest() else { return }
            defer {
                if Task.isCancelled { ForecastNavigation.shared.release(request) }
                else { ForecastNavigation.shared.finish(request) }
            }
            await vm.selectRegion(id: request.regionID)
        }
        .onOpenURL { url in
            let regionId = UrlUtils.extractParam(url: url, name: "id")
            if let regionId = regionId {
                Task {
                    await vm.selectRegion(id: regionId)
                }
            }
        }
    }

    private func favoriteRows(for regions: [RegionSummary]) -> some View {
        ForEach(regions) { region in
            let isLocalRegion = region.Id == vm.location.region?.Id
            NavigationLink(value: region.id) {
                if let warning = region.AvalancheWarningList.first {
                    RegionWatchRow(warning: warning, isLocalRegion: isLocalRegion)
                } else {
                    Text(region.Name)
                }
            }
            .speechLocale(for: region.Id)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .cornerRadius(20)
        }
    }

    func removeFavorite(at offsets: IndexSet) {
        let ids = offsets.compactMap { index in
            vm.favoriteRegions.indices.contains(index) ? vm.favoriteRegions[index].id : nil
        }
        for id in ids { vm.removeFavorite(id: id) }
    }
}

#if DEBUG
    #Preview("Region List") {
        RegionListView(vm: PreviewModels.browser())
    }
#endif
