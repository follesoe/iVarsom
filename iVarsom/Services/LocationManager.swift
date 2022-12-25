
import Combine
import CoreLocation

public typealias Location = CLLocationCoordinate2D

final class LocationManager: NSObject {
    private typealias LocationCheckedThrowingContinuation = CheckedContinuation<Location, Error>
    private typealias BoolCheckedThrowingContinuation = CheckedContinuation<Bool, Error>

    fileprivate lazy var locationManager = CLLocationManager()
    
    private var locationCheckedThrowingContinuation: LocationCheckedThrowingContinuation?
    private var boolCheckedThrowingContinuation: BoolCheckedThrowingContinuation?
    
    public var isAuthorizedForWidgetUpdates: Bool {
#if os(watchOS)
        return isAuthorized
#else
        return locationManager.isAuthorizedForWidgetUpdates
#endif
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
    
    func requestPermission() async throws -> Bool {
        print("LocationManager.requestPermission")
        return try await withCheckedThrowingContinuation({ [weak self] (continuation: BoolCheckedThrowingContinuation) in
            guard let self = self else {
                return
            }
            
            self.boolCheckedThrowingContinuation = continuation
            
            if (self.isAuthorized) {
                boolCheckedThrowingContinuation?.resume(returning: true)
            } else {
                print("requestWhenInUseAuthorization is notDetermined: \(locationManager.authorizationStatus == .notDetermined)")
                self.locationManager.delegate = self
                self.locationManager.requestWhenInUseAuthorization()
            }
        })
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
        print("LocationManager.didFailWithError: \(error)")
        locationCheckedThrowingContinuation?.resume(throwing: error)
        locationCheckedThrowingContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("LocationManager.locationManagerDidChangeAuthorization: \(manager.authorizationStatus)")
        boolCheckedThrowingContinuation?.resume(returning: isAuthorized)
    }
}
