import Foundation

/// Deep-links into Uber using Uber's officially documented Ride Request
/// deep-linking mechanism.
///
/// Reference: Uber Developers, "Introduction to Deep Links" and the Ride
/// Request Deeplink tutorial
/// (`developer.uber.com/docs/riders/ride-requests/tutorials/deep-links`).
/// Verified against Uber's current documentation as of this project's
/// implementation date — reconfirm before shipping, since Uber can change
/// documented parameters.
///
/// Uber documents two equivalent entry points, both using the `setPickup`
/// action:
///  - a **universal link**, `https://m.uber.com/ul/`, which opens the app
///    when installed and otherwise falls back to Uber's mobile web / App
///    Store experience automatically — no separate fallback handling needed;
///  - a **custom URL scheme**, `uber://`, which only resolves when Uber is
///    installed.
///
/// This provider builds the universal link, since it degrades gracefully on
/// its own and matches Uber's own recommendation to "always implement
/// universal links so riders get the best Uber experience on their device."
///
/// Documented query parameters used: `action`, `client_id`,
/// `pickup[latitude]`, `pickup[longitude]`, `pickup[nickname]`,
/// `pickup[formatted_address]`, `dropoff[latitude]`, `dropoff[longitude]`,
/// `dropoff[nickname]`, `dropoff[formatted_address]`. Uber's docs require
/// latitude/longitude plus at least one of `nickname` or
/// `formatted_address` for each location; this implementation always
/// supplies both when available, as Uber recommends supplying as many
/// parameters as possible for the best in-app context.
///
/// This provider never requests or displays a fare estimate — Uber's deep
/// link mechanism doesn't expose pricing, and this app doesn't scrape or
/// reverse engineer the Uber app to obtain one.
public struct UberProvider: RideProvider {
    public let name = "Uber"
    public let identifier = "uber"
    public let queryableURLScheme: String? = "uber"
    public let websiteFallbackURL: URL? = URL(string: "https://m.uber.com/")
    public let appStoreFallbackURL: URL? = URL(string: "https://apps.apple.com/app/id368677368")

    /// Your Uber developer app's Client ID, from developer.uber.com/dashboard.
    /// Optional: the deep link itself works without it, but Uber recommends
    /// including it so the request can be attributed to your app. Pass `nil`
    /// (the default) to omit it entirely.
    private let clientID: String?

    public init(clientID: String? = nil) {
        self.clientID = clientID
    }

    public func buildRideURL(pickup: RideLocation, destination: RideLocation) -> URL? {
        var components = URLComponents(string: "https://m.uber.com/ul/")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "action", value: "setPickup"),
        ]

        if let clientID, !clientID.isEmpty {
            items.append(URLQueryItem(name: "client_id", value: clientID))
        }

        items.append(contentsOf: queryItems(prefix: "pickup", location: pickup))
        items.append(contentsOf: queryItems(prefix: "dropoff", location: destination))

        components?.queryItems = items
        return components?.url
    }

    private func queryItems(prefix: String, location: RideLocation) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "\(prefix)[latitude]", value: String(location.latitude)),
            URLQueryItem(name: "\(prefix)[longitude]", value: String(location.longitude)),
            URLQueryItem(name: "\(prefix)[nickname]", value: location.name),
        ]
        if let address = location.address, !address.isEmpty {
            items.append(URLQueryItem(name: "\(prefix)[formatted_address]", value: address))
        }
        return items
    }
}
