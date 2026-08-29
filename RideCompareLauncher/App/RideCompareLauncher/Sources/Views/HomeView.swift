import RideCompareCore
import SwiftUI

/// The app's single main screen: pickup, destination search, and (once a
/// destination is chosen) automatic navigation into `RideProvidersView`.
///
/// Kept deliberately to one screen plus two sheets/pushes, per the task's
/// "avoid unnecessary screens" / "only a few taps" requirement:
/// tap destination → search → select → provider list, with pickup handled
/// automatically via Core Location unless the user chooses to enter it manually.
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var isSearchingDestination = false
    @State private var isSearchingManualPickup = false
    @State private var path: [Route] = []

    private enum Route: Hashable { case providers }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $path) {
            Form {
                pickupSection
                destinationSection
            }
            .navigationTitle("RideCompare")
            .task { viewModel.requestCurrentLocation() }
            .onChange(of: viewModel.destination) { _, newValue in
                if newValue != nil, path.last != .providers {
                    path.append(.providers)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .providers:
                    if let pickup = viewModel.pickup, let destination = viewModel.destination {
                        RideProvidersView(
                            pickup: pickup,
                            destination: destination,
                            providers: viewModel.providerService.providers,
                            onOpenProvider: viewModel.openProvider,
                            isProviderAvailable: viewModel.isProviderAppInstalled,
                            errorMessage: $viewModel.openProviderErrorMessage
                        )
                    }
                }
            }
            .sheet(isPresented: $isSearchingDestination) {
                DestinationSearchView(title: "Where are you going?") { location in
                    viewModel.setDestination(location)
                    isSearchingDestination = false
                }
            }
            .sheet(isPresented: $isSearchingManualPickup) {
                DestinationSearchView(title: "Enter pickup location") { location in
                    viewModel.setManualPickup(location)
                    isSearchingManualPickup = false
                }
            }
        }
    }

    // MARK: - Pickup

    private var pickupSection: some View {
        Section("From") {
            if let pickup = viewModel.pickup {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pickup.name)
                        if let address = pickup.address {
                            Text(address)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                }
                .accessibilityElement(children: .combine)

                Button("Enter pickup location manually") {
                    isSearchingManualPickup = true
                }
                .font(.footnote)
            } else if viewModel.isPickupLoading {
                HStack {
                    ProgressView()
                    Text("Finding your location…")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Finding your location")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label(viewModel.pickupErrorMessage ?? "Your location isn't available.", systemImage: "location.slash")
                        .foregroundStyle(.secondary)
                        .font(.footnote)

                    HStack {
                        Button("Try Again") {
                            viewModel.requestCurrentLocation()
                        }
                        Spacer()
                        Button("Enter Manually") {
                            isSearchingManualPickup = true
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Destination

    private var destinationSection: some View {
        Section {
            Button {
                isSearchingDestination = true
            } label: {
                if let destination = viewModel.destination {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(destination.name)
                            .foregroundStyle(.primary)
                        if let address = destination.address {
                            Text(address)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Label("Search destination", systemImage: "magnifyingglass")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(viewModel.destination == nil ? "Search destination" : "Destination: \(viewModel.destination?.name ?? "")")
            .accessibilityHint("Opens destination search")
        } header: {
            Text("Where are you going?")
        }
    }
}

#Preview {
    HomeView()
}
