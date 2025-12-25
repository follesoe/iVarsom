import Combine
import CoreLocation
import SwiftLocation

/** A 2D coordinate type alias for location coordinates */
public typealias Location2D = CLLocationCoordinate2D

/**
 A location manager that provides thread-safe authorization status reading
 and main-actor isolated location operations.
 
 This class separates concerns to support both main app usage and widget extensions:
 - **Thread-safe authorization reading**: Can be safely accessed from any thread,
   including widget extensions that run on background threads
 - **Main-actor isolated operations**: Location operations (requesting permission,
   updating location) are isolated to the main actor and automatically hop to
   the main thread when called from non-isolated contexts
 
 ## Usage
 
 ```swift
 let locationManager = LocationManager()
 
 // Thread-safe: Can be called from any context
 if locationManager.isAuthorized {
     // Main-actor isolated: Automatically hops to main actor
     let location = try await locationManager.updateLocation()
 }
 ```
 
 ## CoreLocation Warnings
 
 You may see runtime warnings from CoreLocation about UI unresponsiveness when
 location operations are performed. These warnings originate from the SwiftLocation
 library when it accesses `CLLocationManager.authorizationStatus` during initialization.
 These are informational warnings and don't indicate actual UI blocking - the async/await
 pattern ensures operations don't block the UI thread. The warnings are minimized by
 caching the Location instance so it only appears once during first initialization.
 */
final class LocationManager: NSObject {
    // Thread-safe: CLLocationManager authorization properties are safe to read from any thread
    private let locationManager: CLLocationManager
    
    // Cached Location instance to avoid recreating it (which would trigger warnings each time).
    // This is only accessed from `@MainActor` methods, so it's safe to use `nonisolated(unsafe)`.
    nonisolated(unsafe) private var _cachedSwiftLocation: Location?
    
    /**
     Creates a new LocationManager instance.
     
     The CLLocationManager is initialized immediately, but location operations
     are deferred until explicitly requested via `requestPermission()` or `updateLocation()`.
     */
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
    }
    
    /**
     Gets or creates a SwiftLocation instance on the MainActor.
     
     Reusing the instance prevents CoreLocation warnings from appearing on every call.
     The first call will create the instance (and may trigger a warning once), subsequent
     calls reuse the cached instance.
     
     - Returns: A cached or newly created `Location` instance from SwiftLocation
     */
    @MainActor
    private func getSwiftLocation() -> Location {
        if let cached = _cachedSwiftLocation {
            return cached
        }
        // Create once - this will trigger the warning once, but subsequent calls reuse the instance
        // The warning occurs here during first initialization when SwiftLocation accesses
        // CLLocationManager.authorizationStatus. Subsequent calls reuse the cached instance.
        let location = Location(locationManager: locationManager)
        _cachedSwiftLocation = location
        return location
    }
    
    /**
     Checks if location services are authorized for widget updates.
     
     This property is thread-safe and can be accessed from any context, including
     widget extensions that run on background threads.
     
     - Returns: `true` if location services are authorized for widget updates, `false` otherwise.
       On watchOS, this returns the same value as `isAuthorized`.
     */
    public var isAuthorizedForWidgetUpdates: Bool {
#if os(watchOS)
        return isAuthorized
#else
        return locationManager.isAuthorizedForWidgetUpdates
#endif
    }
    
    /**
     Checks if location services are currently authorized.
     
     This property is thread-safe and can be accessed from any context, including
     widget extensions that run on background threads.
     
     - Returns: `true` if location services are authorized (either "always" or "when in use"),
       `false` if authorization is not determined, restricted, or denied.
     */
    public var isAuthorized: Bool {
        return hasPermission(status: locationManager.authorizationStatus)
    }
    
    /**
     Determines if a given authorization status represents an authorized state.
     
     - Parameter status: The `CLAuthorizationStatus` to check
     - Returns: `true` if the status is `.authorizedAlways` or `.authorizedWhenInUse`,
       `false` otherwise
     */
    private func hasPermission(status: CLAuthorizationStatus) -> Bool {
        switch status {
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        @unknown default:
            return false
        }
    }
    
    /**
     Requests location permission from the user.
     
     This method is main-actor isolated and will automatically hop to the main actor
     when called from non-isolated contexts (such as widget extensions). It requests
     "when in use" location permission.
     
     ## Example
     
     ```swift
     do {
         let authorized = try await locationManager.requestPermission()
         if authorized {
             // User granted permission
         }
     } catch {
         // Handle error
     }
     ```
     
     - Returns: `true` if permission was granted (either "always" or "when in use"),
       `false` if permission was denied
     - Throws: An error if the permission request fails or if the Info.plist is not
       properly configured for location permissions
     
     ## Note
     
     You may see a runtime warning from CoreLocation about UI unresponsiveness. This
     is informational and doesn't indicate actual blocking - the async/await pattern
     ensures the operation doesn't block the UI thread.
     */
    @MainActor
    func requestPermission() async throws -> Bool {
        print("LocationManager.requestPermission")
        // Yield to allow other work on the main thread before starting location operations
        await Task.yield()
        
        // Reuse cached Location instance to avoid triggering the warning repeatedly
        // The first call will create it (and trigger the warning once), subsequent
        // calls reuse the cached instance
        // Note: nonisolated(unsafe) is needed because Location from SwiftLocation
        // is not Sendable, but we only use it within this MainActor context
        nonisolated(unsafe) let location = getSwiftLocation()
        let permission = try await location.requestPermission(.whenInUse)
        return hasPermission(status: permission)
    }
    
    /**
     Updates the current location.
     
     This method is main-actor isolated and will automatically hop to the main actor
     when called from non-isolated contexts (such as widget extensions). It requests
     the current location from the device.
     
     ## Example
     
     ```swift
     do {
         if let coordinate = try await locationManager.updateLocation() {
             // Use the coordinate
             print("Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")
         } else {
             // Location unavailable
         }
     } catch {
         // Handle error
     }
     ```
     
     - Returns: A `Location2D` (CLLocationCoordinate2D) containing the current location,
       or `nil` if the location is unavailable or permission was denied
     - Throws: An error if the location request fails, permission is not granted,
       or location services are disabled
     
     ## Note
     
     You may see a runtime warning from CoreLocation about UI unresponsiveness. This
     is informational and doesn't indicate actual blocking - the async/await pattern
     ensures the operation doesn't block the UI thread.
     */
    @MainActor
    func updateLocation() async throws -> Location2D? {
        print("LocationManager.updateLocation")
        // Yield to allow other work on the main thread before starting location operations
        await Task.yield()
        
        // Reuse cached Location instance to avoid triggering the warning repeatedly
        // The first call will create it (and trigger the warning once), subsequent
        // calls reuse the cached instance
        // Note: nonisolated(unsafe) is needed because Location from SwiftLocation
        // is not Sendable, but we only use it within this MainActor context
        nonisolated(unsafe) let location = getSwiftLocation()
        let userLocation = try await location.requestLocation()
        return userLocation.location?.coordinate
    }
}
