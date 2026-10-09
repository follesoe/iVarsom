import Foundation
import Observation

struct WarningSnapshot {
    let warnings: [AvalancheWarningDetailed]
    let source: WarningSource
    var selectedWarningID: Int?

    var selectedWarning: AvalancheWarningDetailed? {
        warnings.first { $0.id == selectedWarningID }
    }
}

@Observable
@MainActor
final class WarningDetailModel {
    private(set) var state: LoadState<WarningSnapshot> = .idle
    private(set) var regionID: Int?
    private let repository: any WarningRepositoryProviding
    private let now: () -> Date
    @ObservationIgnored private var requestID = UUID()

    init(repository: any WarningRepositoryProviding, now: @escaping () -> Date = { Date.current }) {
        self.repository = repository
        self.now = now
    }

    var warnings: [AvalancheWarningDetailed] { state.value?.warnings ?? [] }
    var selectedWarning: AvalancheWarningDetailed? { state.value?.selectedWarning }
    var selectedWarningID: Int? {
        get { state.value?.selectedWarningID }
        set {
            guard case .loaded(var snapshot) = state,
                newValue == nil || snapshot.warnings.contains(where: { $0.id == newValue })
            else { return }
            snapshot.selectedWarningID = newValue
            state = .loaded(snapshot)
        }
    }

    func selectRegion(_ id: Int?) {
        guard regionID != id else { return }
        regionID = id
        requestID = UUID()
        state = .idle
    }

    func load(from: Int = WarningDateRange.defaultDaysBefore, to: Int = WarningDateRange.defaultDaysAfter) async {
        guard let regionID else { return }
        let request = UUID()
        requestID = request
        state = .loading()
        defer {
            if requestID == request, state.phase == .loading { state = .idle }
        }
        do {
            try Task.checkCancellation()
            let date = now()
            let query = WarningRequest(regionID: regionID, date: date, daysBefore: -from, daysAfter: to)
            let loaded = try await repository.loadWarnings(query, cachePolicy: .fallback)
            try Task.checkCancellation()
            guard requestID == request, self.regionID == regionID else { return }
            let warnings = loaded.warnings.sorted { $0.ValidFrom < $1.ValidFrom }
            let selectedID = warnings.currentWarningIndex(on: date).map { warnings[$0].id }
            state = .loaded(WarningSnapshot(warnings: warnings, source: loaded.source, selectedWarningID: selectedID))
        } catch {
            guard !Task.isCancelled, !(error is CancellationError),
                (error as? URLError)?.code != .cancelled,
                requestID == request, self.regionID == regionID
            else { return }
            state = .failed
        }
    }
}
