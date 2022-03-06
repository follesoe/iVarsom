import Foundation

@MainActor
class DesignTimeRegionDetailViewModel: RegionDetailViewModelProtocol {
    @Published var regionSummary: RegionSummary
    @Published var selectedWarning: AvalancheWarningSimple
    @Published var warnings = [AvalancheWarningSimple]()
    
    
    init(regionSummary: RegionSummary) {
        self.regionSummary = regionSummary
        self.selectedWarning = regionSummary.AvalancheWarningList.first!
        self.warnings = regionSummary.AvalancheWarningList
    }
    
    func loadWarnings() async {
    }
}
