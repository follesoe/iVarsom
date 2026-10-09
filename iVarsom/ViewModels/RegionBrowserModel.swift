import Foundation
import Observation

@Observable
@MainActor
final class RegionBrowserModel {
    private(set) var state: LoadState<RegionCatalog> = .idle
    var searchTerm = ""
    var selectedRegionID: Int? {
        didSet { detail.selectRegion(selectedRegionID) }
    }
    let detail: WarningDetailModel
    let location: RegionLocationModel
    let favorites: FavoritesService
    private let repository: any WarningRepositoryProviding
    private let now: () -> Date
    @ObservationIgnored private var requestID = UUID()
    @ObservationIgnored private var lastRefresh: Date?

    init(
        repository: any WarningRepositoryProviding = WarningRepository(),
        locationManager: any LocationProviding = LocationManager(),
        favorites: FavoritesService = FavoritesService(),
        now: @escaping () -> Date = { Date.current }
    ) {
        self.repository = repository
        self.favorites = favorites
        self.now = now
        detail = WarningDetailModel(repository: repository, now: now)
        location = RegionLocationModel(manager: locationManager, repository: repository, now: now)
    }

    var regions: [RegionSummary] { state.value?.norway ?? [] }
    var swedenRegions: [RegionSummary] { state.value?.sweden ?? [] }
    var allRegions: [RegionSummary] { regions + swedenRegions }
    var selectedRegion: RegionSummary? {
        allRegions.first { $0.id == selectedRegionID }
            ?? (location.region?.id == selectedRegionID ? location.region : nil)
    }
    var filteredRegions: [RegionSummary] { regions.filter(matchesSearch) }
    var filteredSwedenRegions: [RegionSummary] { swedenRegions.filter(matchesSearch) }
    var favoriteRegions: [RegionSummary] {
        let usesLocalRegion = favorites.ids.contains(RegionOption.currentPositionOption.id)
        var result = (filteredRegions + filteredSwedenRegions).filter {
            favorites.ids.contains($0.id) && !(usesLocalRegion && $0.id == location.region?.id)
        }
        if usesLocalRegion, let localRegion = location.region, matchesSearch(localRegion) {
            result.insert(localRegion, at: 0)
        }
        return result
    }

    func removeFavorite(id: Int) {
        if favorites.ids.contains(id) {
            favorites.removeFavorite(id)
        } else if id == location.region?.id {
            favorites.removeFavorite(RegionOption.currentPositionOption.id)
        }
    }

    func needsRefresh() -> Bool {
        guard let lastRefresh else { return true }
        let date = now()
        return !Calendar.current.isDate(date, inSameDayAs: lastRefresh)
            || date.timeIntervalSince(lastRefresh) >= 4 * 60 * 60 || date < lastRefresh
    }

    func refreshOnActivation() async {
        if needsRefresh() {
            // Loading the catalog also refreshes the local region.
            await loadRegions()
        } else {
            // Location and permission can change while the catalog is still fresh.
            await location.refresh(regions: allRegions)
        }
    }

    func loadRegions() async {
        let request = UUID()
        requestID = request
        let previous = state.value
        state = .loading(previous: previous)
        defer {
            if requestID == request, state.phase == .loading {
                state = previous.map { .loaded($0) } ?? .idle
            }
        }
        do {
            let catalog = try await repository.loadRegions()
            try Task.checkCancellation()
            guard requestID == request else { return }
            state = .loaded(catalog)
            if catalog.isEntirelyFresh { lastRefresh = now() }
            await location.refresh(regions: catalog.allRegions)
        } catch {
            guard !Task.isCancelled, !(error is CancellationError), requestID == request else { return }
            state = .failed
        }
    }

    func selectRegion(id: Int) async {
        if allRegions.isEmpty { await loadRegions() }
        guard !Task.isCancelled else { return }
        if allRegions.contains(where: { $0.id == id }) || location.region?.id == id { selectedRegionID = id }
    }

    private func matchesSearch(_ region: RegionSummary) -> Bool {
        searchTerm.isEmpty || region.Name.localizedCaseInsensitiveContains(searchTerm)
    }
}
