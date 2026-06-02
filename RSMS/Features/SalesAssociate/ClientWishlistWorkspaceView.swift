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
                    
                    // Smart Recommendations
                    if viewModel.hasRecommendations {
                        recommendationSections
                    }
                    
                    Spacer(minLength: 120)
                }
            }
            
            if viewModel.wishlistCount > 0 {
                floatingActionBar
            }
            
            if viewModel.isLoading && viewModel.wishlistProducts.isEmpty {
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
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                // Client Info
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text(viewModel.clientName)
                        .font(.system(size: 28, weight: .semibold))
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
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text("Explore curated recommendations below to begin building this client's personal collection.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Recommendation Sections
    
    @ViewBuilder
    private var recommendationSections: some View {
        VStack(spacing: 40) {
            // Divider before recommendations
            HStack {
                Rectangle()
                    .fill(RSMSTheme.border)
                    .frame(height: 0.5)
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.primary.opacity(0.5))
                Rectangle()
                    .fill(RSMSTheme.border)
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
            
            if viewModel.hasWishlistItems {
                // Contextual recommendations when wishlist has items
                if !viewModel.completeTheLook.isEmpty {
                    RecommendationCarousel(
                        title: "Complete The Look",
                        subtitle: "Pieces that pair beautifully with your selections",
                        icon: "wand.and.stars",
                        products: viewModel.completeTheLook,
                        viewModel: viewModel
                    )
                }
                
                if !viewModel.premiumAlternatives.isEmpty {
                    RecommendationCarousel(
                        title: "Premium Alternatives",
                        subtitle: "Elevated options in a similar style",
                        icon: "arrow.up.right.circle",
                        products: viewModel.premiumAlternatives,
                        viewModel: viewModel
                    )
                }
            } else {
                // Preference-based recommendations when wishlist is empty
                if !viewModel.recommendedForClient.isEmpty {
                    RecommendationCarousel(
                        title: "Recommended For \(viewModel.client.fullName.components(separatedBy: " ").first ?? "Client")",
                        subtitle: "Handpicked based on preferences and style profile",
                        icon: "person.crop.square.filled.and.at.rectangle",
                        products: viewModel.recommendedForClient,
                        viewModel: viewModel
                    )
                }
            }
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

// MARK: - Recommendation Carousel

struct RecommendationCarousel: View {
    let title: String
    let subtitle: String
    let icon: String
    let products: [Product]
    let viewModel: ClientWishlistWorkspaceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(RSMSTheme.primary)
                    
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            .padding(.horizontal, 24)
            
            // Horizontal Scroll Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(products) { product in
                        RecommendationProductCard(product: product, viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Recommendation Product Card

struct RecommendationProductCard: View {
    let product: Product
    let viewModel: ClientWishlistWorkspaceViewModel
    @State private var isAdding = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Area
            ZStack(alignment: .topTrailing) {
                if let urlString = product.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            placeholderView
                        }
                    }
                    .frame(width: 200, height: 260)
                    .clipped()
                } else {
                    placeholderView
                        .frame(width: 200, height: 260)
                }
                
                // Add to Wishlist Button
                Button {
                    Task {
                        isAdding = true
                        await viewModel.addToWishlist(product: product)
                        isAdding = false
                    }
                } label: {
                    Image(systemName: "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(RSMSTheme.primary)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.9)))
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(10)
                .disabled(isAdding)
            }
            
            // Product Details Area
            VStack(alignment: .leading, spacing: 4) {
                Text(product.brand.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(RSMSTheme.textTertiary)
                
                Text(product.name)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)
                    .frame(width: 176, alignment: .leading) // 200 - padding
                
                Text(product.formattedPrice)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.primary)
                    .padding(.top, 2)
            }
            .padding(12)
            .frame(width: 200, alignment: .leading)
        }
        .background(RSMSTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(RSMSTheme.surfaceSecondary)
            
            VStack(spacing: 8) {
                Image(systemName: product.categoryIconName)
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundStyle(RSMSTheme.textTertiary.opacity(0.5))
                
                Text(product.category.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(RSMSTheme.textTertiary.opacity(0.4))
            }
        }
    }
}

// MARK: - Editorial Product Card (Wishlist)

struct WishlistProductEditorialCard: View {
    let product: Product
    let viewModel: ClientWishlistWorkspaceViewModel
    @State private var showOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Area
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
                    .clipped()
                } else {
                    Rectangle()
                        .fill(RSMSTheme.surfaceSecondary)
                        .frame(height: 240)
                        .overlay(
                            Image(systemName: "bag.fill")
                                .font(.largeTitle)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        )
                }
            }
            
            // Product Details Area
            VStack(alignment: .leading, spacing: 4) {
                Text(product.brand.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(RSMSTheme.textTertiary)
                
                Text(product.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)
                
                HStack {
                    Text(product.formattedPrice)
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
            .padding(16)
        }
        .background(RSMSTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
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
