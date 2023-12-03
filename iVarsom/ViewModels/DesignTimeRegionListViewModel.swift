import Foundation

@MainActor
class DesignTimeRegionListViewModel: RegionListViewModelProtocol {
    @Published var regionLoadState = LoadState.loading
    @Published var warningLoadState = LoadState.loading
    @Published var localRegion: RegionSummary? = nil
    @Published var locationIsAuthorized = false
    @Published var filteredRegions = [RegionSummary]()
    @Published var favoriteRegionIds = [Int]()
    @Published var favoriteRegions = [RegionSummary]()
    @Published var searchTerm = ""
    @Published var selectedRegion: RegionSummary? = nil
    @Published var warnings = [AvalancheWarningDetailed]()
    @Published var selectedWarning: AvalancheWarningDetailed? = nil
    
    init() {
    }

    init(state: LoadState, locationIsAuthorized: Bool, filteredRegions: [RegionSummary]) {
        self.regionLoadState = state
        self.locationIsAuthorized = locationIsAuthorized
        self.filteredRegions = filteredRegions
        self.favoriteRegions = filteredRegions
    }
     
    func needsRefresh() -> Bool {
        return true
    }
    
    func loadRegions() async {
    }
    
    func updateLocation() async {
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
