//
//  ProductCatalogView.swift
//  RSMS
//
//  Guided Product Catalog for the Sales Associate.
//  Fetches real product + stock data from Supabase, supports
//  search, category/collection/price filters, product detail,
//  and quick-add to a curated cart.
//

import SwiftUI

// MARK: - Root Catalog View

struct ProductCatalogView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel: ProductCatalogViewModel?
    @State private var selectedProduct: Product?
    @State private var showFilterSheet = false

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            if let vm = viewModel {
                catalogContent(vm)
            } else {
                ProgressView()
                    .tint(RSMSTheme.primary)
            }
        }
        .navigationTitle("Product Catalog")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let vm = viewModel {
                    filterButton(vm)
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            let vm = ProductCatalogViewModel(dataStore: appViewModel.dataStore,
                                            storeId: appViewModel.currentUser?.storeId)
            await vm.load()
            viewModel = vm
        }
        .sheet(item: $selectedProduct) { product in
            if let vm = viewModel {
                CatalogProductDetailSheet(
                    product: product,
                    stockQuantity: vm.stockQuantity(for: product.id),
                    onAddToCart: { vm.addToCart(product) }
                )
            }
        }
    }

    // MARK: - Catalog Content

    @ViewBuilder
    private func catalogContent(_ vm: ProductCatalogViewModel) -> some View {
        VStack(spacing: 0) {
            searchBar(vm)
            categoryFilters(vm)

            if vm.isLoading {
                Spacer()
                ProgressView("Loading products…")
                    .tint(RSMSTheme.primary)
                Spacer()
            } else if let error = vm.errorMessage {
                Spacer()
                ContentUnavailableView("Load Failed",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text(error))
                Spacer()
            } else if vm.filteredProducts.isEmpty {
                Spacer()
                ContentUnavailableView("No Products Found",
                                       systemImage: "magnifyingglass",
                                       description: Text("Try adjusting your search or filters."))
                Spacer()
            } else {
                productGrid(vm)
            }
        }

        // Mini cart badge overlay
        if vm.cartItems.count > 0 {
            VStack {
                Spacer()
                CatalogCartBadge(count: vm.cartItems.count,
                                 dataStore: appViewModel.dataStore,
                                 items: vm.cartItems,
                                 onClear: { vm.clearCart() })
                    .padding(.bottom, 16)
                    .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Search Bar

    private func searchBar(_ vm: ProductCatalogViewModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(RSMSTheme.textTertiary)
            TextField("Search by name, SKU, brand…", text: Bindable(vm).searchQuery)
                .foregroundStyle(RSMSTheme.textPrimary)
                .autocorrectionDisabled()
            if !vm.searchQuery.isEmpty {
                Button { vm.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: - Category Filter Chips

    private func categoryFilters(_ vm: ProductCatalogViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CatalogChip(label: "All", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(vm.availableCategories, id: \.self) { cat in
                    CatalogChip(label: cat, isSelected: vm.selectedCategory == cat) {
                        vm.selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Product Grid

    private func productGrid(_ vm: ProductCatalogViewModel) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 16)],
                      spacing: 16) {
                ForEach(vm.filteredProducts) { product in
                    ProductCatalogCard(
                        product: product,
                        stockQty: vm.stockQuantity(for: product.id),
                        isInCart: vm.isInCart(product.id)
                    )
                    .onTapGesture { selectedProduct = product }
                    .overlay(alignment: .topTrailing) {
                        Button {
                            vm.addToCart(product)
                        } label: {
                            Image(systemName: vm.isInCart(product.id) ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(vm.isInCart(product.id) ? Color.green : RSMSTheme.primary)
                                .background(Circle().fill(RSMSTheme.cream))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(10)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, vm.cartItems.count > 0 ? 100 : 40)
        }
    }

    // MARK: - Filter Button

    private func filterButton(_ vm: ProductCatalogViewModel) -> some View {
        Button {
            showFilterSheet = true
        } label: {
            Label("Filter", systemImage: vm.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(vm.hasActiveFilters ? RSMSTheme.primary : RSMSTheme.textPrimary)
        }
        .sheet(isPresented: $showFilterSheet) {
            CatalogFilterSheet(viewModel: vm)
        }
    }
}

// MARK: - Product Catalog Card

struct ProductCatalogCard: View {
    let product: Product
    let stockQty: Int
    let isInCart: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Product image
            productImage
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)

                Text(product.brand)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)

                HStack {
                    Text(product.formattedPrice)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(RSMSTheme.primary)
                    Spacer()
                    StockBadge(quantity: stockQty)
                }
            }
        }
        .rsmsCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isInCart ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var productImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(RSMSTheme.primary.opacity(0.06))
                .frame(height: 110)

            if let urlString = product.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure, .empty:
                        categoryIcon
                    @unknown default:
                        categoryIcon
                        
                    }
                }
            } else {
                categoryIcon
            }
        }
    }

    private var categoryIcon: some View {
        Image(systemName: product.categoryIconName)
            .font(.system(size: 30))
            .foregroundStyle(RSMSTheme.primary.opacity(0.25))
    }
}

// MARK: - Stock Badge

struct StockBadge: View {
    let quantity: Int

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.caption2.weight(.medium))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.08), in: Capsule())
    }

    private var statusColor: Color {
        if quantity == 0 { return .red }
        if quantity <= 3 { return .orange }
        return .green
    }

    private var statusText: String {
        if quantity == 0 { return "Out of stock" }
        if quantity <= 3 { return "Low stock" }
        return "In stock"
    }
}

// MARK: - Catalog Cart Badge (Mini floating bar)

struct CatalogCartBadge: View {
    let count: Int
    let dataStore: DataStore
    let items: [CartSelectionItem]
    let onClear: () -> Void

    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "cart.fill")
                    .foregroundStyle(RSMSTheme.cream)
                Text("\(count) item\(count == 1 ? "" : "s") selected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.cream)
                Spacer()
                Text("View →")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.cream.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(RSMSTheme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showSheet) {
            CartSelectionPreviewSheet(items: items, dataStore: dataStore, onClear: onClear)
        }
    }
}

// MARK: - Cart Selection Preview Sheet

struct CartSelectionPreviewSheet: View {
    let items: [CartSelectionItem]
    let dataStore: DataStore
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    if let product = dataStore.product(by: item.productId) {
                        HStack(spacing: 12) {
                            Image(systemName: product.categoryIconName)
                                .font(.title3)
                                .foregroundStyle(RSMSTheme.primary)
                                .frame(width: 36, height: 36)
                                .background(RSMSTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text(product.formattedPrice)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Cart Selection (\(items.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { onClear(); dismiss() }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Product Detail Sheet

struct CatalogProductDetailSheet: View {
    let product: Product
    let stockQuantity: Int
    let onAddToCart: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var addedToCart = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        heroImage
                        productInfo
                        actions
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var heroImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(RSMSTheme.primary.opacity(0.06))
                .frame(height: 220)

            if let urlString = product.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    default:
                        Image(systemName: product.categoryIconName)
                            .font(.system(size: 64))
                            .foregroundStyle(RSMSTheme.primary.opacity(0.2))
                    }
                }
            } else {
                Image(systemName: product.categoryIconName)
                    .font(.system(size: 64))
                    .foregroundStyle(RSMSTheme.primary.opacity(0.2))
            }
        }
        .padding(.horizontal, 24)
    }

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(product.brand)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                Spacer()
                StockBadge(quantity: stockQuantity)
            }

            Text(product.formattedPrice)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(RSMSTheme.primary)

            Divider().overlay(RSMSTheme.divider)

            DetailRow(label: "SKU", value: product.sku)
            DetailRow(label: "Category", value: product.category)
            if let sub = product.subcategory { DetailRow(label: "Subcategory", value: sub) }
            if let mat = product.material { DetailRow(label: "Material", value: mat) }
            if let col = product.collection { DetailRow(label: "Collection", value: col) }
            if let desc = product.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                onAddToCart()
                addedToCart = true
            } label: {
                Label(addedToCart ? "Added to Cart ✓" : "Add to Curated Cart",
                      systemImage: addedToCart ? "checkmark.circle.fill" : "cart.badge.plus")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(addedToCart ? AnyShapeStyle(Color.green) : AnyShapeStyle(RSMSTheme.primaryGradient))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(addedToCart)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Filter Sheet

struct CatalogFilterSheet: View {
    @Bindable var viewModel: ProductCatalogViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Collection
                if !viewModel.availableCollections.isEmpty {
                    Section("Collection") {
                        Picker("Collection", selection: $viewModel.selectedCollection) {
                            Text("All Collections").tag(String?.none)
                            ForEach(viewModel.availableCollections, id: \.self) { col in
                                Text(col).tag(String?.some(col))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Price Range
                Section("Price Range") {
                    HStack {
                        Text("Min")
                        Slider(value: $viewModel.minPrice, in: 0...viewModel.maxPriceSliderBound, step: 100)
                        Text(viewModel.minPrice.formatted(.number.precision(.fractionLength(0))))
                    }
                    HStack {
                        Text("Max")
                        Slider(value: $viewModel.maxPrice, in: 0...viewModel.maxPriceSliderBound, step: 100)
                        Text(viewModel.maxPrice.formatted(.number.precision(.fractionLength(0))))
                    }
                }

                // Availability
                Section("Availability") {
                    Toggle("In-stock only", isOn: $viewModel.showInStockOnly)
                }

                Section {
                    Button("Clear All Filters") {
                        viewModel.clearFilters()
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Filter Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Catalog Chip

struct CatalogChip: View {
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
                .overlay(Capsule().stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Detail Row

struct DetailRow: View {
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

// MARK: - Product Extension Helpers

extension Product {
    var categoryIconName: String {
        switch category.lowercased() {
        case "jewelry": return "sparkles"
        case "watches": return "clock.fill"
        case "leather goods": return "bag.fill"
        case "fragrances", "perfume": return "wind"
        default: return "diamond.fill"
        }
    }

    var formattedPrice: String {
        return "₹\(Int(price).formatted())"
    }
}
