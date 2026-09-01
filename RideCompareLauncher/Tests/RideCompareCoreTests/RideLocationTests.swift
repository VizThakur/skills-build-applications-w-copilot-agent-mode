import XCTest
@testable import RideCompareCore

final class RideLocationTests: XCTestCase {
    func testIdUsesPlaceIDWhenAvailable() {
        let location = RideLocation(name: "Airport", latitude: 1, longitude: 2, placeID: "abc123")
        XCTAssertEqual(location.id, "abc123")
    }

    func testIdFallsBackToCoordinatesWhenNoPlaceID() {
        let location = RideLocation(name: "Current Location", latitude: 50.0619, longitude: 19.9368)
        XCTAssertEqual(location.id, "50.0619,19.9368")
    }

    func testEqualityIgnoresNothingUnexpected() {
        let a = RideLocation(name: "Airport", address: "Somewhere", latitude: 1, longitude: 2, placeID: "abc")
        let b = RideLocation(name: "Airport", address: "Somewhere", latitude: 1, longitude: 2, placeID: "abc")
        let c = RideLocation(name: "Airport", address: "Somewhere else", latitude: 1, longitude: 2, placeID: "abc")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testDisplaySubtitleMirrorsAddress() {
        XCTAssertEqual(RideLocation(name: "A", address: "B", latitude: 0, longitude: 0).displaySubtitle, "B")
        XCTAssertNil(RideLocation(name: "A", latitude: 0, longitude: 0).displaySubtitle)
    }
}
