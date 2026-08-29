import Foundation

/// Abstracts "open this trip in a ride-hailing app" behind a single
/// interface, so the UI never constructs a provider URL itself.
///
/// Each ride-hailing app gets its own `RideProvider` conformance
/// (`UberProvider`, `BoltProvider`, `FreeNowProvider`). Provider integrations
/// change independently of one another and of this app's own release
/// schedule — a documented deep-link parameter can be added, changed, or
/// removed by any of these companies at any time — so all provider-specific
/// knowledge is isolated to one file per provider under `Providers/`.
public protocol RideProvider: Sendable {
    /// Display name, e.g. "Uber".
    var name: String { get }

    /// Stable, lowercase identifier used for logging, analytics-free
    /// diagnostics, and `RideQuote.provider` matching, e.g. `"uber"`.
    var identifier: String { get }

    /// The custom URL scheme this provider's app is known to register (for
    /// example `"uber"` for `uber://`), used only with
    /// `UIApplication.canOpenURL` to check whether the app is installed.
    /// `nil` when the provider has no known scheme to probe, or when this
    /// project has deliberately chosen not to encode one (see `BoltProvider`
    /// and `FreeNowProvider`).
    var queryableURLScheme: String? { get }

    /// Where to send the user when the provider's app isn't installed and no
    /// richer deep link is available. Should point at the App Store listing.
    var appStoreFallbackURL: URL? { get }

    /// A last-resort fallback — the provider's own website — used when even
    /// an App Store link isn't appropriate or available.
    var websiteFallbackURL: URL? { get }

    /// Builds a URL that, when opened, requests a trip from `pickup` to
    /// `destination` in this provider's app.
    ///
    /// Returns `nil` when this provider has no officially documented way to
    /// pre-fill a trip — callers must fall back to `appStoreFallbackURL` or
    /// `websiteFallbackURL` rather than treating `nil` as an error. This
    /// method never scrapes, reverse engineers, or guesses at an undocumented
    /// URL format.
    func buildRideURL(pickup: RideLocation, destination: RideLocation) -> URL?
}

public extension RideProvider {
    var queryableURLScheme: String? { nil }
    var appStoreFallbackURL: URL? { nil }
    var websiteFallbackURL: URL? { nil }
}
