import RideCompareCore
import SwiftUI

/// Shown once a destination has been selected: recaps the trip, then lists
/// every ride provider as a one-tap "Open <Provider>" card.
struct RideProvidersView: View {
    let pickup: RideLocation
    let destination: RideLocation
    let providers: [RideProvider]
    let onOpenProvider: (RideProvider) -> Void
    var isProviderAvailable: (RideProvider) -> Bool = { _ in true }
    @Binding var errorMessage: String?

    var body: some View {
        List {
            Section {
                tripSummaryRow(icon: "location.circle.fill", title: "From", location: pickup)
                tripSummaryRow(icon: "mappin.circle.fill", title: "To", location: destination)
            }

            Section("Choose a ride app") {
                ForEach(providers, id: \.identifier) { provider in
                    ProviderButtonView(provider: provider, isAvailable: isProviderAvailable(provider)) {
                        onOpenProvider(provider)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Your destination")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Unable to Open App",
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }),
            presenting: errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func tripSummaryRow(icon: String, title: String, location: RideLocation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(location.name)
                    .font(.body)
                if let address = location.address {
                    Text(address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        RideProvidersView(
            pickup: RideLocation(name: "Current Location", latitude: 50.0619, longitude: 19.9368),
            destination: RideLocation(name: "Kraków Airport", address: "Balice, Kraków", latitude: 50.0777, longitude: 19.7848),
            providers: RideProviderService.standard().providers,
            onOpenProvider: { _ in },
            errorMessage: .constant(nil)
        )
    }
}
