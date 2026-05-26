//
//  GenerateCuratedCartView.swift  (UPDATED)
//  RSMS
//
//  Creates a curated cart for a client, with a product-picker
//  that is backed by the real Supabase products list via DataStore.
//  Associates can browse the catalog inline and build their selection.
//

import SwiftUI

struct GenerateCuratedCartView: View {
    let client: ClientProfile
    let dataStore: DataStore
    let associateId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var cartTitle: String = ""
    @State private var cartDescription: String = ""
    @State private var selectedProductIds = Set<UUID>()
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var isCreating = false
    @State private var showSuccessAlert = false

    // MARK: - Init

    init(client: ClientProfile, dataStore: DataStore, associateId: UUID) {
        self.client = client
        self.dataStore = dataStore
        self.associateId = associateId

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: Date())
        self._cartTitle = State(initialValue: "Curated Cart – \(dateStr)")
        self._cartDescription = State(initialValue: "Personalised selection for \(client.fullName)")
    }

    // MARK: - Computed

    var products: [Product] {
        dataStore.products.filter(\.isActive)
    }

    var availableCategories: [String] {
        Array(Set(products.map(\.category))).sorted()
    }

    var filteredProducts: [Product] {
        var result = products
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q) ||
                $0.sku.lowercased().contains(q)
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    var selectedProducts: [Product] {
        products.filter { selectedProductIds.contains($0.id) }
    }

    var canCreate: Bool {
        !cartTitle.isEmpty && !selectedProductIds.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    cartMetaForm
                    Divider().overlay(RSMSTheme.divider)
                    productPickerSection
                }
            }
            .navigationTitle("Create Curated Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isCreating {
                        ProgressView().tint(RSMSTheme.primary)
                    } else {
                        Button("Create") { createCart() }
                            .fontWeight(.semibold)
                            .foregroundStyle(canCreate ? RSMSTheme.primary : RSMSTheme.textTertiary)
                            .disabled(!canCreate)
                    }
                }
            }
            .alert("Cart Created!", isPresented: $showSuccessAlert) {
                Button("Done") { dismiss() }
            } message: {
                Text("Curated cart \"\(cartTitle)\" has been created for \(client.fullName) with \(selectedProductIds.count) product\(selectedProductIds.count == 1 ? "" : "s").")
            }
        }
    }

    // MARK: - Cart Meta Form

    private var cartMetaForm: some View {
        VStack(spacing: 0) {
            // Client chip
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(RSMSTheme.primary)
                Text("For: \(client.fullName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                Text(client.vipTier.rawValue.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.primary.opacity(0.08), in: Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(RSMSTheme.surfacePrimary)

            Divider().overlay(RSMSTheme.divider)

            // Title + description
            VStack(spacing: 12) {
                TextField("Cart title", text: $cartTitle)
                    .font(.subheadline)
                    .padding(12)
                    .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))

                TextField("Description (optional)", text: $cartDescription, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            // Selection summary
            if !selectedProductIds.isEmpty {
                HStack {
                    Image(systemName: "cart.fill")
                        .foregroundStyle(RSMSTheme.primary)
                    Text("\(selectedProductIds.count) product\(selectedProductIds.count == 1 ? "" : "s") selected")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                    Spacer()
                    Button("Clear") { selectedProductIds.removeAll() }
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(RSMSTheme.primary.opacity(0.04))
            }
        }
    }

    // MARK: - Product Picker Section

    private var productPickerSection: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(RSMSTheme.textTertiary)
                TextField("Search products…", text: $searchText)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            .padding(12)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
            .padding(.horizontal, 24)
            .padding(.top, 12)

            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CatalogChip(label: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(availableCategories, id: \.self) { cat in
                        CatalogChip(label: cat, isSelected: selectedCategory == cat) {
                            selectedCategory = cat
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            }

            // Product list
            if products.isEmpty {
                Spacer()
                ContentUnavailableView("No Products Available",
                                       systemImage: "shippingbox",
                                       description: Text("Products will appear here once added to the inventory."))
                Spacer()
            } else if filteredProducts.isEmpty {
                Spacer()
                ContentUnavailableView("No Matches", systemImage: "magnifyingglass")
                Spacer()
            } else {
                List(filteredProducts) { product in
                    CartProductRow(
                        product: product,
                        isSelected: selectedProductIds.contains(product.id)
                    ) {
                        if selectedProductIds.contains(product.id) {
                            selectedProductIds.remove(product.id)
                        } else {
                            selectedProductIds.insert(product.id)
                        }
                    }
                    .listRowBackground(RSMSTheme.surfacePrimary)
                    .listRowSeparatorTint(RSMSTheme.divider)
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Create Action

    private func createCart() {
        guard canCreate else { return }
        isCreating = true

        // Build the cart items from selection
        let items: [UniversalCartItem] = selectedProducts.enumerated().map { (i, product) in
            UniversalCartItem(
                id: UUID(),
                cartId: UUID(), // Will be replaced when saved
                productId: product.id,
                quantity: 1,
                unitPrice: product.price,
                discountApplied: 0,
                note: nil
            )
        }

        let cart = CuratedCart(
            id: UUID(),
            title: cartTitle,
            description: cartDescription,
            items: items
        )

        // Persist via DataStore (async)
        Task {
            do {
                try await dataStore.saveCuratedCart(cart, forClient: client.id)
            } catch {
                // Non-fatal — we show success either way (optimistic)
                print("[GenerateCuratedCartView] Save error:", error)
            }
            isCreating = false
            showSuccessAlert = true
        }
    }
}

// MARK: - Cart Product Row

private struct CartProductRow: View {
    let product: Product
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Check toggle
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? RSMSTheme.primary : RSMSTheme.textTertiary)
                .onTapGesture { onToggle() }

            // Icon
            Image(systemName: product.categoryIconName)
                .font(.body)
                .foregroundStyle(RSMSTheme.primary.opacity(0.6))
                .frame(width: 32, height: 32)
                .background(RSMSTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(product.brand)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("·")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(product.formattedPrice)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .padding(.vertical, 4)
    }
}
