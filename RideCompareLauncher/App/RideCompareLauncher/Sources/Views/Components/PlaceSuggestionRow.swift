import SwiftUI

/// A single row in the destination/pickup autocomplete results list.
struct PlaceSuggestionRow: View {
    let suggestion: PlaceSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.primaryText)
                    .font(.body)
                    .foregroundStyle(.primary)

                if let secondaryText = suggestion.secondaryText, !secondaryText.isEmpty {
                    Text(secondaryText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        if let secondaryText = suggestion.secondaryText, !secondaryText.isEmpty {
            return "\(suggestion.primaryText), \(secondaryText)"
        }
        return suggestion.primaryText
    }
}

#Preview {
    List {
        PlaceSuggestionRow(suggestion: PlaceSuggestion(id: "1", primaryText: "Kraków Airport", secondaryText: "Balice, Kraków"))
        PlaceSuggestionRow(suggestion: PlaceSuggestion(id: "2", primaryText: "Kraków Airport Parking", secondaryText: "Balice"))
        PlaceSuggestionRow(suggestion: PlaceSuggestion(id: "3", primaryText: "Kraków Airport Hotel", secondaryText: nil))
    }
}
