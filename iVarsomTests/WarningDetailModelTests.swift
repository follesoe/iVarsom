import Foundation
import Testing

@testable import Skredvarsel

@MainActor
struct WarningDetailModelTests {
    private let directory = TemporaryDirectory()
    private let norway = StubNorwayClient()
    private let sweden = StubSwedenClient()

    private func model() -> WarningDetailModel {
        let repository = WarningRepository(
            norway: norway, sweden: sweden, cache: CacheService(directory: directory.url))
        let model = WarningDetailModel(repository: repository, now: { Fixtures.date })
        model.selectRegion(3003)
        return model
    }

    @Test func awaitingWarningsWaitsForCompletionAndSelectsToday() async {
        let today = Fixtures.warning()
        var yesterday = Fixtures.warning(date: Fixtures.date.addingTimeInterval(-86400))
        yesterday.RegId = 42
        norway.detailed = { _ in [today, yesterday] }
        let vm = model()
        await vm.load()
        #expect(vm.state.phase == .loaded)
        #expect(vm.warnings.count == 2)
        #expect(vm.selectedWarning?.ValidFrom == Fixtures.date)
        vm.selectedWarningID = 42
        #expect(vm.selectedWarning?.ValidFrom == yesterday.ValidFrom)
        vm.selectedWarningID = 999
        #expect(vm.selectedWarningID == 42)
    }

    @Test(arguments: [false, true]) func olderRequestCannotOverwriteNewSelection(fails: Bool) async {
        let gate = WarningGate()
        norway.detailed = { id in id == 3003 ? try await gate.load() : [Fixtures.warning(id)] }
        let vm = model()
        let first = Task { await vm.load() }
        await gate.waitUntilStarted()
        vm.selectRegion(3006)
        await vm.load()
        gate.finish(fails ? .failure(TestFailure.offline) : .success([Fixtures.warning()]))
        await first.value
        #expect(vm.selectedWarning?.RegionId == 3006)
        #expect(vm.warnings.map(\.RegionId) == [3006])
        #expect(vm.state.phase == .loaded)
    }

    @Test func cancellationDoesNotLoadCacheOrLeaveSpinnerRunning() async {
        let cache = CacheService(directory: directory.url)
        await cache.saveWarningsDetailed([Fixtures.warning()], regionId: 3003)
        let gate = WarningGate()
        norway.detailed = { _ in try await gate.load() }
        let vm = model()
        let task = Task { await vm.load() }
        await gate.waitUntilStarted()
        task.cancel()
        gate.finish(.failure(URLError(.cancelled)))
        await task.value
        #expect(vm.state.phase == .idle)
        #expect(vm.warnings.isEmpty)
        #expect(vm.selectedWarning == nil)
    }

    @Test func deselectionInvalidatesPendingWarning() async {
        let gate = WarningGate()
        norway.detailed = { _ in try await gate.load() }
        let vm = model()
        let task = Task { await vm.load() }
        await gate.waitUntilStarted()
        vm.selectRegion(nil)
        gate.finish(.success([Fixtures.warning()]))
        await task.value
        #expect(vm.state.phase == .idle)
        #expect(vm.warnings.isEmpty)
    }

    @Test func offlineWarningFallback() async {
        let cache = CacheService(directory: directory.url)
        await cache.saveWarningsDetailed([Fixtures.warning()], regionId: 3003)
        norway.detailed = { _ in throw TestFailure.offline }
        let vm = model()
        await vm.load()
        #expect(vm.state.value?.source == .cache)
        #expect(vm.selectedWarning?.RegionId == 3003)
    }

    @Test func failedAndEmptyResponsesAreDistinct() async {
        let vm = model()
        norway.detailed = { _ in throw TestFailure.offline }
        await vm.load()
        #expect(vm.state.phase == .failed)
        norway.detailed = { _ in [] }
        await vm.load()
        #expect(vm.state.phase == .loaded)
        #expect(vm.selectedWarning == nil)
        #expect(vm.warnings.isEmpty)
    }

    @Test func swedishHistoryHonorsRequestedRange() async {
        let vm = model()
        vm.selectRegion(100001)
        await vm.load(from: -5, to: 2)
        #expect(sweden.requestedDaysBefore == 5)
    }
}
