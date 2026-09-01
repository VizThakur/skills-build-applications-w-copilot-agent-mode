import Foundation

/// The single place that knows which ride providers this app offers.
///
/// Views ask `RideProviderService` for the list of providers rather than
/// constructing `UberProvider()`, `BoltProvider()`, etc. themselves, so
/// adding, removing, or reordering providers is a one-line change here
/// instead of a change scattered across the UI layer.
public struct RideProviderService: Sendable {
    public let providers: [RideProvider]

    public init(providers: [RideProvider]) {
        self.providers = providers
    }

    /// The default provider set: Uber, Bolt, then FREE NOW.
    ///
    /// - Parameter uberClientID: Optional Uber developer Client ID, forwarded
    ///   to `UberProvider`. See `UberProvider` for details.
    public static func standard(uberClientID: String? = nil) -> RideProviderService {
        RideProviderService(providers: [
            UberProvider(clientID: uberClientID),
            BoltProvider(),
            FreeNowProvider(),
        ])
    }

    /// Builds a ride-request URL for a given provider, keyed by
    /// `RideProvider.identifier`. Returns `nil` if the identifier is unknown
    /// or the provider has no deep link available for this trip.
    public func rideURL(providerIdentifier: String, pickup: RideLocation, destination: RideLocation) -> URL? {
        providers.first { $0.identifier == providerIdentifier }?.buildRideURL(pickup: pickup, destination: destination)
    }
}
