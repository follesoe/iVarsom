import Foundation

@MainActor
protocol RegionListViewModelProtocol: ObservableObject {
    var state: LoadState { get }
    var localRegion: RegionSummary? { get }
    var locationIsAuthorized: Bool { get }
    var filteredRegions: [RegionSummary] { get }
    var favoriteRegionIds: [Int] { get set }
    var favoriteRegions: [RegionSummary] { get }
    var searchTerm: String { get set }
    var selectedRegionId: Int? { get set}
    
    func needsRefresh() -> Bool
    func loadRegions() async -> ()
    func updateLocation() async -> ()
    
    func addFavorite(id: Int) -> ()
    func removeFavorite(id: Int) -> ()
}
