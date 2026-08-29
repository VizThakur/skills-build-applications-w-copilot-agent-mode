import Foundation

/// Bolt integration — currently fallback-only.
///
/// As of this project's research (see the README's "Provider limitations"
/// section), Bolt (bolt.eu) does not publish an official, documented
/// consumer deep-link format that lets a third-party app open Bolt with a
/// specific pickup and destination pre-filled. Bolt offers partner/B2B
/// integrations (e.g. a business API for corporate travel), but nothing
/// equivalent to Uber's public Ride Request Deeplink for arbitrary iOS apps.
///
/// Per this project's rules, we do not reverse engineer or guess at an
/// undocumented `bolt://` parameter format, and we do not scrape the Bolt
/// app. `buildRideURL` therefore always returns `nil`, and the app falls
/// back to Bolt's App Store listing (via `appStoreFallbackURL`) or its
/// website (`websiteFallbackURL`) so the user can still reach Bolt in one or
/// two taps and re-enter the destination there.
///
/// If Bolt documents an official deep-link API in the future, only this file
/// needs to change: everything else in the app depends on the `RideProvider`
/// protocol, not on Bolt specifically, and the Uber/FREE NOW flows continue
/// to work unaffected either way.
public struct BoltProvider: RideProvider {
    public let name = "Bolt"
    public let identifier = "bolt"

    /// Bolt's app has been commonly observed to register a `bolt://` URL
    /// scheme, but Bolt does not officially document this, so it is treated
    /// only as an installation check (via `canOpenURL`) to decide whether to
    /// offer an "Open Bolt" affordance versus going straight to the App
    /// Store — never as a place to pass along a guessed trip payload. If
    /// this probe is ever unreliable it simply falls through to the App
    /// Store link, so getting it wrong has no user-facing failure mode.
    public let queryableURLScheme: String? = "bolt"

    public let websiteFallbackURL: URL? = URL(string: "https://bolt.eu/en/")
    public let appStoreFallbackURL: URL? = URL(string: "https://apps.apple.com/app/id675033630")

    public init() {}

    public func buildRideURL(pickup: RideLocation, destination: RideLocation) -> URL? {
        nil
    }
}
