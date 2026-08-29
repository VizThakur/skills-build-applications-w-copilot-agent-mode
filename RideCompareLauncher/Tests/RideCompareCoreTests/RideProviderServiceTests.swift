import XCTest
@testable import RideCompareCore

final class RideProviderServiceTests: XCTestCase {
    func testStandardIncludesAllThreeProvidersInOrder() {
        let service = RideProviderService.standard()
        XCTAssertEqual(service.providers.map(\.identifier), ["uber", "bolt", "freenow"])
    }

    func testRideURLLooksUpByIdentifier() {
        let service = RideProviderService.standard()
        let pickup = RideLocation(name: "Current Location", latitude: 50.0619, longitude: 19.9368)
        let destination = RideLocation(name: "Kraków Airport", latitude: 50.0777, longitude: 19.7848)

        XCTAssertNotNil(service.rideURL(providerIdentifier: "uber", pickup: pickup, destination: destination))
        XCTAssertNil(service.rideURL(providerIdentifier: "bolt", pickup: pickup, destination: destination))
        XCTAssertNil(service.rideURL(providerIdentifier: "does-not-exist", pickup: pickup, destination: destination))
    }
}
