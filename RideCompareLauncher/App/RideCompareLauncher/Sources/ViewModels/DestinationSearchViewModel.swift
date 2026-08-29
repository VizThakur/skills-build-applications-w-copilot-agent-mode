import Observation
import RideCompareCore

/// Drives `DestinationSearchView`: turns typed text into debounced Places
/// Autocomplete requests and exposes a simple state machine the view renders
/// directly, with no Google-specific types anywhere in this file.
@MainActor
@Observable
final class DestinationSearchViewModel {
    enum SearchState: Equatable {
        /// Nothing typed yet.
        case empty
        case loading
        case results([PlaceSuggestion])
        /// A real, successful search that matched nothing.
        case noResults
        case error(String)
    }

    var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            scheduleSearch(for: query)
        }
    }

    private(set) var state: SearchState = .empty

    private let placesService: PlacesSearching
    private let debouncer = Debouncer(delay: .milliseconds(300))

    init(placesService: PlacesSearching) {
        self.placesService = placesService
        placesService.startNewSession()
    }

    private func scheduleSearch(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .empty
            Task { await debouncer.cancel() }
            return
        }

        Task {
            await debouncer.run { [weak self] in
                await self?.performSearch(trimmed)
            }
        }
    }

    private func performSearch(_ query: String) async {
        await MainActor.run { self.state = .loading }
        do {
            let suggestions = try await placesService.autocomplete(query: query)
            await MainActor.run {
                // The query may have changed again while this request was in
                // flight; only apply results if they still match what's on screen.
                guard self.query.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }
                self.state = suggestions.isEmpty ? .noResults : .results(suggestions)
            }
        } catch let error as PlacesServiceError {
            await MainActor.run { self.state = .error(error.userFacingMessage) }
        } catch {
            await MainActor.run {
                self.state = .error("We couldn't search for that location. Please check your connection and try again.")
            }
        }
    }

    /// Re-runs the search for the current query, e.g. from a "Try Again"
    /// button after a failed request.
    func retry() {
        scheduleSearch(for: query)
    }

    /// Resolves a selected suggestion into a full `RideLocation` and starts a
    /// fresh Autocomplete session for the next search.
    func resolveLocation(for suggestion: PlaceSuggestion) async throws -> RideLocation {
        defer { placesService.startNewSession() }
        return try await placesService.resolveLocation(for: suggestion)
    }
}
