import AppIntents
import Foundation
import Observation

@Observable
@MainActor
final class ForecastNavigation {
    static let shared = ForecastNavigation()
    struct Request: Equatable {
        let id = UUID()
        let regionID: Int
    }
    private(set) var request: Request?
    @ObservationIgnored private var claimedID: UUID?

    func open(regionID: Int) { request = Request(regionID: regionID) }
    func claimRequest() -> Request? {
        guard let request, request.id != claimedID else { return nil }
        claimedID = request.id
        return request
    }

    func finish(_ completed: Request) {
        if request == completed { request = nil }
    }

    func release(_ pending: Request) {
        if request == pending { claimedID = nil }
    }
}

struct OpenRegionIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open avalanche forecast"
    static let description = IntentDescription("Open the full bulletin for a region or your current position.")

    @Parameter(title: "Region") var target: RegionConfigOptionAppEntity

    static var parameterSummary: some ParameterSummary { Summary("Open forecast for \(\.$target)") }

    init() {}
    init(region: RegionConfigOptionAppEntity) { target = region }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let regionID = Int(target.id), RegionOption.allOptions.contains(where: { $0.id == regionID }) else {
            throw ForecastError.invalidRegion
        }
        ForecastNavigation.shared.open(regionID: regionID)
        return .result()
    }
}
