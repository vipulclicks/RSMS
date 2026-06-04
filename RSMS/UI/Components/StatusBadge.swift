import SwiftUI

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(RSMSTheme.bgOpacity(for: contrast, base: 0.15)))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(text)")
    }
}
