import RideCompareCore
import XCTest
@testable import RideCompareLauncher

/// A configurable fake `PlacesSearching` so these tests never touch the
/// network, an API key, or the real Google Places SDK.
@MainActor
private final class FakePlacesService: PlacesSearching {
    var suggestionsToReturn: [PlaceSuggestion] = []
    var autocompleteError: Error?
    var locationToReturn: RideLocation?
    private(set) var sessionsStarted = 0
    private(set) var lastQuery: String?

    func startNewSession() {
        sessionsStarted += 1
    }

    func autocomplete(query: String) async throws -> [PlaceSuggestion] {
        lastQuery = query
        if let autocompleteError { throw autocompleteError }
        return suggestionsToReturn
    }

    func resolveLocation(for suggestion: PlaceSuggestion) async throws -> RideLocation {
        locationToReturn ?? RideLocation(name: suggestion.primaryText, latitude: 0, longitude: 0, placeID: suggestion.id)
    }
}

@MainActor
final class DestinationSearchViewModelTests: XCTestCase {
    func testEmptyQueryProducesEmptyState() async {
        let service = FakePlacesService()
        let viewModel = DestinationSearchViewModel(placesService: service)

        viewModel.query = ""

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testTypingSchedulesADebouncedSearchAndPopulatesResults() async throws {
        let service = FakePlacesService()
        service.suggestionsToReturn = [PlaceSuggestion(id: "1", primaryText: "Kraków Airport", secondaryText: "Balice")]
        let viewModel = DestinationSearchViewModel(placesService: service)

        viewModel.query = "Kraków air"

        // Give the (300ms default) debounce window plus the async request time to complete.
        try await waitUntil(timeout: .seconds(1)) { viewModel.state != .empty && viewModel.state != .loading }

        XCTAssertEqual(viewModel.state, .results(service.suggestionsToReturn))
        XCTAssertEqual(service.lastQuery, "Kraków air")
    }

    func testRapidTypingOnlySearchesForTheFinalQuery() async throws {
        let service = FakePlacesService()
        service.suggestionsToReturn = [PlaceSuggestion(id: "1", primaryText: "Result", secondaryText: nil)]
        let viewModel = DestinationSearchViewModel(placesService: service)

        for partial in ["K", "Kr", "Kra", "Krak", "Kraków"] {
            viewModel.query = partial
        }

        try await waitUntil(timeout: .seconds(1)) { viewModel.state != .empty && viewModel.state != .loading }

        XCTAssertEqual(service.lastQuery, "Kraków")
    }

    func testNoResultsStateWhenSearchSucceedsWithNothing() async throws {
        let service = FakePlacesService()
        service.suggestionsToReturn = []
        let viewModel = DestinationSearchViewModel(placesService: service)

        viewModel.query = "asdkjhaksjdh"

        try await waitUntil(timeout: .seconds(1)) { viewModel.state != .empty && viewModel.state != .loading }

        XCTAssertEqual(viewModel.state, .noResults)
    }

    func testSearchFailureSurfacesUserFacingMessage() async throws {
        let service = FakePlacesService()
        service.autocompleteError = PlacesServiceError.autocompleteFailed("network down")
        let viewModel = DestinationSearchViewModel(placesService: service)

        viewModel.query = "Kraków"

        try await waitUntil(timeout: .seconds(1)) { viewModel.state != .empty && viewModel.state != .loading }

        XCTAssertEqual(viewModel.state, .error(PlacesServiceError.autocompleteFailed("network down").userFacingMessage))
    }

    func testResolveLocationStartsANewSessionAfterward() async throws {
        let service = FakePlacesService()
        let viewModel = DestinationSearchViewModel(placesService: service)
        let sessionsBefore = service.sessionsStarted

        _ = try await viewModel.resolveLocation(for: PlaceSuggestion(id: "1", primaryText: "A", secondaryText: nil))

        XCTAssertEqual(service.sessionsStarted, sessionsBefore + 1)
    }

    /// Polls `condition` until it's true or `timeout` elapses, to observe the
    /// result of the view model's internally-debounced, fire-and-forget `Task`.
    private func waitUntil(
        timeout: Duration,
        condition: @escaping () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTFail("Condition not met within \(timeout)")
    }
}
