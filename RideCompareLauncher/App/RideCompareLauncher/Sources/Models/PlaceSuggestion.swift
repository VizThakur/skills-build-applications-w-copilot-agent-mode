import Foundation

/// A single Places Autocomplete suggestion, already stripped down to what
/// the UI needs.
///
/// Like `RideLocation`, this is the app's own type rather than a Google SDK
/// type — `DestinationSearchView` and `DestinationSearchViewModel` never see
/// a Google `AutocompleteSuggestion` or `PlacePrediction` directly. Only
/// `PlacesService` (specifically `GooglePlacesService`) knows about the
/// Google Places SDK.
struct PlaceSuggestion: Identifiable, Hashable, Sendable {
    /// The underlying Google Place ID, used to fetch full place details once
    /// selected, and to keep the suggestion uniquely identifiable in a list.
    let id: String
    /// The main line, e.g. "Kraków Airport".
    let primaryText: String
    /// The secondary line, e.g. "Balice, Kraków, Poland". `nil` when Google
    /// doesn't provide one.
    let secondaryText: String?
}
