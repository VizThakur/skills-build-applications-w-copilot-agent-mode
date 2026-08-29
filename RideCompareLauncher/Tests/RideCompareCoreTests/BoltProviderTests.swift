import XCTest
@testable import RideCompareCore

final class BoltProviderTests: XCTestCase {
    private let pickup = RideLocation(name: "Current Location", latitude: 50.0619, longitude: 19.9368)
    private let destination = RideLocation(name: "Kraków Airport", latitude: 50.0777, longitude: 19.7848)

    /// Bolt has no documented deep-link format, so this must always be nil —
    /// never a guessed URL. If this test starts failing because someone
    /// added a URL, they've reintroduced the exact behavior this project's
    /// rules prohibit.
    func testBuildRideURLIsAlwaysNil() {
        XCTAssertNil(BoltProvider().buildRideURL(pickup: pickup, destination: destination))
    }

    func testFallbacksAreProvided() {
        let provider = BoltProvider()
        XCTAssertNotNil(provider.appStoreFallbackURL)
        XCTAssertNotNil(provider.websiteFallbackURL)
    }

    func testProviderIdentity() {
        let provider = BoltProvider()
        XCTAssertEqual(provider.name, "Bolt")
        XCTAssertEqual(provider.identifier, "bolt")
    }
}
