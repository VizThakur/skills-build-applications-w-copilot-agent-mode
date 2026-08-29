import RideCompareCore
import SwiftUI

/// Full-screen search used for both "Where are you going?" (destination) and
/// "Enter pickup location" (manual pickup override) — the same live Google
/// Places Autocomplete flow, just with a different title and completion
/// handler, per the task's requirement to reuse one search experience for
/// both.
struct DestinationSearchView: View {
    let title: String
    let onSelect: (RideLocation) -> Void

    @State private var viewModel: DestinationSearchViewModel
    @State private var resolveError: String?
    @State private var isResolving = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFieldFocused: Bool

    init(title: String, placesService: PlacesSearching = GooglePlacesService(), onSelect: @escaping (RideLocation) -> Void) {
        self.title = title
        self.onSelect = onSelect
        _viewModel = State(initialValue: DestinationSearchViewModel(placesService: placesService))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if !AppConfiguration.isPlacesConfigured {
                    StatusView(
                        systemImage: "exclamationmark.triangle",
                        title: "Destination search isn't set up yet",
                        message: PlacesServiceError.notConfigured.userFacingMessage
                    )
                } else {
                    resultsList
                }
            }
            .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search destination")
            .searchFocused($isSearchFieldFocused)
            .onAppear { isSearchFieldFocused = true }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isResolving {
                    LoadingView(label: "Getting location details…")
                        .background(.regularMaterial)
                }
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(get: { resolveError != nil }, set: { if !$0 { resolveError = nil } }),
                presenting: resolveError
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    @ViewBuilder
    private var resultsList: some View {
        switch viewModel.state {
        case .empty:
            StatusView(systemImage: "magnifyingglass", title: "Search for a destination", message: "Start typing an address or place name.")

        case .loading:
            LoadingView(label: "Searching…")

        case .results(let suggestions):
            List(suggestions) { suggestion in
                Button {
                    select(suggestion)
                } label: {
                    PlaceSuggestionRow(suggestion: suggestion)
                }
                .disabled(isResolving)
            }
            .listStyle(.plain)

        case .noResults:
            StatusView(systemImage: "mappin.slash", title: "No results found", message: "Try a different spelling or a nearby landmark.")

        case .error(let message):
            StatusView(
                systemImage: "wifi.exclamationmark",
                title: "Search failed",
                message: message,
                actionTitle: "Try Again",
                action: { viewModel.retry() }
            )
        }
    }

    private func select(_ suggestion: PlaceSuggestion) {
        isSearchFieldFocused = false
        isResolving = true
        Task {
            do {
                let location = try await viewModel.resolveLocation(for: suggestion)
                isResolving = false
                onSelect(location)
            } catch let error as PlacesServiceError {
                isResolving = false
                resolveError = error.userFacingMessage
            } catch {
                isResolving = false
                resolveError = "We couldn't get details for that location. Please try again."
            }
        }
    }
}

#Preview {
    DestinationSearchView(title: "Where are you going?", placesService: PreviewPlacesService()) { _ in }
}

/// A fake `PlacesSearching` conformance for SwiftUI previews and manual
/// testing without a network connection or API key.
private struct PreviewPlacesService: PlacesSearching {
    func startNewSession() {}

    func autocomplete(query: String) async throws -> [PlaceSuggestion] {
        guard !query.isEmpty else { return [] }
        return [
            PlaceSuggestion(id: "1", primaryText: "Kraków Airport", secondaryText: "Balice, Kraków"),
            PlaceSuggestion(id: "2", primaryText: "Kraków Airport Parking", secondaryText: "Balice"),
            PlaceSuggestion(id: "3", primaryText: "Kraków Airport Hotel", secondaryText: "Kraków"),
        ]
    }

    func resolveLocation(for suggestion: PlaceSuggestion) async throws -> RideLocation {
        RideLocation(name: suggestion.primaryText, address: suggestion.secondaryText, latitude: 50.0777, longitude: 19.7848, placeID: suggestion.id)
    }
}
