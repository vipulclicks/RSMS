// CartCard.swift
import SwiftUI

struct CartCard: View {
    let cart: CuratedCart

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cart.title)
                .font(.system(.headline))
                .foregroundStyle(RSMSTheme.cream)
            Text(cart.description)
                .font(.system(.subheadline))
                .foregroundStyle(RSMSTheme.cream.opacity(0.8))
                .lineLimit(2)
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(RSMSTheme.primaryGradient)
        .cornerRadius(12)
        .shadow(radius: 4)
        .accessibilityLabel("Cart: \(cart.title)")
    }
}
