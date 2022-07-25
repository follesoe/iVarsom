import Foundation

@MainActor
class DesignTimeRegionDetailViewModel: RegionDetailViewModelProtocol {
    @Published var state = LoadState.loading
    @Published var regionSummary: RegionSummary
    @Published var selectedWarning: AvalancheWarningSimple
    @Published var warnings = [AvalancheWarningSimple]()
    
    
    init(regionSummary: RegionSummary) {
        self.regionSummary = regionSummary
        self.selectedWarning = regionSummary.AvalancheWarningList.first!
        self.warnings = regionSummary.AvalancheWarningList
    }
    
    func loadWarnings(from: Int = -5, to: Int = 2) async {
    }
}
