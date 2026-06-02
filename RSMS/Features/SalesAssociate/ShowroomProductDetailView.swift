//
//  ShowroomProductDetailView.swift
//  RSMS
//
//  A modal view displaying deep storytelling and large imagery for a product.
//

import SwiftUI

struct ShowroomProductDetailView: View {
    let product: Product
    let viewModel: ProductCatalogViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var wishlistAdded = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large Image
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
                        .frame(maxWidth: .infinity, idealHeight: 500)
                        .clipped()
                    } else {
                        placeholder
                            .frame(height: 500)
                    }
                    
                    VStack(spacing: 16) {
                        // Title & Price
                        VStack(spacing: 8) {
                            Text(product.brand)
                                .font(.headline)
                                .textCase(.uppercase)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            
                            Text(product.name)
                                .font(.title2.weight(.medium))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            
                            Text(product.formattedPrice)
                                .font(.title3)
                                .foregroundStyle(RSMSTheme.primary)
                        }
                        .padding(.horizontal)
                        
                        Divider().overlay(RSMSTheme.divider)
                            .padding(.horizontal, 24)
                        
                        // Storytelling / Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The Details")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            
                            Text(product.description ?? "An exquisite piece crafted with the finest materials.")
                                .font(.body)
                                .foregroundStyle(RSMSTheme.textSecondary)
                                .lineSpacing(4)
                            
                            HStack {
                                Text("Collection:")
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Spacer()
                                Text(product.collection ?? "Maison Signature")
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            .font(.subheadline)
                            .padding(.top, 8)
                            
                            HStack {
                                Text("Material:")
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Spacer()
                                Text(product.material ?? "Premium")
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            .font(.subheadline)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.cartItems.contains(where: { $0.product.id == product.id }) {
                        Button(action: {
                            viewModel.toggleCartItem(product)
                            dismiss()
                        }) {
                            Image(systemName: "trash")
                                .font(.body.weight(.bold))
                                .foregroundStyle(RSMSTheme.danger)
                        }
                    }
                }
            }
            // Bottom Action Bar
            .safeAreaInset(edge: .bottom) {
                let isInCart = viewModel.cartItems.contains(where: { $0.product.id == product.id })
                HStack(spacing: 16) {
                    Button {
                        Task {
                            await viewModel.toggleWishlist(for: product)
                            withAnimation {
                                wishlistAdded = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    wishlistAdded = false
                                }
                            }
                        }
                    } label: {
                        Image(systemName: wishlistAdded ? "sparkles.square.filled.on.square" : "sparkles.square.on.square")
                            .font(.title2)
                            .foregroundStyle(wishlistAdded ? RSMSTheme.primary : RSMSTheme.textSecondary)
                            .frame(width: 56, height: 56)
                            .background(RSMSTheme.surfaceSecondary, in: Circle())
                            .overlay(Circle().stroke(RSMSTheme.border, lineWidth: 1))
                    }
                    .disabled(wishlistAdded)
                    
                    Button(action: {
                        viewModel.toggleCartItem(product)
                        if isInCart {
                            dismiss()
                        }
                    }) {
                        Text(isInCart ? "Remove from Edit" : "Add to Edit")
                            .font(.headline)
                            .foregroundStyle(isInCart ? RSMSTheme.textPrimary : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isInCart ? RSMSTheme.surfaceSecondary : RSMSTheme.primary, in: Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(RSMSTheme.surfacePrimary.shadow(color: .black.opacity(0.05), radius: 10, y: -5))
            }
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .fill(RSMSTheme.surfaceSecondary)
            .overlay(
                Image(systemName: product.categoryIconName)
                    .font(.system(size: 80))
                    .foregroundStyle(RSMSTheme.textTertiary.opacity(0.3))
            )
    }
}
