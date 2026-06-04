//
//  AssistedSellingView.swift
//  RSMS
//
//  Product catalog with search, category filter chips,
//  product grid, and AI recommendation support.
//

import SwiftUI

struct AssistedSellingView: View {
    @State private var viewModel = AssistedSellingCatalogViewModel()
    @State private var selectedProduct: Product?
    @State private var showProductDetail = false

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                categoryFilters
                productGrid
            }
        }
        .navigationTitle("Product Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedProduct) { product in
            ASProductDetailSheet(product: product)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(RSMSTheme.textTertiary)
            TextField("Search by name, SKU, or brand…", text: $viewModel.searchQuery)
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: - Category Filters

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ASCategoryChip(
                    label: "All",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }

                ForEach(viewModel.categories, id: \.self) { cat in
                    ASCategoryChip(
                        label: cat,
                        isSelected: viewModel.selectedCategory == cat
                    ) {
                        viewModel.selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Product Grid

    private var productGrid: some View {
        ScrollView {
            if viewModel.filteredProducts.isEmpty {
                ContentUnavailableView("No Products Found",
                                       systemImage: "magnifyingglass",
                                       description: Text("Try adjusting your search or filters."))
                    .padding(.top, 60)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 16)
                ], spacing: 16) {
                    ForEach(viewModel.filteredProducts) { product in
                        ASProductCard(product: product)
                            .onTapGesture {
                                selectedProduct = product
                            }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Catalog ViewModel (file-private, uses mock data)

@Observable
private final class AssistedSellingCatalogViewModel {
    private(set) var products: [Product] = Product.all
    var searchQuery = ""
    var selectedCategory: String?

    var filteredProducts: [Product] {
        var result = products.filter(\.isActive)
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                $0.sku.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q)
            }
        }
        return result
    }

    var categories: [String] {
        Array(Set(products.map(\.category))).sorted()
    }
}

// MARK: - Category Chip

private struct ASCategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AnyShapeStyle(RSMSTheme.primaryGradient) : AnyShapeStyle(RSMSTheme.surfacePrimary),
                    in: Capsule()
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Filter by \(label)")
    }
}

// MARK: - Product Card

private struct ASProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.primary.opacity(0.06))
                    .frame(minHeight: 120)
                Image(systemName: categoryIcon)
                    .font(.largeTitle)
                    .foregroundStyle(RSMSTheme.primary.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)

                Text(product.brand)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)

                HStack {
                    Text("₹\(Int(product.price).formatted())")
                        .font(.body.weight(.bold))
                        .foregroundStyle(RSMSTheme.primary)

                    Spacer()

                    if let material = product.material {
                        Text(material)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(RSMSTheme.surfaceSecondary, in: Capsule())
                    }
                }
            }

            if let collection = product.collection {
                Text(collection.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .rsmsCard()
    }

    private var categoryIcon: String {
        switch product.category.lowercased() {
        case "jewelry":       return "sparkles"
        case "watches":       return "clock.fill"
        case "leather goods": return "bag.fill"
        default:              return "diamond.fill"
        }
    }
}

// MARK: - Product Detail Sheet

private struct ASProductDetailSheet: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(RSMSTheme.primary.opacity(0.06))
                                .frame(minHeight: 200)
                            Image(systemName: "sparkles")
                                .font(.largeTitle)
                                .foregroundStyle(RSMSTheme.primary.opacity(0.2))
                        }
                        .padding(.horizontal, 24)

                        // Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text(product.name)
                                .font(.title.weight(.bold))
                                .foregroundStyle(RSMSTheme.textPrimary)

                            Text("₹\(Int(product.price).formatted())")
                                .font(.title.weight(.bold))
                                .foregroundStyle(RSMSTheme.primary)

                            Divider().overlay(RSMSTheme.divider)

                            ASDetailRow(label: "SKU", value: product.sku)
                            ASDetailRow(label: "Brand", value: product.brand)
                            ASDetailRow(label: "Category", value: product.category)
                            if let sub = product.subcategory {
                                ASDetailRow(label: "Subcategory", value: sub)
                            }
                            if let material = product.material {
                                ASDetailRow(label: "Material", value: material)
                            }
                            if let collection = product.collection {
                                ASDetailRow(label: "Collection", value: collection)
                            }

                            if let desc = product.description {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                // Add to cart
                            } label: {
                                Label("Add to Cart", systemImage: "cart.badge.plus")
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RSMSTheme.primaryGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(ScaleButtonStyle())

                            Button {
                                // Add to wishlist
                            } label: {
                                Label("Add to Wishlist", systemImage: "heart")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RSMSTheme.surfacePrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(RSMSTheme.primary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct ASDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AssistedSellingView()
    }
}
