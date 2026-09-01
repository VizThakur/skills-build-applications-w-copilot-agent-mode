import RideCompareCore
import SwiftUI

/// One "Open <Provider>" card on `RideProvidersView`.
///
/// This app doesn't have redistribution rights for Uber's, Bolt's, or FREE
/// NOW's logos, so every provider is shown with a neutral SF Symbol plus its
/// name rather than a brand mark — see the README's "Provider limitations"
/// section. Swap `systemImage` for a real logo asset per provider only after
/// confirming brand usage permission with each company.
struct ProviderButtonView: View {
    let provider: RideProvider
    var isAvailable: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: symbolName)
                    .font(.title2)
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Open \(provider.name)")
        .accessibilityHint(isAvailable ? "" : "\(provider.name) isn't installed. Opens the App Store instead.")
        .accessibilityAddTraits(.isButton)
    }

    /// "Detect whether the relevant app can be opened where possible," per
    /// the product spec — shown as an informational hint rather than
    /// disabling the button, since every provider here still has *some*
    /// working fallback (App Store or website) even when its app isn't
    /// installed.
    private var subtitle: String {
        isAvailable ? "Open \(provider.name)" : "Not installed — opens the App Store"
    }

    private var symbolName: String {
        switch provider.identifier {
        case "uber": return "car.fill"
        case "bolt": return "bolt.car.fill"
        case "freenow": return "car.side.fill"
        default: return "car.fill"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ProviderButtonView(provider: UberProvider(), action: {})
        ProviderButtonView(provider: BoltProvider(), action: {})
        ProviderButtonView(provider: FreeNowProvider(), action: {})
    }
    .padding()
}
