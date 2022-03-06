import Foundation

@MainActor
protocol RegionDetailViewModelProtocol: ObservableObject {
    var regionSummary:RegionSummary { get }
    var selectedWarning:AvalancheWarningSimple { get set }
    var warnings:[AvalancheWarningSimple] { get set }
    func loadWarnings() async -> ()
}
