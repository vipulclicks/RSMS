// GenerateCuratedCartView.swift
import SwiftUI

struct GenerateCuratedCartView: View {
    let client: ClientProfile
    let dataStore: DataStore
    let associateId: UUID
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var cartTitle: String = ""
    @State private var cartDescription: String = ""
    @State private var selectedProductIds = Set<UUID>()
    @State private var productQuantities: [UUID: Int] = [:]
    @State private var productNotes: [UUID: String] = [:]
    @State private var searchText = ""
    @State private var isCreating = false
    
    struct MatchedProduct: Identifiable {
        var id: UUID { product.id }
        let product: Product
        let reasons: [String]
        let isAIRecommended: Bool
    }
    
    init(client: ClientProfile, dataStore: DataStore, associateId: UUID) {
        self.client = client
        self.dataStore = dataStore
        self.associateId = associateId
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        self._cartTitle = State(initialValue: "Curated Cart - \(formatter.string(from: Date()))")
        self._cartDescription = State(initialValue: "Personalized recommendation selection for \(client.fullName)")
    }
    
    var matchedProducts: [MatchedProduct] {
        var results: [MatchedProduct] = []
        
        let aiRecommendedProductIds = Set(
            dataStore.aiRecommendations
                .filter { $0.clientId == client.id }
                .map { $0.productId }
        )
        
        for product in dataStore.products {
            var reasons: [String] = []
            var isAIRecommended = false
            
            if aiRecommendedProductIds.contains(product.id) {
                isAIRecommended = true
                reasons.append("AI Recommended")
            }
            
            if let favCategories = client.favoriteCategories {
                if favCategories.contains(where: { $0.localizedCaseInsensitiveCompare(product.category) == .orderedSame }) {
                    reasons.append("Category: \(product.category)")
                }
            }
            
            if let favMetals = client.favoriteMetals, let material = product.material {
                if favMetals.contains(where: { material.localizedCaseInsensitiveContains($0) }) {
                    reasons.append("Metal: \(material)")
                }
            }
            
            if let favGemstones = client.favoriteGemstones {
                for gemstone in favGemstones {
                    if product.name.localizedCaseInsensitiveContains(gemstone) || (product.description?.localizedCaseInsensitiveContains(gemstone) ?? false) {
                        reasons.append("Gemstone: \(gemstone)")
                        break
                    }
                }
            }
            
            if !reasons.isEmpty {
                results.append(MatchedProduct(product: product, reasons: reasons, isAIRecommended: isAIRecommended))
            }
        }
        
        return results.sorted { (p1, p2) in
            if p1.isAIRecommended != p2.isAIRecommended {
                return p1.isAIRecommended
            }
            return p1.reasons.count > p2.reasons.count
        }
    }
    
    var filteredProducts: [Product] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        return dataStore.products.filter {
            $0.name.lowercased().contains(query) ||
            $0.sku.lowercased().contains(query) ||
            $0.category.lowercased().contains(query)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Cart Info Form
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cart Name")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textSecondary)
                            TextField("e.g. Summer Diamond Collection", text: $cartTitle)
                                .padding(10)
                                .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description / Notes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textSecondary)
                            TextField("e.g. Hand-picked pieces matching client's preferences", text: $cartDescription)
                                .padding(10)
                                .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                    }
                    .padding(16)
                    .background(RSMSTheme.surfaceSecondary)
                    
                    // Search box
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        TextField("Search all products in catalogue...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                    }
                    .padding(10)
                    .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Scrollable Product List
                    List {
                        if !searchText.isEmpty {
                            Section("Search Results") {
                                if filteredProducts.isEmpty {
                                    Text("No products found")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                } else {
                                    ForEach(filteredProducts) { product in
                                        productRow(product: product, reasons: [])
                                    }
                                }
                            }
                        } else {
                            Section("Recommended for \(client.fullName)") {
                                let matches = matchedProducts
                                if matches.isEmpty {
                                    Text("No specific matches found based on preferences. Use search above to select products manually.")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                } else {
                                    ForEach(matches) { item in
                                        productRow(product: item.product, reasons: item.reasons)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    
                    // Create Cart Action
                    VStack {
                        Divider()
                            .background(RSMSTheme.divider)
                        
                        Button {
                            createCart()
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate Curated Cart (\(selectedProductIds.count))")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                selectedProductIds.isEmpty ? Color.gray : RSMSTheme.primary,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .disabled(selectedProductIds.isEmpty || isCreating)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .padding(.top, 12)
                    }
                    .background(RSMSTheme.surfacePrimary)
                }
            }
            .navigationTitle("Generate Recommended Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RSMSTheme.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func productRow(product: Product, reasons: [String]) -> some View {
        let isSelected = selectedProductIds.contains(product.id)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    toggleSelection(for: product.id)
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? RSMSTheme.primary : RSMSTheme.border)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(.subheadline))
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    Text("SKU: \(product.sku) • ₹\(Int(product.price).formatted())")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    if !reasons.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(reasons, id: \.self) { reason in
                                Text(reason)
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(RSMSTheme.primary.opacity(0.1), in: Capsule())
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
            
            if isSelected {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quantity")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(RSMSTheme.textSecondary)
                        
                        HStack {
                            Button {
                                updateQuantity(for: product.id, by: -1)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            
                            Text("\(productQuantities[product.id, default: 1])")
                                .font(.subheadline.weight(.semibold))
                                .frame(minWidth: 24)
                            
                            Button {
                                updateQuantity(for: product.id, by: 1)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Item note / sizing / fit instructions")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(RSMSTheme.textSecondary)
                        
                        TextField("e.g. Ring size 52, gift package", text: Binding(
                            get: { productNotes[product.id, default: ""] },
                            set: { productNotes[product.id] = $0 }
                        ))
                        .font(.caption)
                        .padding(6)
                        .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(RSMSTheme.border, lineWidth: 1))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    }
                }
                .padding(.leading, 32)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
    }
    
    private func toggleSelection(for id: UUID) {
        withAnimation {
            if selectedProductIds.contains(id) {
                selectedProductIds.remove(id)
            } else {
                selectedProductIds.insert(id)
                if productQuantities[id] == nil {
                    productQuantities[id] = 1
                }
            }
        }
    }
    
    private func updateQuantity(for id: UUID, by value: Int) {
        let current = productQuantities[id, default: 1]
        let next = max(1, current + value)
        productQuantities[id] = next
    }
    
    private func createCart() {
        guard !selectedProductIds.isEmpty else { return }
        isCreating = true
        
        Task {
            do {
                // 1. Create the UniversalCart record
                let cartId = UUID()
                let newCart = UniversalCart(
                    id: cartId,
                    type: .curated,
                    associateId: associateId,
                    clientId: client.id,
                    storeId: client.preferredStoreId ?? dataStore.stores.first?.id,
                    status: .active,
                    note: cartTitle + (cartDescription.isEmpty ? "" : " - \(cartDescription)"),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await dataStore.createUniversalCart(newCart)
                
                // 2. Create the UniversalCartItem records
                for prodId in selectedProductIds {
                    let qty = productQuantities[prodId, default: 1]
                    let note = productNotes[prodId]
                    
                    let item = UniversalCartItem(
                        id: UUID(),
                        cartId: cartId,
                        productId: prodId,
                        quantity: qty,
                        unitPrice: nil, // Will be computed on checkout or display
                        discountApplied: nil,
                        note: note?.isEmpty == false ? note : nil
                    )
                    
                    try await dataStore.createUniversalCartItem(item)
                }
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                }
            }
        }
    }
}
