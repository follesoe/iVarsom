import CoreLocation
import Testing
@testable import Skredvarsel

/// The native manager never starts GPS or shows a permission prompt in tests.
private final class StubNativeLocationManager: CLLocationManager {
    let requested: AsyncStream<Void>.Continuation
    var simulatedAuthorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    var onRequestPermission: (() -> Void)?
    private(set) var permissionRequests = 0
    init(requested: AsyncStream<Void>.Continuation) {
        self.requested = requested
        super.init()
    }
    override var authorizationStatus: CLAuthorizationStatus { simulatedAuthorizationStatus }
    override func requestWhenInUseAuthorization() {
        permissionRequests += 1
        onRequestPermission?()
    }
    override func requestLocation() { requested.yield(()) }
    override func stopUpdatingLocation() {}
}

@MainActor
struct LocationManagerTests {
    @Test("Only an explicit request prompts for an undecided permission",
          arguments: [CLAuthorizationStatus.authorizedWhenInUse, .denied, .restricted])
    func requestsUndecidedPermission(decision: CLAuthorizationStatus) async throws {
        let (_, requested) = AsyncStream<Void>.makeStream()
        let native = StubNativeLocationManager(requested: requested)
        native.simulatedAuthorizationStatus = .notDetermined
        let service = LocationManager(manager: native)
        service.locationManagerDidChangeAuthorization(native)
        #expect(try await !service.checkAuthorization())
        #expect(native.permissionRequests == 0)
        native.onRequestPermission = {
            native.simulatedAuthorizationStatus = decision
            service.locationManagerDidChangeAuthorization(native)
        }
        defer { native.onRequestPermission = nil }
        let authorized = try await service.requestPermission()
        #expect(authorized == LocationManager.isAuthorized(decision))
        #expect(service.authorizationStatus == decision)
        #expect(native.permissionRequests == 1)
    }

    @Test("A saved denial or restriction cannot display another system prompt",
          arguments: [CLAuthorizationStatus.denied, .restricted])
    func doesNotRepeatDeniedPermission(status: CLAuthorizationStatus) async throws {
        let (_, requested) = AsyncStream<Void>.makeStream()
        let native = StubNativeLocationManager(requested: requested)
        native.simulatedAuthorizationStatus = status
        let service = LocationManager(manager: native)
        service.locationManagerDidChangeAuthorization(native)
        #expect(try await !service.requestPermission())
        #expect(native.permissionRequests == 0)
        #expect(service.authorizationStatus == status)
    }

    @Test func deliversDelegateCoordinate() async throws {
        let (events, requested) = AsyncStream<Void>.makeStream()
        let native = StubNativeLocationManager(requested: requested)
        let service = LocationManager(manager: native)
        service.locationManagerDidChangeAuthorization(native)
        let task = Task { try await service.updateLocation() }
        var iterator = events.makeAsyncIterator()
        await iterator.next()
        service.locationManager(native, didUpdateLocations: [CLLocation(latitude: 69, longitude: 18)])
        let coordinate = try await task.value
        #expect(coordinate?.latitude == 69)
        #expect(coordinate?.longitude == 18)
    }

    @Test func cancellationResumesPendingRequest() async {
        let (events, requested) = AsyncStream<Void>.makeStream()
        let native = StubNativeLocationManager(requested: requested)
        let service = LocationManager(manager: native)
        service.locationManagerDidChangeAuthorization(native)
        let task = Task { try await service.updateLocation() }
        var iterator = events.makeAsyncIterator()
        await iterator.next()
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func delegateFailureResumesPendingRequest() async {
        let (events, requested) = AsyncStream<Void>.makeStream()
        let native = StubNativeLocationManager(requested: requested)
        let service = LocationManager(manager: native)
        service.locationManagerDidChangeAuthorization(native)
        let task = Task { try await service.updateLocation() }
        var iterator = events.makeAsyncIterator()
        await iterator.next()
        service.locationManager(native, didFailWithError: CLError(.locationUnknown))
        await #expect(throws: CLError.self) { try await task.value }
    }

    @Test(arguments: [CLAuthorizationStatus.notDetermined, .denied, .restricted])
    func unauthorizedStatuses(status: CLAuthorizationStatus) {
        #expect(!LocationManager.isAuthorized(status))
    }
}
