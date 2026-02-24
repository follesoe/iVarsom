import Foundation

@Observable
@MainActor
class DesignTimeRegionListViewModel: RegionListViewModelProtocol {
    var regionLoadState = LoadState.loading
    var warningLoadState = LoadState.loading
    var localRegion: RegionSummary? = nil
    var userLocation: Location2D? = nil
    var locationIsAuthorized = false
    var regions = [RegionSummary]()
    var swedenRegions = [RegionSummary]()
    var favoriteRegionIds = [Int]()
    var searchTerm = ""
    var selectedRegion: RegionSummary? = nil
    var warnings = [AvalancheWarningDetailed]()
    var selectedWarning: AvalancheWarningDetailed? = nil
    var reviewPromptService = ReviewPromptService()

    private var _filteredRegions = [RegionSummary]()

    var filteredRegions: [RegionSummary] {
        _filteredRegions
    }

    var filteredSwedenRegions: [RegionSummary] {
        []
    }

    var favoriteRegions: [RegionSummary] {
        _filteredRegions
    }

    init() {
    }

    init(state: LoadState, locationIsAuthorized: Bool, filteredRegions: [RegionSummary]) {
        self.regionLoadState = state
        self.locationIsAuthorized = locationIsAuthorized
        self._filteredRegions = filteredRegions
    }

    func needsRefresh() -> Bool {
        return true
    }

    func loadRegions() async {
    }

    func updateLocation() async {
    }

    func requestLocationForMap() async {
    }

    func addFavorite(id: Int) {
    }

    func removeFavorite(id: Int) {
    }

    func loadWarnings(from: Int = -5, to: Int = 2) async {
    }

    func selectRegionById(regionId: Int) async {
    }
}
