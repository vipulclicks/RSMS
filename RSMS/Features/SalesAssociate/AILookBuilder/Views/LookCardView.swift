//
//  LookCardView.swift
//  RSMS
//

import SwiftUI

struct LookCardView: View {
    let look: GeneratedLook
    let isSaved: Bool
    let onSaveToggle: () -> Void
    
    // We will use ShareLink for sharing
    var sharePayload: String
    
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
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(look.products) { product in
                    LookProductItemView(product: product)
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
                    if let firstProduct = look.products.first {
                        Text("\(firstProduct.currency) \(String(format: "%.2f", look.totalPrice))")
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
                            .font(.system(size: 20))
                            .foregroundColor(RSMSTheme.primary)
                    }
                    
                    Button(action: onSaveToggle) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20))
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
        VStack(alignment: .leading, spacing: 8) {
            // Image Placeholder (Using color palette if no imageURL)
            ZStack {
                if let urlString = product.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.clear
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(RSMSTheme.textSecondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                        .foregroundColor(RSMSTheme.textSecondary.opacity(0.5))
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(8)
            .clipped()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.brand)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                
                Text(product.name)
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.textPrimary)
                    .lineLimit(2)
                    .frame(height: 36, alignment: .topLeading)
                
                Text("\(product.currency) \(String(format: "%.2f", product.price))")
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.textPrimary)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
