import CoreLocation
import GooglePlacesSwift
import RideCompareCore

/// Production `PlacesSearching` conformance backed by the **Places SDK for
/// iOS (New)** Swift API (`GooglePlacesSwift`, distributed via
/// `https://github.com/googlemaps/ios-places-sdk`).
///
/// ⚠️ **Verify against your installed SDK version before relying on this file.**
/// `GooglePlacesSwift` is a young, sub-1.0 Swift API (see the project README's
/// "Google Places SDK version" note) and Google has changed method and type
/// names across releases. This implementation targets the documented shape
/// of `PlacesClient.fetchAutocompleteSuggestions(with:)` and
/// `PlacesClient.fetchPlace(with:)` as of this project's implementation
/// date. If Xcode reports a missing symbol here after adding the package,
/// this is the one file that needs updating — nothing else in the app
/// depends on Google's types directly (see `PlacesSearching`).
///
/// This service only ever requests the specific `PlaceProperty` values the
/// app actually renders or needs for a deep link (`coordinate`,
/// `formattedAddress`, `displayName`) — never the full place payload — to
/// avoid unnecessary Places API cost, per Google's field-masking guidance.
@MainActor
final class GooglePlacesService: PlacesSearching {
    private let placesClient = PlacesClient.shared
    private var sessionToken: AutocompleteSessionToken?

    func startNewSession() {
        sessionToken = AutocompleteSessionToken()
    }

    private func currentSessionToken() -> AutocompleteSessionToken {
        if let sessionToken { return sessionToken }
        let token = AutocompleteSessionToken()
        sessionToken = token
        return token
    }

    func autocomplete(query: String) async throws -> [PlaceSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard AppConfiguration.isPlacesConfigured else { throw PlacesServiceError.notConfigured }

        let request = AutocompleteRequest(query: trimmed, sessionToken: currentSessionToken())
        let result = await placesClient.fetchAutocompleteSuggestions(with: request)

        switch result {
        case .success(let suggestions):
            return suggestions.compactMap { suggestion -> PlaceSuggestion? in
                guard case .place(let placePrediction) = suggestion else { return nil }
                return PlaceSuggestion(
                    id: placePrediction.placeID,
                    primaryText: placePrediction.attributedPrimaryText.string,
                    secondaryText: placePrediction.attributedSecondaryText?.string
                )
            }
        case .failure(let error):
            throw PlacesServiceError.autocompleteFailed(error.localizedDescription)
        }
    }

    func resolveLocation(for suggestion: PlaceSuggestion) async throws -> RideLocation {
        guard AppConfiguration.isPlacesConfigured else { throw PlacesServiceError.notConfigured }

        // Only request the three fields this app actually uses, and close
        // out the Autocomplete session with this Place Details request, per
        // Google's session-token billing guidance.
        let request = FetchPlaceRequest(
            placeID: suggestion.id,
            placeProperties: [.coordinate, .formattedAddress, .displayName],
            sessionToken: currentSessionToken()
        )
        sessionToken = nil

        let result = await placesClient.fetchPlace(with: request)

        switch result {
        case .success(let place):
            // `place.location` is this file's highest-risk line — see the
            // header comment. If Xcode reports no member `location` on
            // `Place`, check the installed GooglePlacesSwift version's
            // reference for the current coordinate property name (it may be
            // `coordinate` instead) and update this one line.
            guard let coordinate = place.location else {
                throw PlacesServiceError.detailsFailed("The selected place has no coordinates.")
            }
            return RideLocation(
                name: place.displayName ?? suggestion.primaryText,
                address: place.formattedAddress ?? suggestion.secondaryText,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                placeID: suggestion.id
            )
        case .failure(let error):
            throw PlacesServiceError.detailsFailed(error.localizedDescription)
        }
    }
}
