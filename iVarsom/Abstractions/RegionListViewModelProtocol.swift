import Foundation

@MainActor
protocol RegionListViewModelProtocol: ObservableObject {
    var regionLoadState: LoadState { get }
    var warningLoadState: LoadState { get }
    var localRegion: RegionSummary? { get }
    var locationIsAuthorized: Bool { get }
    var filteredRegions: [RegionSummary] { get }
    var favoriteRegionIds: [Int] { get set }
    var favoriteRegions: [RegionSummary] { get }
    var searchTerm: String { get set }
    var selectedRegion: RegionSummary? { get set }    
    var warnings: [AvalancheWarningDetailed] { get set }
    var selectedWarning: AvalancheWarningDetailed? { get set }
    
    func needsRefresh() -> Bool
    func loadRegions() async -> ()
    func updateLocation() async -> ()
    
    func addFavorite(id: Int) -> ()
    func removeFavorite(id: Int) -> ()
    func selectRegionById(regionId: Int) async -> ()
    
    /**
     Load detailed warnings for selected region.
     
        - Parameters:
          - from: Number of days back in time to load warnings (default -5)
          - to: Number of days into the future to load warnings (default 2)
     */
    func loadWarnings(from: Int, to: Int) async -> ()
}
