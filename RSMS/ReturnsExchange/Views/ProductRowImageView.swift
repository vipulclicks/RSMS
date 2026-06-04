//
//  ProductRowImageView.swift
//  RSMS
//

import SwiftUI

struct ProductRowImageView: View {
    let product: Product
    
    var body: some View {
        if let urlString = product.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else if phase.error != nil {
                    fallbackImage
                } else {
                    ProgressView()
                        .tint(RSMSTheme.primary)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
        } else {
            fallbackImage
        }
    }
    
    private var fallbackImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(RSMSTheme.surfaceSecondary)
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: product.categoryIconName)
                    .font(.system(size: 20))
                    .foregroundStyle(RSMSTheme.textTertiary)
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
    }
}

struct FallbackProductImageView: View {
    let systemImage: String
    let statusColor: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(statusColor.opacity(0.1))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(statusColor)
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
    }
}
