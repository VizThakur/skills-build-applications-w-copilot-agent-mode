import GooglePlaces
import SwiftUI

@main
struct RideCompareLauncherApp: App {
    init() {
        // Registers the Google Places API key once at launch. `GooglePlacesSwift`'s
        // `PlacesClient.shared` (used by `GooglePlacesService`) relies on this same
        // registration. If no key has been configured yet (a fresh checkout before
        // `Configuration/Secrets.xcconfig` has been created — see the README), this
        // is skipped entirely: `AppConfiguration.isPlacesConfigured` will be `false`
        // and the destination search screen shows a clear "not set up yet" state
        // instead of crashing or silently failing later.
        if let apiKey = AppConfiguration.googlePlacesAPIKey {
            GMSPlacesClient.provideAPIKey(apiKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
