import Foundation
import SwiftUI

@MainActor
class RegionDetailViewModel: RegionDetailViewModelProtocol {
    @Published private(set) var state = LoadState.idle
    @Published var regionSummary:RegionSummary
    @Published var selectedWarning:AvalancheWarningSimple
    @Published var warnings = [AvalancheWarningSimple]()
    @Published var isLocalRegion: Bool
    
    private let client: VarsomApiClient
    
    init(client: VarsomApiClient, regionSummary: RegionSummary, isLocalRegion: Bool) {
        self.client = client
        self.regionSummary = regionSummary
        self.selectedWarning = regionSummary.AvalancheWarningList.first!
        self.isLocalRegion = isLocalRegion
    }

    func loadWarnings(from: Int = -5, to: Int = 2) async {
        do {
            self.state = .loading
            let from = Calendar.current.date(byAdding: .day, value: from, to: Date())!
            let to = Calendar.current.date(byAdding: .day, value: to, to: Date())!
            self.warnings = try await client.loadWarnings(
                lang: VarsomApiClient.currentLang(),
                regionId: regionSummary.Id,
                from: from,
                to: to)
            self.state = .loaded
        } catch {
            self.state = .failed
            print(error)
        }
    }
}
