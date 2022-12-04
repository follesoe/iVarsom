import Foundation

@MainActor
class DesignTimeRegionListViewModel: RegionListViewModelProtocol {
    @Published var state = LoadState.loading
    @Published var localRegion: RegionSummary? = nil
    @Published var locationIsAuthorized = false
    @Published var filteredRegions = [RegionSummary]()
    @Published var favoriteRegionIds = [Int]()
    @Published var favoriteRegions = [RegionSummary]()
    @Published var searchTerm = ""
    @Published var selectedRegionId: Int? = nil
    
    init() {
    }

    init(state: LoadState, locationIsAuthorized: Bool, filteredRegions: [RegionSummary]) {
        self.state = state
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
}
