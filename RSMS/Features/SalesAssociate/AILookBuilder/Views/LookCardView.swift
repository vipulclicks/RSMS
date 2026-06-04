//
//  LookCardView.swift
//  RSMS
//

import SwiftUI

struct ProductRow: Identifiable {
    let id = UUID()
    let left: Product
    let right: Product?
}

struct LookCardView: View {
    let look: GeneratedLook
    let isSaved: Bool
    let onSaveToggle: () -> Void
    
    // We will use ShareLink for sharing
    var sharePayload: String
    
    private var productRows: [ProductRow] {
        var rows: [ProductRow] = []
        let products = look.products
        for i in stride(from: 0, to: products.count, by: 2) {
            let left = products[i]
            let right = i + 1 < products.count ? products[i + 1] : nil
            rows.append(ProductRow(left: left, right: right))
        }
        return rows
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(look.name)
                    .font(.headline)
                    .foregroundColor(RSMSTheme.textPrimary)
                
                Text(look.occasion.rawValue)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.surfaceSecondary)
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Products Grid (2x2 or similar)
            VStack(spacing: 16) {
                ForEach(productRows) { row in
                    HStack(spacing: 12) {
                        LookProductItemView(product: row.left)
                        
                        if let right = row.right {
                            LookProductItemView(product: right)
                        } else {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
                .background(RSMSTheme.border)
            
            // Footer: Total & Actions
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.textSecondary)
                    if !look.products.isEmpty {
                        Text("₹\(Int(look.totalPrice).formatted())")
                            .font(.body)
                            .foregroundColor(RSMSTheme.textPrimary)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    ShareLink(item: sharePayload) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(RSMSTheme.primary)
                    }
                    
                    Button(action: onSaveToggle) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark").accessibilityLabel("Save")
                            .font(.title3)
                            .foregroundColor(isSaved ? RSMSTheme.primary : RSMSTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(RSMSTheme.surfacePrimary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct LookProductItemView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image Placeholder - Strictly enforce 1:1 aspect ratio
            Rectangle()
                .fill(RSMSTheme.surfaceSecondary)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay(
                    Group {
                        if let urlString = product.imageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    Image(systemName: "photo")
                                        .foregroundColor(RSMSTheme.textSecondary)
                                }
                            }
                        } else {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title)
                                .foregroundColor(RSMSTheme.textSecondary.opacity(0.5))
                        }
                    }
                )
                .clipped()
            
            VStack(alignment: .leading, spacing: 10) {
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)
                    .frame(minHeight: 36, alignment: .topLeading)
                
                Text(product.brand)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                
                Text("₹\(Int(product.price).formatted())")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(RSMSTheme.primary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RSMSTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
