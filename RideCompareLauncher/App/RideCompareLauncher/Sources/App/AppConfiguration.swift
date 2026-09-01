import Foundation

/// Reads build-time configuration (API keys, client IDs) out of the app's
/// `Info.plist` rather than hard-coding it into source.
///
/// The actual secret values live in `Configuration/Secrets.xcconfig`, a file
/// that is **not** committed to source control (see `.gitignore` and the
/// project README's "Configure your Google API key" section). Xcode
/// substitutes the `GOOGLE_PLACES_API_KEY` / `UBER_CLIENT_ID` build settings
/// into `Info.plist` at build time via `$(GOOGLE_PLACES_API_KEY)` style
/// placeholders, and this type reads the resulting values back out of the
/// compiled bundle at runtime.
///
/// If a key is missing (a fresh checkout before `Secrets.xcconfig` has been
/// created), every property here safely returns `nil`/`false` instead of
/// crashing — the app degrades to its "Places isn't configured" error state
/// rather than force-unwrapping a missing key.
enum AppConfiguration {
    /// The Google Places API key, or `nil` if it hasn't been configured yet.
    static var googlePlacesAPIKey: String? {
        nonPlaceholderInfoPlistString(forKey: "GooglePlacesAPIKey")
    }

    /// Whether Places Autocomplete can actually be used right now.
    static var isPlacesConfigured: Bool {
        googlePlacesAPIKey != nil
    }

    /// Optional Uber developer Client ID (see `UberProvider`). Uber's deep
    /// link works without this, so a missing value is not an error state.
    static var uberClientID: String? {
        nonPlaceholderInfoPlistString(forKey: "UberClientID")
    }

    /// Looks up a string in the bundle's `Info.plist`, treating an empty
    /// string or an un-substituted `$(VAR_NAME)` build-setting placeholder
    /// (what you get when the xcconfig variable was never defined) the same
    /// as "not configured".
    private static func nonPlaceholderInfoPlistString(forKey key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        return resolvedValue(from: value)
    }

    /// The pure "is this a real value or an empty/placeholder string" check,
    /// factored out of `nonPlaceholderInfoPlistString` so it can be unit
    /// tested without needing to fake out `Bundle.main`.
    static func resolvedValue(from rawInfoPlistString: String) -> String? {
        let trimmed = rawInfoPlistString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else { return nil }
        return trimmed
    }
}
