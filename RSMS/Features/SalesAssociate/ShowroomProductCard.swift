//
//  ShowroomProductCard.swift
//  RSMS
//
//  A premium, luxury product card for the Digital Showroom.
//

import SwiftUI

struct ShowroomProductCard: View {
    let product: Product
    let isInCart: Bool
    let stockQty: Int
    let onAdd: () -> Void
    let onDetail: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Area
            ZStack(alignment: .topTrailing) {
                if let urlString = product.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            placeholder
                        }
                    }
                    .frame(height: 240)
                    .clipped()
                } else {
                    placeholder
                        .frame(height: 240)
                }
                
                // Availability Badge (Top-Left overlay)
                VStack {
                    HStack {
                        StockBadge(quantity: stockQty)
                            .padding(12)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onDetail)
            
            // Text Details & Add Button
            VStack(alignment: .leading, spacing: 6) {
                if let col = product.collection {
                    Text(col.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .tracking(1.5)
                } else {
                    Text(product.brand.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .tracking(1.5)
                }
                
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(alignment: .bottom) {
                    Text(product.formattedPrice)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(RSMSTheme.primary)
                    
                    Spacer()
                    
                    // Add Button placed at bottom-right of the text block
                    if stockQty == 0 && !isInCart {
                        Button(action: {}) {
                            Text("OUT OF STOCK")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(RSMSTheme.textTertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(RSMSTheme.surfaceSecondary, in: Capsule())
                        }
                        .disabled(true)
                    } else {
                        Button(action: onAdd) {
                            HStack(spacing: 4) {
                                if isInCart {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                    Text("ADDED")
                                } else {
                                    Text("ADD")
                                }
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isInCart ? RSMSTheme.primary : Color(red: 0.15, green: 0.15, blue: 0.15), in: Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RSMSTheme.surfacePrimary)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isInCart ? RSMSTheme.primary : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(RSMSTheme.surfaceSecondary)
            .overlay(
                Image(systemName: product.categoryIconName)
                    .font(.system(size: 40))
                    .foregroundStyle(RSMSTheme.textTertiary.opacity(0.5))
            )
    }
}
