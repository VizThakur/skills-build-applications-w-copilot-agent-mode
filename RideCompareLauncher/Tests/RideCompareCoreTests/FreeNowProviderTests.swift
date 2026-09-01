import XCTest
@testable import RideCompareCore

final class FreeNowProviderTests: XCTestCase {
    private let pickup = RideLocation(name: "Current Location", latitude: 50.0619, longitude: 19.9368)
    private let destination = RideLocation(name: "Kraków Airport", latitude: 50.0777, longitude: 19.7848)

    /// FREE NOW has no documented deep-link format, so this must always be
    /// nil — never a guessed URL.
    func testBuildRideURLIsAlwaysNil() {
        XCTAssertNil(FreeNowProvider().buildRideURL(pickup: pickup, destination: destination))
    }

    func testNoURLSchemeIsGuessed() {
        // Unlike Bolt, no scheme has been reliably confirmed for FREE NOW, so
        // this stays nil rather than encoding a guess.
        XCTAssertNil(FreeNowProvider().queryableURLScheme)
    }

    func testFallbacksAreProvided() {
        let provider = FreeNowProvider()
        XCTAssertNotNil(provider.appStoreFallbackURL)
        XCTAssertNotNil(provider.websiteFallbackURL)
    }

    func testProviderIdentity() {
        let provider = FreeNowProvider()
        XCTAssertEqual(provider.name, "FREE NOW")
        XCTAssertEqual(provider.identifier, "freenow")
    }
}
