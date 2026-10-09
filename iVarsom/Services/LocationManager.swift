import CoreLocation

public typealias Location2D = CLLocationCoordinate2D

@MainActor
protocol LocationProviding: AnyObject {
    var isAuthorized: Bool { get }
    func checkAuthorization() async throws -> Bool
    func requestPermission() async throws -> Bool
    func updateLocation() async throws -> Location2D?
}

/// Core Location delivers callbacks on the run loop where its manager was created.
/// Keeping construction, delegate callbacks and continuations on MainActor gives
/// apps, widgets and intents the same isolation without unchecked Sendable state.
@MainActor
final class LocationManager: NSObject, LocationProviding, @preconcurrency CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private var authorizationStatus: CLAuthorizationStatus?
    private var authorizationRequests: [UUID: CheckedContinuation<CLAuthorizationStatus, any Error>] = [:]
    private var permissionRequests: [UUID: CheckedContinuation<Bool, any Error>] = [:]
    private var locationRequests: [UUID: CheckedContinuation<Location2D?, any Error>] = [:]
    private var timeout: Task<Void, Never>?

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.delegate = self
    }

    var isAuthorized: Bool {
        authorizationStatus.map(Self.isAuthorized) ?? false
    }

    func checkWidgetAuthorization() async throws -> Bool {
        _ = try await currentAuthorization()
        #if os(watchOS)
        return isAuthorized
        #else
        return manager.isAuthorizedForWidgetUpdates
        #endif
    }

    static func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
        status == .authorizedAlways || status == .authorizedWhenInUse
    }

    func checkAuthorization() async throws -> Bool {
        Self.isAuthorized(try await currentAuthorization())
    }

    // Wait for the initial delegate event instead of synchronously asking the
    // location daemon during SwiftUI view construction.
    private func currentAuthorization() async throws -> CLAuthorizationStatus {
        try Task.checkCancellation()
        if let authorizationStatus { return authorizationStatus }
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { authorizationRequests[id] = $0 }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.authorizationRequests.removeValue(forKey: id)?.resume(throwing: CancellationError())
            }
        }
    }

    func requestPermission() async throws -> Bool {
        let status = try await currentAuthorization()
        guard status == .notDetermined else { return Self.isAuthorized(status) }
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                permissionRequests[id] = continuation
                if permissionRequests.count == 1 { manager.requestWhenInUseAuthorization() }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.permissionRequests.removeValue(forKey: id)?.resume(throwing: CancellationError())
            }
        }
    }

    func updateLocation() async throws -> Location2D? {
        guard try await checkAuthorization() else { return nil }
        try Task.checkCancellation()
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                locationRequests[id] = continuation
                if locationRequests.count == 1 {
                    manager.requestLocation()
                    timeout = Task { [weak self] in
                        do {
                            try await Task.sleep(for: .seconds(20))
                            self?.finishLocationRequests(.failure(CLError(.locationUnknown)))
                        } catch { /* The request completed or was cancelled. */ }
                    }
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                locationRequests.removeValue(forKey: id)?.resume(throwing: CancellationError())
                if locationRequests.isEmpty { stopLocationRequest() }
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationStatus = status
        let initialRequests = authorizationRequests.values
        authorizationRequests.removeAll()
        for request in initialRequests { request.resume(returning: status) }
        guard status != .notDetermined else { return }
        let requests = permissionRequests.values
        permissionRequests.removeAll()
        for request in requests { request.resume(returning: isAuthorized) }
        if !isAuthorized { finishLocationRequests(.success(nil)) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finishLocationRequests(.success(locations.last(where: { $0.horizontalAccuracy >= 0 })?.coordinate))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        finishLocationRequests(.failure(error))
    }

    private func finishLocationRequests(_ result: Result<Location2D?, any Error>) {
        let requests = locationRequests.values
        locationRequests.removeAll()
        stopLocationRequest()
        for request in requests { request.resume(with: result) }
    }

    private func stopLocationRequest() {
        timeout?.cancel()
        timeout = nil
        manager.stopUpdatingLocation()
    }
}
