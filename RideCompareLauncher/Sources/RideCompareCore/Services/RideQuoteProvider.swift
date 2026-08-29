import Foundation

/// Future extension point for live price comparison.
///
/// This MVP is a **launcher**, not a price aggregator: it never calls this
/// protocol, and no type in this package conforms to it. It exists purely so
/// that once a legitimate, authorized pricing integration is available for a
/// provider (an official partner API, for example), it can be added as a
/// `RideQuoteProvider` conformance without touching the deep-link code in
/// `Providers/`, `RideProviderService`, or any existing view model.
///
/// Deep-linking (`RideProvider`) and quote retrieval (`RideQuoteProvider`)
/// are intentionally separate protocols so a provider can support one, the
/// other, both, or neither.
public protocol RideQuoteProvider: Sendable {
    /// Fetches live quotes for a trip from `pickup` to `destination`.
    ///
    /// Implementations must only return quotes sourced from an official,
    /// authorized API or SDK — never invented, cached-forever, or scraped
    /// figures. Throw rather than return a guessed value when a real quote
    /// isn't available.
    func getQuotes(pickup: RideLocation, destination: RideLocation) async throws -> [RideQuote]
}
