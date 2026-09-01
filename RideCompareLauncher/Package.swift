// swift-tools-version:5.9
import PackageDescription

/// RideCompareCore holds every piece of business logic that does not need
/// SwiftUI, UIKit, CoreLocation, or the Google Places SDK: the app's
/// internal models, the ride-provider deep-link abstraction and its
/// concrete implementations, and small platform-independent utilities.
///
/// Keeping this logic in its own Swift package (rather than directly inside
/// the Xcode app target) means it can be unit tested with a plain
/// `swift test` — no simulator, no Xcode project, no network access — and
/// it keeps the provider deep-link rules (the part of this app most likely
/// to need careful review) decoupled from UI code.
///
/// The Xcode app target (see `App/RideCompareLauncher.xcodeproj`) depends on
/// this package as a local Swift package and layers SwiftUI views,
/// CoreLocation, and the Google Places SDK integration on top of it.
let package = Package(
    name: "RideCompareCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13), // enables `swift test` on macOS/Linux CI without an iOS simulator
    ],
    products: [
        .library(name: "RideCompareCore", targets: ["RideCompareCore"])
    ],
    targets: [
        .target(name: "RideCompareCore"),
        .testTarget(name: "RideCompareCoreTests", dependencies: ["RideCompareCore"]),
    ]
)
