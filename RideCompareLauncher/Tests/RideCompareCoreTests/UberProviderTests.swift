import XCTest
@testable import RideCompareCore

final class UberProviderTests: XCTestCase {
    private let pickup = RideLocation(
        name: "Current Location",
        address: nil,
        latitude: 50.0619,
        longitude: 19.9368
    )

    private let destination = RideLocation(
        name: "Kraków Airport",
        address: "Balice, 32-083 Kraków, Poland",
        latitude: 50.0777,
        longitude: 19.7848,
        placeID: "ChIJplaceID123"
    )

    func testBuildRideURLUsesUberUniversalLinkHost() {
        let url = UberProvider().buildRideURL(pickup: pickup, destination: destination)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "m.uber.com")
        XCTAssertEqual(url?.path, "/ul/")
    }

    func testBuildRideURLIncludesSetPickupAction() throws {
        let url = try XCTUnwrap(UberProvider().buildRideURL(pickup: pickup, destination: destination))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertTrue(items.contains(URLQueryItem(name: "action", value: "setPickup")))
    }

    func testBuildRideURLIncludesPickupAndDropoffCoordinates() throws {
        let url = try XCTUnwrap(UberProvider().buildRideURL(pickup: pickup, destination: destination))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)

        XCTAssertTrue(items.contains(URLQueryItem(name: "pickup[latitude]", value: "50.0619")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "pickup[longitude]", value: "19.9368")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "pickup[nickname]", value: "Current Location")))

        XCTAssertTrue(items.contains(URLQueryItem(name: "dropoff[latitude]", value: "50.0777")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "dropoff[longitude]", value: "19.7848")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "dropoff[nickname]", value: "Kraków Airport")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "dropoff[formatted_address]", value: "Balice, 32-083 Kraków, Poland")))
    }

    func testBuildRideURLOmitsFormattedAddressWhenNilOrEmpty() throws {
        // Pickup has no address, so pickup[formatted_address] must be absent entirely.
        let url = try XCTUnwrap(UberProvider().buildRideURL(pickup: pickup, destination: destination))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertFalse(items.contains { $0.name == "pickup[formatted_address]" })
    }

    func testBuildRideURLOmitsClientIDWhenNotProvided() throws {
        let url = try XCTUnwrap(UberProvider().buildRideURL(pickup: pickup, destination: destination))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertFalse(items.contains { $0.name == "client_id" })
    }

    func testBuildRideURLIncludesClientIDWhenProvided() throws {
        let url = try XCTUnwrap(UberProvider(clientID: "abc123").buildRideURL(pickup: pickup, destination: destination))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertTrue(items.contains(URLQueryItem(name: "client_id", value: "abc123")))
    }

    func testProviderIdentity() {
        let provider = UberProvider()
        XCTAssertEqual(provider.name, "Uber")
        XCTAssertEqual(provider.identifier, "uber")
        XCTAssertEqual(provider.queryableURLScheme, "uber")
        XCTAssertNotNil(provider.appStoreFallbackURL)
        XCTAssertNotNil(provider.websiteFallbackURL)
    }
}
