import Foundation

/// A single price/ETA estimate from a ride provider.
///
/// **Nothing in this MVP ever constructs a `RideQuote`.** The type exists so
/// a *future* `RideQuoteProvider` implementation — backed by an official,
/// authorized pricing API or SDK from Uber, Bolt, or FREE NOW — has a stable,
/// provider-agnostic model to return, and so UI that eventually renders
/// quotes can be built and designed against a real type today.
///
/// Never populate `estimatedPrice` with an invented, guessed, scraped, or
/// reverse-engineered number. If a legitimate price isn't available, leave
/// it `nil` and let the UI show "price unavailable" rather than a fake
/// figure.
public struct RideQuote: Identifiable, Equatable, Sendable {
    public var id: String {
        "\(provider)-\(productName)-\(retrievedAt.timeIntervalSince1970)"
    }

    /// The `RideProvider.identifier` this quote came from, e.g. `"uber"`.
    public let provider: String

    /// The provider's product name, e.g. "UberX" or "Bolt Comfort".
    public let productName: String

    /// `nil` when no legitimate price is available — never a placeholder or estimate.
    public let estimatedPrice: Decimal?

    /// ISO 4217 currency code, e.g. "EUR". `nil` alongside `estimatedPrice` when unset.
    public let currency: String?

    /// Estimated time, in seconds, until a driver could arrive for pickup.
    public let estimatedPickupTime: TimeInterval?

    public let retrievedAt: Date

    public init(
        provider: String,
        productName: String,
        estimatedPrice: Decimal? = nil,
        currency: String? = nil,
        estimatedPickupTime: TimeInterval? = nil,
        retrievedAt: Date = Date()
    ) {
        self.provider = provider
        self.productName = productName
        self.estimatedPrice = estimatedPrice
        self.currency = currency
        self.estimatedPickupTime = estimatedPickupTime
        self.retrievedAt = retrievedAt
    }
}
