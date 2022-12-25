import Foundation

@MainActor
protocol RegionDetailViewModelProtocol: ObservableObject {
    var state: LoadState { get }
    var regionSummary:RegionSummary { get }
    var selectedWarning:AvalancheWarningSimple { get set }
    var warnings:[AvalancheWarningSimple] { get set }
    var isLocalRegion:Bool { get set}
    
    /**
     Load detailed warnings for selected region.
     
        - Parameters:
          - from: Number of days back in time to load warnings (default -5)
          - to: Number of days into the future to load warnings (default 2)
     */
    func loadWarnings(from: Int, to: Int) async -> ()
}
