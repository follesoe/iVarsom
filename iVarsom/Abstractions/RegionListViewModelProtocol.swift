import Foundation

@MainActor
protocol RegionListViewModelProtocol: ObservableObject {
    var state: RegionListViewModel.State { get }
    var localRegion: RegionSummary? { get }
    var locationIsAuthorized: Bool { get }
    var filteredRegions: [RegionSummary] { get }
    var searchTerm: String { get set }
    var selectedRegionId: Int? { get set}
    
    func loadRegions() async -> ()
    func updateLocation() async -> ()
}
