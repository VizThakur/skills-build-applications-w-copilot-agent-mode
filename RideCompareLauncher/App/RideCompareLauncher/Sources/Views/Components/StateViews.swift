import SwiftUI

/// A centered, icon + title + optional message layout used for every empty,
/// loading, error, and permission-denied state in the app, so those states
/// look and behave consistently wherever they appear.
struct StatusView: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// A simple, Dynamic-Type-friendly loading indicator with a label, for use
/// wherever a spinner alone wouldn't be accessible to VoiceOver users.
struct LoadingView: View {
    var label: String = "Loading…"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

#Preview("Status") {
    StatusView(
        systemImage: "location.slash",
        title: "Location access is disabled",
        message: "You can still enter your pickup location manually.",
        actionTitle: "Open Settings",
        action: {}
    )
}

#Preview("Loading") {
    LoadingView(label: "Finding your location…")
}
