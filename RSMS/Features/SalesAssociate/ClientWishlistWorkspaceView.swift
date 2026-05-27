//
//  ClientWishlistWorkspaceView.swift
//  RSMS
//
//  Created for luxury client wishlist workspace.
//

import SwiftUI

struct ClientWishlistWorkspaceView: View {
    let viewModel: ClientWishlistWorkspaceViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    // Grid configuration for large luxury product cards
    private var columns: [GridItem] {
        if sizeClass == .regular {
            return [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)]
        } else {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    luxuryHeader
                    
                    preferenceOverview
                    
                    if viewModel.wishlistProducts.isEmpty {
                        emptyStateView
                    } else {
                        wishlistProductGrid
                    }
                    
                    if !viewModel.availableCatalogProducts.isEmpty {
                        catalogDiscoverySection
                    }
                    
                    Spacer(minLength: 120)
                }
            }
            
            floatingActionBar
            
            if viewModel.isLoading && viewModel.wishlistProducts.isEmpty && viewModel.availableCatalogProducts.isEmpty {
                ProgressView()
                    .tint(RSMSTheme.primary)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RSMSTheme.background.opacity(0.4))
            }
        }
        .navigationTitle("Wishlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(RSMSTheme.primary)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Components
    
    private var luxuryHeader: some View {
        VStack(spacing: 24) {
            HStack(spacing: 20) {
                // Circular Avatar
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.12))
                        .frame(width: 72, height: 72)
                        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
                    
                    Text(viewModel.initials)
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                // Client Info
                VStack(alignment: .leading, spacing: 6) {
                    Text("Private Collection For")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .textCase(.uppercase)
                        .tracking(2.0)
                    
                    Text(viewModel.clientName)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        if viewModel.isVIP {
                            Text(viewModel.vipBadgeText)
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(RSMSTheme.primaryGradient)
                                .foregroundStyle(RSMSTheme.cream)
                                .clipShape(Capsule())
                        }
                        
                        Text(viewModel.lastUpdatedFormatted)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Category Filter pills
            categoryFilterSection
        }
        .padding(.top, 20)
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(label: "All", isSelected: viewModel.selectedCategory == nil) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        viewModel.selectedCategory = nil
                    }
                }
                
                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryChip(label: category, isSelected: viewModel.selectedCategory == category) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            viewModel.selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var preferenceOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client Preferences")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textSecondary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Spacer().frame(width: 12)
                    ForEach(viewModel.clientPreferences) { chip in
                        HStack(spacing: 6) {
                            Image(systemName: chip.icon)
                                .font(.caption2)
                            Text(chip.value)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(RSMSTheme.primary)
                        .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                    }
                    Spacer().frame(width: 12)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            
            Image(systemName: "sparkles.square.filled.on.square")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(RSMSTheme.primary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("An Empty Canvas")
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text("Scroll down to discover and save luxury pieces to the client's personal collection.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    private var catalogDiscoverySection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discover")
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Add items to the client's Wishlist.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            
            LazyVGrid(columns: columns, spacing: 32) {
                ForEach(viewModel.availableCatalogProducts) { product in
                    CatalogProductEditorialCard(product: product, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.availableCatalogProducts)
        }
    }
    
    private var wishlistProductGrid: some View {
        LazyVGrid(columns: columns, spacing: 32) {
            ForEach(viewModel.wishlistProducts) { product in
                WishlistProductEditorialCard(product: product, viewModel: viewModel)
            }
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.wishlistProducts)
    }
    
    private var floatingActionBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.wishlistCount) Items")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
                Text("₹\(Int(viewModel.estimatedWishlistValue).formatted())")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.createCartFromWishlist()
                }
            } label: {
                Text("Create Cart")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.cream)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(RSMSTheme.primaryGradient, in: Capsule())
            }
            .disabled(viewModel.wishlistProducts.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Editorial Product Card

struct WishlistProductEditorialCard: View {
    let product: Product
    let viewModel: ClientWishlistWorkspaceViewModel
    @State private var showOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                if let urlString = product.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.gray.opacity(0.1)
                        }
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(RSMSTheme.surfaceSecondary)
                        .frame(height: 240)
                        .overlay(
                            Image(systemName: "bag.fill")
                                .font(.largeTitle)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        )
                }
                
                // Match score badge or luxury flag
                Text("98% Match")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.brand.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(RSMSTheme.textTertiary)
                
                Text(product.name)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)
                
                HStack {
                    Text("\(product.currency) \(Int(product.price).formatted())")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                    Spacer()
                    
                    Menu {
                        Button {
                            Task { await viewModel.moveToCuratedCart(product: product) }
                        } label: {
                            Label("Move to Cart", systemImage: "cart.badge.plus")
                        }
                        
                        Button(role: .destructive) {
                            Task { await viewModel.removeFromWishlist(product: product) }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .padding(4)
                            .background(RSMSTheme.surfacePrimary, in: Circle())
                            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Catalog Editorial Card

struct CatalogProductEditorialCard: View {
    let product: Product
    let viewModel: ClientWishlistWorkspaceViewModel
    @State private var isAdding = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                if let urlString = product.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.gray.opacity(0.1)
                        }
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(RSMSTheme.surfaceSecondary)
                        .frame(height: 240)
                        .overlay(
                            Image(systemName: "bag")
                                .font(.largeTitle)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        )
                }
                
                Button {
                    Task {
                        isAdding = true
                        await viewModel.addToWishlist(product: product)
                        isAdding = false
                    }
                } label: {
                    Image(systemName: "heart")
                        .font(.system(size: 15))
                        .foregroundStyle(RSMSTheme.primary)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.85)))
                        .shadow(color: .black.opacity(0.08), radius: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(12)
                .disabled(isAdding)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.brand.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(RSMSTheme.textTertiary)
                
                Text(product.name)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)
                
                Text("\(product.currency) \(Int(product.price).formatted())")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.primary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : RSMSTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AnyShapeStyle(RSMSTheme.primaryGradient) : AnyShapeStyle(RSMSTheme.surfacePrimary),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1))
        }
    }
}
