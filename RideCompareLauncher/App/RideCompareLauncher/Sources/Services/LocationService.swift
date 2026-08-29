import CoreLocation
import Observation

/// The rider's pickup location, as far as the rest of the app is concerned.
///
/// Every case here is a legitimate, expected state the UI must render —
/// there is no "impossible" case, and `LocationService` never lets a denied
/// or unavailable location surface as a crash. When location isn't
/// available, `HomeView` lets the user fall back to searching for their
/// pickup location manually, using the same Places Autocomplete flow as the
/// destination search.
enum PickupLocationState: Equatable {
    /// We haven't asked the user for permission yet.
    case notDetermined
    /// Permission was requested (or already granted) and we're waiting on a fix.
    case loading
    /// We have a current location to use as pickup.
    case available(CLLocationCoordinate2D)
    /// The user denied permission. Not fatal — they can search manually.
    case denied
    /// Location is restricted by parental controls / MDM. Not fatal.
    case restricted
    /// Permission is granted but a location couldn't be obtained (e.g. no
    /// GPS signal, Location Services off system-wide, airplane mode).
    case unavailable(reason: String)
}

/// Thin, `CLLocationManager`-backed service exposing an `@Observable` state
/// property that SwiftUI views can read directly.
///
/// This is the *only* file in the app that imports CoreLocation — views and
/// view models work with `PickupLocationState` and `CLLocationCoordinate2D`
/// only, via this service, mirroring the separation the app keeps between
/// Google Places and the rest of the app. Because `state` is `@Observable`,
/// `HomeViewModel` doesn't poll or manually sync it: any SwiftUI view (or
/// computed property on another `@Observable` type) that reads
/// `locationService.state` re-evaluates automatically whenever it changes,
/// including on permission grant/deny, on a successful fix, and on failure.
@MainActor
@Observable
final class LocationService: NSObject {
    private(set) var state: PickupLocationState = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Requests "when in use" permission if needed, and requests a single
    /// location fix once authorized. Safe to call repeatedly (e.g. on
    /// appear, or from a "retry" button) — it never throws and never
    /// crashes regardless of the user's permission choice.
    func requestCurrentLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            state = .loading
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            guard CLLocationManager.locationServicesEnabled() else {
                state = .unavailable(reason: "Location Services is turned off on this device.")
                return
            }
            state = .loading
            manager.requestLocation()

        case .denied:
            state = .denied

        case .restricted:
            state = .restricted

        @unknown default:
            state = .unavailable(reason: "Location authorization is in an unrecognized state.")
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                // Permission just became available (either the user granted
                // it just now, or it was already granted before this service
                // was created) — go ahead and request a fix.
                self.state = .loading
                manager.requestLocation()
            case .denied:
                self.state = .denied
            case .restricted:
                self.state = .restricted
            case .notDetermined:
                self.state = .notDetermined
            @unknown default:
                self.state = .unavailable(reason: "Location authorization is in an unrecognized state.")
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.state = .available(coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError, clError.code == .denied {
                self.state = .denied
            } else {
                self.state = .unavailable(reason: error.localizedDescription)
            }
        }
    }
}
