import CoreLocation
import Testing
@testable import Skredvarsel

/// The native manager never starts GPS or shows a permission prompt in tests.
private final class StubNativeLocationManager: CLLocationManager {
    let requested: AsyncStream<Void>.Continuation
    init(requested: AsyncStream<Void>.Continuation) {
        self.requested = requested
        super.init()
    }
    override var authorizationStatus: CLAuthorizationStatus { .authorizedWhenInUse }
    override func requestLocation() { requested.yield(()) }
    override func stopUpdatingLocation() {}
}

@MainActor
struct LocationManagerTests {
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
