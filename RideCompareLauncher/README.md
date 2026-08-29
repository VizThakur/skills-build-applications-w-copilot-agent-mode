# RideCompare — Ride Comparison Launcher (iOS MVP)

RideCompare is a native iOS app that lets you type a destination once — with
live Google Places Autocomplete — and then open that exact trip in **Uber**,
**Bolt**, or **FREE NOW**, using your current location as pickup. It's a
*launcher*, not a price aggregator: it never scrapes, reverse engineers, or
guesses at prices from any of these apps, and it never invents a deep link a
provider hasn't documented.

```
Current Location  →  Kraków Airport  →  Open Uber / Bolt / FREE NOW
                                          (destination pre-filled where the
                                           provider documents how)
```

## Contents

- [Requirements](#requirements)
- [Project structure](#project-structure)
- [Setup](#setup)
- [Configure your Google API key](#configure-your-google-api-key)
- [Running the tests](#running-the-tests)
- [Architecture](#architecture)
- [Provider limitations](#provider-limitations) — read this before assuming Bolt/FREE NOW behave like Uber
- [Privacy](#privacy)
- [Known limitations & next steps](#known-limitations--next-steps)

## Requirements

- Xcode 16.0 or later (for the `PBXFileSystemSynchronizedRootGroup` project
  format and the Places SDK's own minimum toolchain requirement)
- iOS 17.0+ deployment target / simulator or device
- A Google Cloud project with the **Places API (New)** enabled and billing
  configured (see below)
- An Apple Developer account for code signing on a device (the simulator
  doesn't need one)

## Project structure

```
RideCompareLauncher/
├── Package.swift                  Swift package: RideCompareCore
├── Sources/RideCompareCore/       Pure business logic — no SwiftUI/UIKit/
│   ├── Models/                    CoreLocation/Google Places imports here.
│   ├── Providers/                 Testable with a plain `swift test`.
│   ├── Services/
│   └── Support/
├── Tests/RideCompareCoreTests/    Unit tests for RideLocation, RideQuote,
│                                  and — most importantly — every provider's
│                                  deep-link URL construction.
└── App/
    ├── RideCompareLauncher.xcodeproj
    ├── RideCompareLauncher/
    │   ├── Sources/                App/, Models/, Services/, ViewModels/,
    │   │                           Views/ — SwiftUI, CoreLocation, and the
    │   │                           Google Places SDK integration live here.
    │   ├── Resources/              Info.plist, Assets.xcassets
    │   └── Configuration/          Debug/Release .xcconfig + your untracked
    │                               Secrets.xcconfig
    └── RideCompareLauncherTests/   View-model tests using a fake Places
                                    service (no network, no API key needed).
```

`RideCompareCore` is a **local Swift package**, added to the Xcode project as
a package dependency (see `Architecture`). It contains everything that
doesn't need an iOS runtime — most importantly the `RideProvider`
conformances — so the deep-link logic can be verified with a plain
`swift test`, without Xcode, a simulator, or an API key. The Xcode app target
layers SwiftUI, CoreLocation, and the Google Places SDK on top of it.

## Setup

1. **Clone and open the project.**
   ```sh
   open RideCompareLauncher/App/RideCompareLauncher.xcodeproj
   ```
   Xcode resolves both Swift package dependencies automatically: the local
   `RideCompareCore` package (in the parent directory) and the remote
   [Places SDK for iOS](https://github.com/googlemaps/ios-places-sdk)
   package (`GooglePlaces` + `GooglePlacesSwift` products). This requires
   network access on first open.

2. **Create your `Secrets.xcconfig`.**
   ```sh
   cd RideCompareLauncher/App/RideCompareLauncher/Configuration
   cp Secrets.xcconfig.example Secrets.xcconfig
   ```
   Then edit `Secrets.xcconfig` and fill in `GOOGLE_PLACES_API_KEY` (see
   below). `Secrets.xcconfig` is listed in `.gitignore` — **never commit a
   real API key.**

3. **Set your bundle identifier and signing team.** The project ships with a
   placeholder bundle ID (`com.ridecompare.launcher`). In the target's
   *Signing & Capabilities* tab, change it to something under your own Apple
   Developer team and pick that team for automatic signing. (Not required
   to run in the simulator.)

4. **Build and run.** Without any configuration, the app still builds and
   runs — it just shows a clear "destination search isn't set up yet" state
   instead of crashing (see `AppConfiguration.swift`).

The app compiles and runs with no other source changes once steps 2–3 are
done.

## Configure your Google API key

1. In [Google Cloud Console](https://console.cloud.google.com/), create or
   select a project, then enable **Places API (New)** under *APIs & Services
   → Library*. (Billing must be enabled on the project — Google's free
   monthly credit generally covers MVP-scale development traffic; see
   [Places SDK for iOS usage & billing](https://developers.google.com/maps/documentation/places/ios-sdk/usage-and-billing).)
2. Go to *APIs & Services → Credentials* → **Create Credentials → API key**.
3. **Restrict the key** before using it anywhere real:
   - Application restrictions → **iOS apps** → add your app's bundle
     identifier (the one you set in Xcode signing settings).
   - API restrictions → **Restrict key** → select only **Places API (New)**
     (and **Places API** if you also rely on any legacy endpoint — this
     project doesn't).
4. Paste the key into `Secrets.xcconfig` as `GOOGLE_PLACES_API_KEY`.

Autocomplete requests use a Google
[`AutocompleteSessionToken`](https://developers.google.com/maps/documentation/places/ios-sdk/place-autocomplete)
per search — started when `DestinationSearchView` appears, reused across
every keystroke's autocomplete request, and closed out by the Place Details
request when a suggestion is selected — so a whole search is billed as one
session rather than one call per request, per Google's guidance. Only the
`coordinate`, `formattedAddress`, and `displayName` fields are ever
requested for Place Details, to avoid unnecessary API cost.

Optionally, set `UBER_CLIENT_ID` in the same file (from
[developer.uber.com/dashboard](https://developer.uber.com/dashboard)) so
Uber can attribute ride requests to this app. It's not required — Uber's
deep link works without it.

## Running the tests

**Provider / model logic** (no Xcode, no simulator, no API key required):
```sh
cd RideCompareLauncher
swift test
```
This runs `UberProviderTests`, `BoltProviderTests`, `FreeNowProviderTests`,
`RideLocationTests`, `RideProviderServiceTests`, and `DebouncerTests` — most
importantly, the Uber tests assert the exact deep-link URL and query
parameters built for a trip, and the Bolt/FREE NOW tests assert that
`buildRideURL` always returns `nil` (i.e. that nobody has quietly added a
guessed, undocumented URL).

**View models / app-target logic** — open the project in Xcode and press
<kbd>⌘U</kbd>, or:
```sh
xcodebuild test \
  -project RideCompareLauncher/App/RideCompareLauncher.xcodeproj \
  -scheme RideCompareLauncher \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
`DestinationSearchViewModelTests` exercises debouncing, error states, and
session handling against a fake `PlacesSearching` implementation — no
network access needed.

## Architecture

```
Views                    (SwiftUI — HomeView, DestinationSearchView, RideProvidersView)
   │
ViewModels                (@Observable — HomeViewModel, DestinationSearchViewModel)
   │
Services                  LocationService (CoreLocation)  ·  GooglePlacesService (Places SDK)
   │                       — the only two files that import a platform/vendor SDK directly
   ▼
RideCompareCore  (Swift package, no SwiftUI/UIKit/CoreLocation/Google imports)
   ├── Models         RideLocation, RideQuote
   ├── Providers       RideProvider protocol + UberProvider / BoltProvider / FreeNowProvider
   └── Services         RideProviderService, RideQuoteProvider (future)
```

Four boundaries are kept strict, on purpose:

1. **Google location/search** is isolated to `GooglePlacesService` +
   `PlaceSuggestion`. Nothing else in the app touches a Google SDK type — a
   selected result is converted to `RideLocation` immediately (see
   `PlacesSearching`).
2. **User/location state** is isolated to `LocationService`. It's the only
   file that imports CoreLocation, and it never lets a denied or
   unavailable location become a crash — see `PickupLocationState`.
3. **Provider deep links** are isolated to `Providers/`, behind the
   `RideProvider` protocol. The UI never builds a provider URL itself; it
   asks `RideProviderService` for the provider list and calls
   `buildRideURL`. Adding, changing, or dropping a provider integration
   touches exactly one file.
4. **Future quote retrieval** (`RideQuoteProvider`, `RideQuote`) is a
   separate protocol nothing currently conforms to — see the doc comments on
   both types. When a legitimate, authorized pricing API becomes available
   for a provider, it plugs in without touching deep-link code.

## Provider limitations

This project's rule, from day one: **only implement a provider deep link
that the provider currently documents publicly** — never scrape, never
reverse engineer, never guess at an undocumented URL format, even if one is
"commonly known" from blog posts or other apps.

| Provider | Deep link | Status |
|---|---|---|
| **Uber** | ✅ Implemented | Uber publishes an official [Ride Request Deeplink](https://developer.uber.com/docs/riders/ride-requests/tutorials/deep-links/introduction) (`action=setPickup` on `https://m.uber.com/ul/`). `UberProvider` builds this universal link with documented pickup/dropoff latitude, longitude, nickname, and formatted-address parameters. |
| **Bolt** | ⚠️ Fallback only | No public, documented deep-link format for pre-filling a trip from a third-party app was found at the time this was built (Bolt's public resources describe partner/B2B integrations, not a consumer URL scheme). `BoltProvider.buildRideURL` always returns `nil`; the app falls back to Bolt's App Store listing / website. |
| **FREE NOW** | ⚠️ Fallback only | Same situation: no documented consumer deep-link format was found. (FREE NOW is now "Freenow by Lyft" following Lyft's 2025 acquisition — Lyft's own `lyft://` deep link is *not* assumed to work with the FREE NOW app, since it's a distinct product.) `FreeNowProvider.buildRideURL` always returns `nil`; the app falls back to FREE NOW's App Store listing / website. |

If Bolt or FREE NOW publish an official deep-link API in the future, only
`BoltProvider.swift` / `FreeNowProvider.swift` need to change — see their doc
comments. **Re-verify this table against each company's current developer
documentation before relying on it**; deep-link support is exactly the kind
of thing that changes without much announcement.

Provider logos aren't used (no confirmed redistribution rights) — each
provider is shown with its name and a neutral SF Symbol instead
(`ProviderButtonView`).

## Privacy

- No user accounts, no analytics, no third-party SDKs beyond the Google
  Places SDK required for destination search.
- The user's location is requested only to display it as pickup and to
  build a provider deep link the user explicitly taps to open — it is never
  stored on disk and never sent to any server other than Google's, as part
  of an autocomplete/place-details request the user initiated.
- No destination or location history is persisted between launches.
- `NSLocationWhenInUseUsageDescription` in `Info.plist` explains this
  plainly to the user at the permission prompt.

## Known limitations & next steps

- **`GooglePlacesSwift` API surface.** The Places Swift SDK is a young,
  sub-1.0 API and Google has changed method/type names across releases.
  `GooglePlacesService.swift` targets the documented shape of
  `PlacesClient.fetchAutocompleteSuggestions(with:)` and
  `PlacesClient.fetchPlace(with:)` as of this project's implementation date;
  if Xcode reports a missing symbol after resolving packages, that one file
  is the only place to update (see its header comment).
- **App icon.** `Assets.xcassets/AppIcon.appiconset` is an empty placeholder
  slot — add a real 1024×1024 icon before shipping.
- **Bundle identifier.** `com.ridecompare.launcher` is a placeholder; change
  it (and the App Store Connect app record, if you publish this) before
  release.
- **Price comparison.** Deliberately out of scope for this MVP — see
  `RideQuoteProvider` and `RideQuote` for the extension point. Do not wire up
  a "quote" source that isn't an official, authorized API.
