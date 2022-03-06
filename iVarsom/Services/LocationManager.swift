
import Combine
import CoreLocation

public typealias Location = CLLocationCoordinate2D

final class LocationManager: NSObject {
    private typealias LocationCheckedThrowingContinuation = CheckedContinuation<Location, Error>

    fileprivate lazy var locationManager = CLLocationManager()
    
    private var locationCheckedThrowingContinuation: LocationCheckedThrowingContinuation?
    
    public var isAuthorizedForWidgetUpdates: Bool {
        return locationManager.isAuthorizedForWidgetUpdates
    }
    
    public var isAuthorized: Bool {
        switch locationManager.authorizationStatus {
            case .notDetermined, .restricted, .denied:
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                return true
            @unknown default:
                return false
        }
    }

    func updateLocation() async throws -> Location {
        print("LocationManager.updateLocation")
        return try await withCheckedThrowingContinuation({ [weak self] (continuation: LocationCheckedThrowingContinuation) in
            guard let self = self else {
                return
            }

            self.locationCheckedThrowingContinuation = continuation
            
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            self.locationManager.requestWhenInUseAuthorization()
            if (self.locationManager.location != nil) {
                let coord = self.locationManager.location!.coordinate
                let location = Location(latitude: coord.latitude, longitude: coord.longitude)
                locationCheckedThrowingContinuation?.resume(returning: location)
                locationCheckedThrowingContinuation = nil
            } else {
                self.locationManager.requestLocation()
            }
        })
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LocationManager.didUpdateLocations")
        if let locationObj = locations.last {
            let coord = locationObj.coordinate
            let location = Location(latitude: coord.latitude, longitude: coord.longitude)
            locationCheckedThrowingContinuation?.resume(returning: location)
            locationCheckedThrowingContinuation = nil
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager.didFailWithError")
        locationCheckedThrowingContinuation?.resume(throwing: error)
        locationCheckedThrowingContinuation = nil
    }
}
