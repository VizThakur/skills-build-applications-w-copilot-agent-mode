import Foundation

/// A pickup or destination location used throughout the app.
///
/// This is the app's own internal representation of "a place" — it is what
/// views, view models, and ride providers work with. Nothing outside the
/// Google Places integration layer ever touches a Google-specific type
/// (`GMSPlace`, `Place`, autocomplete predictions, etc.); a selected result
/// is converted into a `RideLocation` immediately, and everything downstream
/// depends only on this struct. That keeps the app free to change or drop
/// the Places SDK later without rewriting providers, view models, or views.
public struct RideLocation: Identifiable, Equatable, Hashable, Sendable {
    /// A stable identity for use in SwiftUI lists: the Google Place ID when
    /// one is known, otherwise the coordinate pair.
    public var id: String {
        placeID ?? "\(latitude),\(longitude)"
    }

    /// A short, human-readable name, e.g. "Kraków Airport" or "Current Location".
    public let name: String

    /// A longer, formatted address, e.g. "Balice, 32-083 Kraków, Poland".
    /// `nil` when no address is available (for example, a raw device
    /// coordinate that hasn't been reverse-geocoded).
    public let address: String?

    public let latitude: Double
    public let longitude: Double

    /// The originating Google Place ID, when this location came from Places
    /// Autocomplete. `nil` for the device's current location or a manually
    /// entered coordinate.
    public let placeID: String?

    public init(
        name: String,
        address: String? = nil,
        latitude: Double,
        longitude: Double,
        placeID: String? = nil
    ) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.placeID = placeID
    }
}

public extension RideLocation {
    /// The label used when this location is the rider's current GPS position
    /// rather than a searched destination.
    static let currentLocationName = "Current Location"

    /// A one-line description suitable for display or for logging (never for
    /// analytics — the MVP does not send location data anywhere it doesn't
    /// have to).
    var displaySubtitle: String? {
        address
    }
}
