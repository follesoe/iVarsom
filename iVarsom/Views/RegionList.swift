import CoreLocation
import MapKit
import StoreKit
import SwiftUI

struct RegionList: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @Bindable var vm: RegionBrowserModel
    @State private var cameraPosition: MapCameraPosition = AvalancheMapView.overviewPosition
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
                    List(selection: $vm.selectedRegionID) {
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
                        if dynamicTypeSize.isAccessibilitySize {
                            sourceAttribution
                                .listRowBackground(Color.clear)
                        }
                    }
                    .navigationTitle("Regions")
                    .searchable(text: $vm.searchTerm)
                    .listStyle(.insetGrouped)
                    if !dynamicTypeSize.isAccessibilitySize {
                        sourceAttribution.padding()
                    }
                }
            }
        } detail: {
            if sizeClass == .regular {
                Group {
                    if vm.selectedRegion != nil {
                        selectedRegionDetail
                            .toolbar {
                                ToolbarItem(placement: .navigation) {
                                    Button {
                                        vm.selectedRegionID = nil
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
                            onRegionSelected: { vm.selectedRegionID = $0.id },
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
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await vm.refreshOnActivation()
            if let location = vm.location.coordinate {
                withAnimation {
                    cameraPosition = AvalancheMapView.userPosition(location)
                }
            }
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
            isFavorite: vm.favorites.ids.contains(vm.selectedRegionID ?? 0),
            showsActions: true, toggleFavorite: toggleFavorite)
    }

    private func locate() async -> Location2D? {
        if let coordinate = vm.location.coordinate { return coordinate }
        await vm.location.refresh(regions: vm.allRegions, requestPermission: true)
        return vm.location.coordinate
    }

    private func toggleFavorite() {
        guard let id = vm.selectedRegionID else { return }
        if vm.favorites.ids.contains(id) { vm.favorites.removeFavorite(id) } else { vm.favorites.addFavorite(id) }
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
        RegionList(vm: PreviewModels.browser(regions: []), reviewPromptService: PreviewModels.reviewPrompt())
    }

    #Preview("Region List Dark") {
        RegionList(vm: PreviewModels.browser(), reviewPromptService: PreviewModels.reviewPrompt())
            .preferredColorScheme(.dark)
    }

    #Preview("Region List Norwegian") {
        RegionList(vm: PreviewModels.browser(), reviewPromptService: PreviewModels.reviewPrompt())
            .environment(\.locale, Locale(identifier: "nb"))
    }
#endif
