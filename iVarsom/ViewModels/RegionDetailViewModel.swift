import Foundation
import SwiftUI

@MainActor
class RegionDetailViewModel: RegionDetailViewModelProtocol {
    @Published var regionSummary:RegionSummary
    @Published var selectedWarning:AvalancheWarningSimple
    @Published var warnings = [AvalancheWarningSimple]()
    
    private let client: VarsomApiClient
    
    init(client: VarsomApiClient, regionSummary: RegionSummary) {
        self.client = client
        self.regionSummary = regionSummary
        self.selectedWarning = regionSummary.AvalancheWarningList.first!
    }
    
    func loadWarnings() async {
        do {
            let from = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
            let to = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            self.warnings = try await client.loadWarnings(
                lang: VarsomApiClient.currentLang(),
                regionId: regionSummary.Id,
                from: from,
                to: to)
        } catch {
            print(error)
        }
    }
}
