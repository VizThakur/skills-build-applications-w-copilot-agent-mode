import RideCompareCore

/// Abstracts "search for a destination" behind a protocol so
/// `DestinationSearchViewModel` doesn't depend on the Google Places SDK
/// directly, and so it can be unit tested against a fake implementation
/// without hitting the network or requiring an API key.
///
/// `GooglePlacesService` is the only production conformance, using the
/// Places SDK for iOS (New) / Places Swift SDK.
@MainActor
protocol PlacesSearching {
    /// Starts a new Autocomplete session. Call this once when the user opens
    /// the destination search screen (or clears it and starts over) — not on
    /// every keystroke — so a whole search-to-selection flow is billed by
    /// Google as a single session, per Google's session token guidance.
    func startNewSession()

    /// Returns live autocomplete suggestions for the given (already
    /// debounced) query. Returns an empty array for an empty query rather
    /// than making a request.
    func autocomplete(query: String) async throws -> [PlaceSuggestion]

    /// Resolves a selected suggestion into a full `RideLocation`, fetching
    /// only the fields the app actually needs (coordinate, formatted
    /// address, display name) and closing out the current Autocomplete
    /// session.
    func resolveLocation(for suggestion: PlaceSuggestion) async throws -> RideLocation
}

/// Errors surfaced by `PlacesSearching` conformances, kept independent of
/// whatever error type the underlying SDK throws so the UI layer has one
/// stable set of cases to switch over.
enum PlacesServiceError: Error, Equatable {
    /// The Google Places API key hasn't been configured (see `AppConfiguration`).
    case notConfigured
    case autocompleteFailed(String)
    case detailsFailed(String)

    var userFacingMessage: String {
        switch self {
        case .notConfigured:
            return "Destination search isn't set up yet. Add a Google Places API key to enable it."
        case .autocompleteFailed, .detailsFailed:
            return "We couldn't search for that location. Please check your connection and try again."
        }
    }
}
