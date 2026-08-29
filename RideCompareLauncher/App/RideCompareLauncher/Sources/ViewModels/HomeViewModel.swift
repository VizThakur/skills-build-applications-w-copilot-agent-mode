import CoreLocation
import Observation
import RideCompareCore
import UIKit

/// Drives `HomeView`: owns the pickup location (device GPS or a manual
/// override), the selected destination, the list of ride providers, and the
/// "open this provider" flow with its fallback handling.
@MainActor
@Observable
final class HomeViewModel {
    let locationService: LocationService
    let providerService: RideProviderService

    /// The destination the user selected via `DestinationSearchView`.
    private(set) var destination: RideLocation?

    /// Set when the user chooses to enter a pickup location manually instead
    /// of using their GPS position (see `PickupLocationState`). Takes
    /// priority over `locationService.state` whenever it's set.
    private var manualPickup: RideLocation?

    /// Set after a failed attempt to open a provider's app, for the view to
    /// surface as an alert. Cleared automatically the next time the user
    /// taps a provider.
    var openProviderErrorMessage: String?

    init(
        locationService: LocationService = LocationService(),
        providerService: RideProviderService = .standard(uberClientID: AppConfiguration.uberClientID)
    ) {
        self.locationService = locationService
        self.providerService = providerService
    }

    // MARK: - Pickup

    /// The current pickup location, or `nil` while it's still loading or
    /// unavailable. Computed (not stored) so it stays in sync with
    /// `locationService.state` automatically wherever it's read from a
    /// SwiftUI view body.
    var pickup: RideLocation? {
        if let manualPickup { return manualPickup }
        guard case .available(let coordinate) = locationService.state else { return nil }
        return RideLocation(
            name: RideLocation.currentLocationName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    var isPickupLoading: Bool {
        guard manualPickup == nil else { return false }
        switch locationService.state {
        case .loading, .notDetermined: return true
        default: return false
        }
    }

    /// A user-facing explanation for why pickup isn't available yet, or
    /// `nil` when it either is available or is still loading.
    var pickupErrorMessage: String? {
        guard manualPickup == nil else { return nil }
        switch locationService.state {
        case .denied:
            return "Location access is disabled. You can still enter your pickup location manually."
        case .restricted:
            return "Location access is restricted on this device. You can still enter your pickup location manually."
        case .unavailable(let reason):
            return reason
        case .available, .loading, .notDetermined:
            return nil
        }
    }

    func requestCurrentLocation() {
        locationService.requestCurrentLocation()
    }

    func setManualPickup(_ location: RideLocation) {
        manualPickup = location
    }

    func useCurrentLocationForPickup() {
        manualPickup = nil
        locationService.requestCurrentLocation()
    }

    // MARK: - Destination

    func setDestination(_ location: RideLocation) {
        destination = location
    }

    func clearDestination() {
        destination = nil
    }

    // MARK: - Opening a provider

    var canShowProviders: Bool { pickup != nil && destination != nil }

    /// Best-effort "is this provider's app installed?" check, used only to
    /// show an informational "Not installed" hint on `ProviderButtonView` —
    /// never to decide whether the button is tappable, since every provider
    /// still has a working fallback either way. Providers with no known
    /// queryable scheme (`queryableURLScheme == nil`, e.g. FREE NOW) report
    /// `true` rather than guessing.
    func isProviderAppInstalled(_ provider: RideProvider) -> Bool {
        guard let scheme = provider.queryableURLScheme, let url = URL(string: "\(scheme)://") else {
            return true
        }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Attempts to open `provider` for the current pickup/destination.
    ///
    /// Order of attempts, matching the task's fallback requirements:
    /// 1. The provider's own ride-request deep link, if it has one.
    /// 2. Its App Store listing, if opening the deep link fails (app not installed).
    /// 3. Its website, if there's no App Store listing or that also fails.
    /// 4. A user-facing "Unable to open <provider>" message, if nothing else worked.
    func openProvider(_ provider: RideProvider) {
        openProviderErrorMessage = nil
        guard let pickup, let destination else { return }

        if let url = provider.buildRideURL(pickup: pickup, destination: destination) {
            open(url) { [weak self] success in
                guard let self, !success else { return }
                self.openFallback(for: provider)
            }
        } else {
            openFallback(for: provider)
        }
    }

    private func openFallback(for provider: RideProvider) {
        if let storeURL = provider.appStoreFallbackURL {
            open(storeURL) { [weak self] success in
                guard let self, !success else { return }
                if let websiteURL = provider.websiteFallbackURL {
                    self.open(websiteURL) { [weak self] success in
                        guard let self, !success else { return }
                        self.reportUnableToOpen(provider)
                    }
                } else {
                    self.reportUnableToOpen(provider)
                }
            }
        } else if let websiteURL = provider.websiteFallbackURL {
            open(websiteURL) { [weak self] success in
                guard let self, !success else { return }
                self.reportUnableToOpen(provider)
            }
        } else {
            reportUnableToOpen(provider)
        }
    }

    private func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        UIApplication.shared.open(url, options: [:]) { success in
            Task { @MainActor in completion(success) }
        }
    }

    private func reportUnableToOpen(_ provider: RideProvider) {
        openProviderErrorMessage = "Unable to open \(provider.name). Please make sure \(provider.name) is installed."
    }
}
