import SwiftUI

// MARK: - Card Modifier

struct RSMSCardModifier: ViewModifier {
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(RSMSTheme.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 6)
    }
}

extension View {
    func rsmsCard(padding: CGFloat = 20) -> some View {
        modifier(RSMSCardModifier(padding: padding))
    }
}
