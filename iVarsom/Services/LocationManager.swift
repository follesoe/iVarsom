
import Combine
import CoreLocation
import SwiftLocation

public typealias Location2D = CLLocationCoordinate2D

final class LocationManager: NSObject {
    fileprivate lazy var locationManager = CLLocationManager()
    fileprivate lazy var swiftLocation = Location(locationManager: locationManager)

    public var isAuthorizedForWidgetUpdates: Bool {
#if os(watchOS)
        return isAuthorized
#else
        return locationManager.isAuthorizedForWidgetUpdates
#endif
    }
    
    public var isAuthorized: Bool {
        return hasPermission(status: locationManager.authorizationStatus)
    }
    
    func hasPermission(status: CLAuthorizationStatus) -> Bool {
        switch status {
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
        let permission = try await swiftLocation.requestPermission(.whenInUse)
        return hasPermission(status: permission)
    }

    func updateLocation() async throws -> Location2D? {
        print("LocationManager.updateLocation")
        let userLocation = try await swiftLocation.requestLocation()
        return userLocation.location?.coordinate;
    }
}
