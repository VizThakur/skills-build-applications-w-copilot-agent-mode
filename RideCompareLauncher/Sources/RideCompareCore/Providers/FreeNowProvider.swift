import Foundation

/// FREE NOW integration — currently fallback-only.
///
/// As of this project's research (see the README's "Provider limitations"
/// section), FREE NOW (free-now.com, formerly mytaxi, now operating as
/// "Freenow by Lyft" following Lyft's 2025 acquisition) does not publish an
/// official, documented consumer deep-link format for pre-filling a pickup
/// and destination from a third-party app. FREE NOW's public developer
/// resources describe B2B taxi-dispatch and business-travel API
/// integrations, not a URL scheme for arbitrary apps to launch a specific
/// trip. Because FREE NOW is now Lyft-affiliated, it's tempting to assume
/// Lyft's own documented rider deep-link scheme (`lyft://`) would work here
/// — it should not be assumed to: the FREE NOW app is a distinct product
/// from Lyft's US rider app and there is no confirmation it shares Lyft's
/// deep-link handling.
///
/// Per this project's rules, we do not reverse engineer or guess at an
/// undocumented URL format, and we do not scrape the FREE NOW app.
/// `buildRideURL` therefore always returns `nil`, and the app falls back to
/// FREE NOW's App Store listing (`appStoreFallbackURL`) or its website
/// (`websiteFallbackURL`).
///
/// If FREE NOW documents an official deep-link API in the future, only this
/// file needs to change: everything else in the app depends on the
/// `RideProvider` protocol, not on FREE NOW specifically, and the Uber/Bolt
/// flows continue to work unaffected either way.
public struct FreeNowProvider: RideProvider {
    public let name = "FREE NOW"
    public let identifier = "freenow"

    /// No FREE NOW URL scheme is documented or reliably confirmed, so unlike
    /// `BoltProvider` this is left `nil` rather than guessed — the app
    /// simply offers the App Store / website fallback directly.
    public let queryableURLScheme: String? = nil

    public let websiteFallbackURL: URL? = URL(string: "https://www.free-now.com/")
    public let appStoreFallbackURL: URL? = URL(string: "https://apps.apple.com/app/id357852748")

    public init() {}

    public func buildRideURL(pickup: RideLocation, destination: RideLocation) -> URL? {
        nil
    }
}
