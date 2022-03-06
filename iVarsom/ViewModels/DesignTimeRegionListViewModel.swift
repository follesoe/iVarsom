import Foundation

@MainActor
class DesignTimeRegionListViewModel: RegionListViewModelProtocol {
    @Published var state = RegionListViewModel.State.loading
    @Published var localRegion: RegionSummary? = nil
    @Published var locationIsAuthorized = false
    @Published var filteredRegions = [RegionSummary]()
    @Published var searchTerm = ""
    @Published var selectedRegionId: Int? = nil
    
    init() {
    }

    init(state: RegionListViewModel.State, locationIsAuthorized: Bool, filteredRegions: [RegionSummary]) {
        self.state = state
        self.locationIsAuthorized = locationIsAuthorized
        self.filteredRegions = filteredRegions
    }
    
    func loadRegions() async {
    }
    
    func updateLocation() async {
    }
}
