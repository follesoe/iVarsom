import CoreLocation
import MapKit
import StoreKit
import SwiftUI

struct RegionList: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @Bindable var vm: RegionBrowserModel
    @Binding var browser: AdaptiveBrowserState
    @Binding var cameraPosition: MapCameraPosition
    @State private var widgetRefreshID: UUID?

    var reviewPromptService = ReviewPromptService()

    let rowInsets = EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 14)

    var body: some View {
        NavigationSplitView {
            VStack {
                if vm.state.phase == .loading && vm.regions.isEmpty {
                    Spacer()
                    ProgressView()
                    Text("Loading Regions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    Spacer()
                } else {
                    List(selection: listSelection) {
                        localWarningsSection
                        if !vm.favoriteRegions.isEmpty {
                            favoritesSection
                        }
                        if Locale.current.identifier.starts(with: "sv") {
                            swedenSection
                            norwaySection
                        } else {
                            norwaySection
                            swedenSection
                        }
                        // Scrolling with the list keeps every row reachable in short
                        // windows, such as iPhone Duo's outer display in landscape.
                        sourceAttribution
                            .listRowBackground(Color.clear)
                    }
                    .navigationTitle("Regions")
                    .searchable(text: $vm.searchTerm)
                    .listStyle(.insetGrouped)
                }
            }
        } detail: {
            if sizeClass == .regular {
                Group {
                    if !browser.detailShowsMap(hasSelection: vm.selectedRegion != nil) {
                        selectedRegionDetail
                            .toolbar {
                                ToolbarItem(placement: .navigation) {
                                    Button {
                                        vm.selectedRegionID = nil
                                        browser.returnToMap()
                                    } label: {
                                        Label("Map", systemImage: "map")
                                    }
                                }
                            }
                            .transition(.opacity)
                    } else {
                        AvalancheMapView(
                            regions: vm.allRegions, searchTerm: vm.searchTerm,
                            locate: locate,
                            onRegionSelected: { region in
                                // A sheet beside the map where supported; otherwise
                                // the forecast replaces the map in this column.
                                vm.selectedRegionID = region.id
                                browser.showMapDetail(isRegular: true)
                            },
                            cameraPosition: $cameraPosition
                        )
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: vm.selectedRegionID)
            } else {
                selectedRegionDetail
            }
        }
        .refreshable {
            await vm.loadRegions()
            await vm.detail.load(from: WarningDateRange.defaultDaysBefore, to: WarningDateRange.defaultDaysAfter)
            guard !Task.isCancelled else { return }
            widgetRefreshID = UUID()
        }
        .task(id: widgetRefreshID) {
            guard let request = widgetRefreshID else { return }
            await WidgetForecastRefresher.refresh(forceRefresh: true)
            if widgetRefreshID == request { widgetRefreshID = nil }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase == .background {
                reviewPromptService.recordSession()
            }
        }
        .onChange(of: vm.detail.state.phase) { _, newState in
            if newState == .loaded {
                let service = reviewPromptService
                if vm.detail.state.value?.source == .network, let id = vm.selectedRegionID {
                    service.recordRegionView(regionId: id)
                }
                if service.shouldPrompt(
                    favoriteCount: vm.favorites.ids.count,
                    locationAuthorized: vm.location.isAuthorized
                ) {
                    service.recordPrompt()
                    requestReview()
                }
            }
        }
    }

    private var sourceAttribution: some View {
        Text("Data from The Norwegian Avalanche Warning Service and Swedish Environmental Protection Agency.")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private var localWarningsSection: some View {
        Section {
            if let localRegion = vm.location.region {
                NavigationLink(value: localRegion.id) {
                    RegionRow(region: localRegion)
                }
                .speechLocale(for: localRegion.Id)
                .listRowInsets(rowInsets)
            } else {
                UseLocationRow(
                    title: locationActionTitle,
                    systemImage: vm.location.authorizationStatus == .denied ? "gear" : "location",
                    isRefreshing: vm.location.isRefreshing
                ) {
                    if vm.location.authorizationStatus == .denied {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } else {
                        Task { await vm.location.refresh(regions: vm.allRegions, requestPermission: true) }
                    }
                }
                .disabled(vm.location.authorizationStatus == .restricted)
            }
        } header: {
            Text("Local warnings")
        } footer: {
            if vm.location.region == nil {
                Text(locationExplanation)
            }
        }
    }

    private var locationActionTitle: LocalizedStringKey {
        if vm.location.isRefreshing { return "Finding location…" }
        switch vm.location.authorizationStatus {
        case .denied: return "Open Settings"
        case .restricted: return "Location unavailable"
        default: return "Use current location"
        }
    }

    private var locationExplanation: LocalizedStringKey {
        switch vm.location.authorizationStatus {
        case .denied: return "Location access is off. You can enable it in Settings."
        case .restricted: return "Location access is restricted on this device."
        case .authorizedAlways, .authorizedWhenInUse:
            return vm.location.isRefreshing
                ? "Show forecasts for the nearest region." : "Could not determine your current location."
        default: return "Show forecasts for the nearest region."
        }
    }
    private var selectedRegionDetail: some View {
        RegionDetailContainer(
            region: vm.selectedRegion, detail: vm.detail,
            isFavorite: vm.isSelectedRegionFavorite,
            showsActions: true, toggleFavorite: vm.toggleSelectedRegionFavorite)
    }

    /// Choosing a row shows its forecast in the detail column, replacing a
    /// forecast presented over the map.
    private var listSelection: Binding<Int?> {
        Binding(
            get: { vm.selectedRegionID },
            set: { id in
                vm.selectedRegionID = id
                if id != nil { browser.selectFromList() }
            })
    }

    private func locate() async -> Location2D? {
        if let coordinate = vm.location.coordinate { return coordinate }
        await vm.location.refresh(regions: vm.allRegions, requestPermission: true)
        return vm.location.coordinate
    }

    private var favoritesSection: some View {
        Section(header: Text("Favorites")) {
            ForEach(vm.favoriteRegions) { region in
                NavigationLink(value: region.id) {
                    RegionRow(region: region)
                }
                .speechLocale(for: region.Id)
                .listRowInsets(rowInsets)
            }
        }
    }

    private var norwaySection: some View {
        Section(header: Text("Norway")) {
            ForEach(vm.filteredRegions.filter { !vm.favorites.ids.contains($0.id) }) { region in
                NavigationLink(value: region.id) {
                    RegionRow(region: region)
                }
                .speechLocale(for: region.Id)
                .listRowInsets(rowInsets)
            }
        }
    }

    private var swedenSection: some View {
        Section(header: Text("Sweden")) {
            ForEach(vm.filteredSwedenRegions.filter { !vm.favorites.ids.contains($0.id) }) { region in
                NavigationLink(value: region.id) {
                    RegionRow(region: region)
                }
                .speechLocale(for: region.Id)
                .listRowInsets(rowInsets)
            }
        }
    }
}

#if DEBUG
    #Preview("Region List Empty") {
        @Previewable @State var camera = AvalancheMapView.overviewPosition
        @Previewable @State var browser = AdaptiveBrowserState()
        let vm = PreviewModels.browser(regions: [])
        RegionList(vm: vm, browser: $browser, cameraPosition: $camera, reviewPromptService: PreviewModels.reviewPrompt())
            .task { await vm.refreshOnActivation() }
    }

    #Preview("Region List Dark") {
        @Previewable @State var camera = AvalancheMapView.overviewPosition
        @Previewable @State var browser = AdaptiveBrowserState()
        let vm = PreviewModels.browser()
        RegionList(vm: vm, browser: $browser, cameraPosition: $camera, reviewPromptService: PreviewModels.reviewPrompt())
            .task { await vm.refreshOnActivation() }
            .preferredColorScheme(.dark)
    }

    #Preview("Region List Norwegian") {
        @Previewable @State var camera = AvalancheMapView.overviewPosition
        @Previewable @State var browser = AdaptiveBrowserState()
        let vm = PreviewModels.browser()
        RegionList(vm: vm, browser: $browser, cameraPosition: $camera, reviewPromptService: PreviewModels.reviewPrompt())
            .task { await vm.refreshOnActivation() }
            .environment(\.locale, Locale(identifier: "nb"))
    }
#endif
