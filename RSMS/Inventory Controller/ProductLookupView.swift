//
//  ProductLookupView.swift
//  RSMS
//
//  Search and browse all products with live stock status.
//  Scan a barcode to jump directly to a product's detail card.
//

import SwiftUI

struct ProductLookupView: View {

    @Environment(AppViewModel.self) private var appVM
    @State private var searchText = ""
    @State private var selectedProduct: Product? = nil
    @State private var appeared = false

    // Inline barcode scan for quick lookup
    @State private var rawScannedCode: String? = nil
    @State private var showScanner = false

    private let kpiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    kpiSection
                    searchBar
                    productList
                }
                .padding(24)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Product Lookup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScanner.toggle()
                } label: {
                    Image(systemName: "barcode.viewfinder")
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
        .sheet(item: $selectedProduct) { product in
            ProductDetailSheet(
                product: product,
                stockItem: stockItem(for: product)
            )
        }
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                InventoryBarcodeScannerView(initialMode: .verification)
                    .navigationTitle("Scan to Find")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showScanner = false }
                                .foregroundStyle(RSMSTheme.gold)
                        }
                    }
            }
            .environment(appVM)
        }
        .task {
            if appVM.dataStore.products.isEmpty {
                try? await appVM.dataStore.fetchProducts()
            }
            if let sid = appVM.currentStoreId, appVM.dataStore.stockItems.isEmpty {
                try? await appVM.dataStore.fetchStockItems(storeId: sid)
            }
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Filtered Products

    private var filteredProducts: [Product] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return appVM.dataStore.products }
        return appVM.dataStore.products.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.sku.localizedCaseInsensitiveContains(q) ||
            $0.brand.localizedCaseInsensitiveContains(q) ||
            $0.category.localizedCaseInsensitiveContains(q)
        }
    }

    private func stockItem(for product: Product) -> StockItem? {
        appVM.dataStore.stockItems.first {
            $0.productId == product.id && $0.storeId == appVM.currentStoreId
        }
    }

    // MARK: - KPIs

    private var totalSKUs: Int { appVM.dataStore.products.count }
    private var inStockCount: Int {
        appVM.dataStore.stockItems.filter { $0.quantity > 5 && $0.storeId == appVM.currentStoreId }.count
    }
    private var lowStockCount: Int {
        appVM.dataStore.stockItems.filter { $0.quantity > 0 && $0.quantity <= 5 && $0.storeId == appVM.currentStoreId }.count
    }
    private var outOfStockCount: Int {
        appVM.dataStore.products.filter { p in
            let si = stockItem(for: p)
            return si == nil || si!.quantity == 0
        }.count
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Product Lookup")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Search by name, SKU, brand, or category")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    private var kpiSection: some View {
        LazyVGrid(columns: kpiColumns, spacing: 12) {
            kpiTile(icon: "tag.fill", value: "\(totalSKUs)", label: "Total SKUs", color: RSMSTheme.gold)
            kpiTile(icon: "checkmark.circle.fill", value: "\(inStockCount)", label: "In Stock", color: RSMSTheme.success)
            kpiTile(icon: "exclamationmark.triangle.fill", value: "\(lowStockCount)", label: "Low Stock", color: RSMSTheme.warning)
            kpiTile(icon: "xmark.circle.fill", value: "\(outOfStockCount)", label: "Out of Stock", color: RSMSTheme.danger)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    private func kpiTile(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.textTertiary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(RSMSTheme.textTertiary)
            TextField("Name, SKU, brand, category…", text: $searchText)
                .foregroundStyle(RSMSTheme.textPrimary)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
        }
        .padding(14)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    private var productList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PRODUCTS")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(filteredProducts.count) results")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            .padding(.bottom, 10)

            if filteredProducts.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredProducts.enumerated()), id: \.element.id) { index, product in
                        Button {
                            selectedProduct = product
                        } label: {
                            productRow(product)
                        }
                        .buttonStyle(.plain)

                        if index < filteredProducts.count - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        let si = stockItem(for: product)
        let qty = si?.quantity ?? 0
        let statusColor: Color = qty == 0 ? RSMSTheme.danger : qty <= 5 ? RSMSTheme.warning : RSMSTheme.success
        let statusLabel = qty == 0 ? "Out of Stock" : qty <= 5 ? "Low Stock" : "In Stock"

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: categoryIcon(product.category))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(RSMSTheme.gold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(product.sku)
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("·")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(product.brand)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(statusLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
                Text("\(qty) units")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.gold.opacity(0.3))
            Text("No products found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Try a different name, SKU, or brand")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "handbags", "bags":   return "handbag.fill"
        case "watches":             return "watch.analog"
        case "shoes", "heels":      return "shoe.fill"
        case "jewelry", "jewellery": return "sparkles"
        case "dresses", "clothing": return "figure.dress.line.vertical.figure"
        default:                    return "tag.fill"
        }
    }
}

// MARK: - Product Detail Sheet

struct ProductDetailSheet: View {

    let product: Product
    let stockItem: StockItem?
    @Environment(\.dismiss) private var dismiss

    private var qty: Int { stockItem?.quantity ?? 0 }
    private var statusColor: Color {
        qty == 0 ? RSMSTheme.danger : qty <= 5 ? RSMSTheme.warning : RSMSTheme.success
    }
    private var statusLabel: String {
        qty == 0 ? "Out of Stock" : qty <= 5 ? "Low Stock" : "In Stock"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Icon header
                    ZStack {
                        Circle()
                            .fill(RSMSTheme.gold.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "tag.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(RSMSTheme.gold)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 4) {
                        Text(product.name)
                            .font(.title3.bold())
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(product.sku)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(RSMSTheme.gold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(RSMSTheme.gold.opacity(0.08))
                            .clipShape(Capsule())
                    }

                    // Status badge
                    Text(statusLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.12))
                        .clipShape(Capsule())

                    // Product info card
                    VStack(spacing: 0) {
                        detailRow("Brand", product.brand)
                        divider
                        detailRow("Category", product.category)
                        if let sub = product.subcategory {
                            divider
                            detailRow("Subcategory", sub)
                        }
                        divider
                        detailRow("Price", "\(product.currency) \(Int(product.price).formatted())")
                        if let col = product.collection {
                            divider
                            detailRow("Collection", col)
                        }
                        if let mat = product.material {
                            divider
                            detailRow("Material", mat)
                        }
                    }
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))

                    // Stock info card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STOCK DETAILS")
                            .font(.caption.weight(.semibold))
                            .tracking(2)
                            .foregroundStyle(RSMSTheme.gold)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                        VStack(spacing: 0) {
                            detailRow("Quantity", "\(qty) units")
                            if let loc = stockItem?.location {
                                divider
                                detailRow("Location", loc.capitalized)
                            }
                            if let status = stockItem?.status {
                                divider
                                detailRow("Status", status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            }
                            if let scanned = stockItem?.lastScannedAt {
                                divider
                                detailRow("Last Scanned", scanned.formatted(date: .abbreviated, time: .shortened))
                            }
                        }
                    }
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PRODUCT DETAILS")
                        .font(.system(.caption, design: .serif, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var divider: some View {
        Rectangle()
            .fill(RSMSTheme.divider)
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }
}

#Preview {
    ProductLookupView()
        .environment(AppViewModel())
}
