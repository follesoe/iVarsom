import Foundation

@MainActor
protocol RegionListViewModelProtocol: AnyObject, Observable {
    var regionLoadState: LoadState { get }
    var warningLoadState: LoadState { get }
    var localRegion: RegionSummary? { get }
    var locationIsAuthorized: Bool { get }
    var regions: [RegionSummary] { get }
    var swedenRegions: [RegionSummary] { get }
    var favoriteRegionIds: [Int] { get set }
    var searchTerm: String { get set }
    var selectedRegion: RegionSummary? { get set }
    var warnings: [AvalancheWarningDetailed] { get set }
    var selectedWarning: AvalancheWarningDetailed? { get set }

    // Computed properties
    var filteredRegions: [RegionSummary] { get }
    var filteredSwedenRegions: [RegionSummary] { get }
    var favoriteRegions: [RegionSummary] { get }

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
