import CoreLocation
import Foundation
import Testing

@testable import Skredvarsel

@MainActor
struct RegionBrowserModelTests {
    private let preferences = TestPreferences()
    private let directory = TemporaryDirectory()
    private let norway = StubNorwayClient()
    private let sweden = StubSwedenClient()
    private let location = StubLocation()

    private func model(now: @escaping () -> Date = { Fixtures.date }) -> RegionBrowserModel {
        RegionBrowserModel(
            repository: WarningRepository(
                norway: norway, sweden: sweden,
                cache: CacheService(directory: directory.url)),
            locationManager: location, favorites: preferences.favorites(), now: now)
    }

    @Test("The detail column and the map's forecast sheet share one favorite toggle")
    func togglesSelectedRegionFavorite() {
        let vm = model()
        vm.toggleSelectedRegionFavorite()  // No selection: no change.
        #expect(vm.favorites.ids.isEmpty)
        vm.selectedRegionID = 3003
        #expect(!vm.isSelectedRegionFavorite)
        vm.toggleSelectedRegionFavorite()
        #expect(vm.isSelectedRegionFavorite)
        #expect(vm.favorites.ids.contains(3003))
        vm.toggleSelectedRegionFavorite()
        #expect(!vm.isSelectedRegionFavorite)
    }

    @Test("Cold-launch fixed-region navigation does not wait for or compete with a catalog refresh")
    func navigationDuringCatalogLoad() async {
        let gate = WarningGate()
        norway.onLoadRegions = {
            try await gate.load().map { Fixtures.region($0.RegionId, name: "Refreshed name") }
        }
        let vm = model()
        let activation = Task { await vm.refreshOnActivation() }
        await gate.waitUntilStarted()
        await vm.selectRegion(id: 3003)
        #expect(vm.selectedRegion?.id == 3003)
        #expect(vm.detail.regionID == 3003)
        #expect(norway.regionRequests == 1)
        gate.finish(.success([Fixtures.warning()]))
        await activation.value
        #expect(vm.selectedRegion?.Name == "Refreshed name")
    }

    @Test("Local navigation owns its result even when activation starts another location request",
          arguments: ["complete", "cancel", "newTarget"])
    func concurrentLocalNavigation(outcome: String) async {
        let (events, started) = AsyncStream<Void>.makeStream()
        var pending: [CheckedContinuation<Location2D?, Never>] = []
        location.isAuthorized = true
        location.onUpdateLocation = {
            await withCheckedContinuation {
                pending.append($0)
                started.yield(())
            }
        }
        let vm = model()
        let navigation = Task { await vm.selectRegion(id: RegionOption.currentPositionOption.id) }
        var iterator = events.makeAsyncIterator()
        await iterator.next()
        let activation = Task { await vm.refreshOnActivation() }
        await iterator.next()
        if outcome == "cancel" { navigation.cancel() }
        if outcome == "newTarget" { await vm.selectRegion(id: 100001) }
        pending[0].resume(returning: Location2D(latitude: 78.22, longitude: 15.65))
        await navigation.value
        let expected: Int? = outcome == "cancel" ? nil : (outcome == "newTarget" ? 100001 : 3003)
        #expect(vm.selectedRegion?.id == expected)
        #expect(vm.location.region == nil) // Presentation request is still waiting.
        pending[1].resume(returning: Location2D(latitude: 69.65, longitude: 18.96))
        await activation.value
        #expect(vm.location.region?.id == 3011)
        #expect(vm.selectedRegion?.id == expected)
    }

    @Test("Offline catalogs and unknown deep links cannot discard a known selection")
    func offlineNavigation() async {
        norway.regions = .failure(TestFailure.offline)
        sweden.regions = .failure(TestFailure.offline)
        let vm = model()
        await vm.loadRegions()
        await vm.selectRegion(id: 3003)
        #expect(vm.selectedRegion?.id == 3003)
        await vm.selectRegion(id: -999)
        #expect(vm.selectedRegion?.id == 3003)
        await vm.selectRegion(id: RegionOption.currentPositionOption.id)
        #expect(vm.selectedRegion?.id == 3003)
        #expect(location.locationRequests == 0)
    }

    @Test func norwayFailureDoesNotDiscardSweden() async {
        norway.regions = .failure(TestFailure.offline)
        let vm = model()
        await vm.loadRegions()
        #expect(vm.state.phase == .loaded)
        #expect(vm.regions.isEmpty)
        #expect(vm.swedenRegions.map(\.id) == [100001])
        #expect(vm.needsRefresh())
    }

    @Test func swedenFailureDoesNotDiscardNorway() async {
        sweden.regions = .failure(TestFailure.offline)
        let vm = model()
        await vm.loadRegions()
        #expect(vm.state.phase == .loaded)
        #expect(vm.regions.map(\.id) == [3003])
        #expect(vm.swedenRegions.isEmpty)
    }

    @Test func filtersBRegionsAndSearchesBothCountries() async {
        var bRegion = Fixtures.region(3006)
        bRegion.TypeName = "B"
        norway.regions = .success([Fixtures.region(name: "Tromsø"), bRegion])
        sweden.regions = .success([Fixtures.region(100001, name: "Abisko")])
        let vm = model()
        await vm.loadRegions()
        #expect(vm.regions.count == 1)
        vm.searchTerm = "TROMSØ"
        #expect(vm.filteredRegions.count == 1)
        #expect(vm.filteredSwedenRegions.isEmpty)
        vm.searchTerm = "abisko"
        #expect(vm.filteredSwedenRegions.count == 1)
    }

    @Test func failedNetworkFallsBackPerCountry() async {
        let cache = CacheService(directory: directory.url)
        await cache.saveRegions([Fixtures.region(100001)], country: .sweden)
        norway.regions = .failure(TestFailure.offline)
        sweden.regions = .failure(TestFailure.offline)
        let vm = model()
        await vm.loadRegions()
        #expect(vm.state.phase == .loaded)
        #expect(vm.swedenRegions.count == 1)
    }

    @Test func failuresWithoutCacheAreReported() async {
        norway.regions = .failure(TestFailure.offline)
        sweden.regions = .failure(TestFailure.offline)
        let vm = model()
        await vm.loadRegions()
        #expect(vm.state.phase == .failed)
    }

    @Test func refreshesOnDayChangeEvenWithinCacheWindow() async {
        var date = Calendar.current.startOfDay(for: Fixtures.date).addingTimeInterval(86340)
        let vm = model(now: { date })
        await vm.loadRegions()
        #expect(!vm.needsRefresh())
        date = date.addingTimeInterval(120)
        #expect(vm.needsRefresh())
    }

    @Test func deniedLocationDoesNotRequestCoordinates() async {
        let vm = model()
        await vm.location.refresh(regions: vm.allRegions, requestPermission: true)
        #expect(location.locationRequests == 0)
        #expect(!vm.location.isAuthorized)
        #expect(location.permissionRequests == 1)
    }

    @Test("The location row can distinguish undecided, denied and restricted permission",
          arguments: [CLAuthorizationStatus.notDetermined, .denied, .restricted])
    func preservesLocationPermissionState(status: CLAuthorizationStatus) async {
        let vm = model()
        location.authorizationStatus = status
        await vm.location.refresh(regions: [])
        #expect(vm.location.authorizationStatus == status)
        #expect(!vm.location.isAuthorized)
        #expect(!vm.location.isRefreshing)
        #expect(location.permissionRequests == 0)
        #expect(location.locationRequests == 0)
    }

    @Test("An unavailable location ends progress and can be retried", arguments: [false, true])
    func retriesUnavailableLocation(throwsError: Bool) async {
        location.isAuthorized = true
        let vm = model()
        location.onUpdateLocation = {
            #expect(vm.location.isRefreshing)
            if throwsError { throw TestFailure.offline }
            return nil
        }
        await vm.location.refresh(regions: [], requestPermission: true)
        #expect(vm.location.isAuthorized)
        #expect(vm.location.region == nil)
        #expect(!vm.location.isRefreshing)

        location.onUpdateLocation = nil
        location.coordinate = Location2D(latitude: 78.22, longitude: 15.65)
        await vm.location.refresh(regions: [Fixtures.region(3003)], requestPermission: true)
        #expect(vm.location.region?.id == 3003)
        #expect(!vm.location.isRefreshing)
    }

    @Test("Opening a fixed region and reactivating never asks for location permission", arguments: [false, true])
    func activationUsesExistingLocationPermission(isAuthorized: Bool) async {
        location.isAuthorized = isAuthorized
        location.coordinate = Location2D(latitude: 78.22, longitude: 15.65)
        let vm = model()
        await vm.selectRegion(id: 3003)
        await vm.refreshOnActivation()
        await vm.refreshOnActivation()
        #expect(vm.selectedRegion?.id == 3003)
        #expect(location.permissionRequests == 0)
        #expect(location.authorizationChecks == 2)
        #expect(location.locationRequests == (isAuthorized ? 2 : 0))
    }

    @Test("Explicit current-position actions request permission", arguments: ["map", "navigation"])
    func explicitLocationActions(action: String) async {
        location.isAuthorized = true
        location.coordinate = Location2D(latitude: 78.22, longitude: 15.65)
        let vm = model()
        if action == "map" {
            await vm.location.refresh(regions: [Fixtures.region(3003)], requestPermission: true)
            #expect(vm.location.region?.id == 3003)
        } else {
            await vm.selectRegion(id: RegionOption.currentPositionOption.id)
            #expect(vm.selectedRegion?.id == 3003)
        }
        #expect(location.permissionRequests == 1)
        #expect(location.locationRequests == 1)
    }

    @Test func reactivationUpdatesLocalFavoriteWithoutReloadingFreshCatalog() async {
        norway.regions = .success([Fixtures.region(3003), Fixtures.region(3011)])
        location.isAuthorized = true
        location.coordinate = Location2D(latitude: 78.22, longitude: 15.65)
        let vm = model()
        vm.favorites.addFavorite(RegionOption.currentPositionOption.id)
        await vm.refreshOnActivation()
        #expect(vm.favoriteRegions.map(\.id) == [3003])
        #expect(location.locationRequests == 1)
        #expect(!vm.needsRefresh())

        location.coordinate = Location2D(latitude: 69.65, longitude: 18.96)
        await vm.refreshOnActivation()

        #expect(vm.favoriteRegions.map(\.id) == [3011])
        #expect(vm.location.coordinate?.latitude == 69.65)
        #expect(location.locationRequests == 2)
        #expect(norway.regionRequests == 1)
        #expect(sweden.regionRequests == 1)
    }

    @Test func reactivationRetriesCancelledLocationWithFreshCatalog() async {
        let (events, started) = AsyncStream<Void>.makeStream()
        var pendingLocation: CheckedContinuation<Location2D?, Never>?
        location.isAuthorized = true
        location.coordinate = Location2D(latitude: 78.22, longitude: 15.65)
        location.onUpdateLocation = {
            await withCheckedContinuation {
                pendingLocation = $0
                started.yield(())
            }
        }
        let vm = model()
        vm.favorites.addFavorite(RegionOption.currentPositionOption.id)
        let activation = Task { await vm.refreshOnActivation() }
        var iterator = events.makeAsyncIterator()
        await iterator.next()
        activation.cancel()
        pendingLocation?.resume(returning: location.coordinate)
        await activation.value
        #expect(!vm.needsRefresh())
        #expect(vm.location.coordinate == nil)
        #expect(!vm.location.isRefreshing)
        #expect(vm.favoriteRegions.isEmpty)

        location.onUpdateLocation = nil
        await vm.refreshOnActivation()

        #expect(vm.favoriteRegions.map(\.id) == [3003])
        #expect(location.locationRequests == 2)
        #expect(norway.regionRequests == 1)
        #expect(sweden.regionRequests == 1)
    }

    @Test func reactivationClearsRevokedLocationWithFreshCatalog() async {
        location.isAuthorized = true
        location.coordinate = Location2D(latitude: 78.22, longitude: 15.65)
        let vm = model()
        vm.favorites.addFavorite(RegionOption.currentPositionOption.id)
        await vm.refreshOnActivation()
        #expect(!vm.favoriteRegions.isEmpty)

        location.isAuthorized = false
        await vm.refreshOnActivation()

        #expect(!vm.location.isAuthorized)
        #expect(vm.location.coordinate == nil)
        #expect(vm.favoriteRegions.isEmpty)
        #expect(norway.regionRequests == 1)
        #expect(sweden.regionRequests == 1)
    }

    @Test func revokingPermissionClearsLastKnownLocation() async {
        let vm = model()
        location.isAuthorized = true
        location.coordinate = Location2D(latitude: 78.22, longitude: 15.65)
        await vm.location.refresh(regions: [])
        #expect(vm.location.coordinate != nil)
        location.isAuthorized = false
        await vm.location.refresh(regions: [])
        #expect(vm.location.coordinate == nil)
        #expect(vm.location.region == nil)
        #expect(!vm.location.isAuthorized)
    }

    @Test func windowsHaveIndependentSelectionAndSharedFavorites() {
        let favorites = preferences.favorites()
        let first = RegionBrowserModel(locationManager: StubLocation(), favorites: favorites)
        let second = RegionBrowserModel(locationManager: StubLocation(), favorites: favorites)
        first.selectedRegionID = 3003
        first.favorites.addFavorite(3003)
        #expect(second.selectedRegionID == nil)
        #expect(second.favorites.ids == [3003])
    }

    @Test func selectionResolvesToRefreshedRegionSnapshot() async {
        let vm = model()
        await vm.loadRegions()
        vm.selectedRegionID = 3003
        norway.regions = .success([Fixtures.region(name: "Updated Name")])
        await vm.loadRegions()
        #expect(vm.selectedRegion?.Name == "Updated Name")
        #expect(vm.detail.regionID == 3003)
    }

    @Test func clearingBrowserSelectionInvalidatesDetail() async {
        let vm = model()
        vm.selectedRegionID = 3003
        await vm.detail.load()
        #expect(vm.detail.selectedWarning != nil)
        vm.selectedRegionID = nil
        #expect(vm.detail.state.phase == .idle)
        #expect(vm.detail.selectedWarning == nil)
    }
}
