//
//  ProductLookupView.swift
//  RSMS
//
//  Unified Lookup & Stock In hub.
//  Tab 1 — Product Lookup: search / barcode-scan products with live stock status.
//  Tab 2 — ASN Matching: receive inventory against an Advanced Shipment Notice.
//

import SwiftUI
import VisionKit
import AVFoundation

// MARK: - Tab Selection

enum LookupTab: String, CaseIterable {
    case productLookup = "Product Lookup"
    case asnMatching   = "ASN Matching"

    var icon: String {
        switch self {
        case .productLookup: return "magnifyingglass"
        case .asnMatching:   return "shippingbox.fill"
        }
    }
}

// MARK: - ProductLookupView (Hub)

struct ProductLookupView: View {

    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedTab: LookupTab = .productLookup

    // Product Lookup state
    @State private var searchText = ""
    @State private var selectedProduct: Product? = nil
    @State private var appeared = false
    @State private var showScanner = false

    // ASN Matching state
    @State private var asnVM = ASNMatchingViewModel()
    @State private var rawScannedASN: String? = nil
    @State private var showASNScanner = false

    // Camera authorization
    @State private var cameraAuthorized = false
    @State private var cameraAuthDenied = false

    private let kpiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Segmented Tab Picker ──────────────────────────────────
                segmentedPicker
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // ── Tab Content ──────────────────────────────────────────
                if selectedTab == .productLookup {
                    productLookupTab
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    asnMatchingTab
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
        }
        .navigationTitle("Lookup & Stock In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if selectedTab == .asnMatching {
                // ASN back button when in review state
                if asnVM.state == .matched {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { asnVM.reset() }
                            .foregroundStyle(RSMSTheme.gold)
                    }
                }
            }
        }
        // ── Product Lookup sheets ────────────────────────────────────────
        .fullScreenCover(item: $selectedProduct) { product in
            ProductDetailSheet(
                product: product,
                stockItem: stockItem(for: product)
            )
        }
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                InventoryBarcodeScannerView(initialMode: .verification) { product in
                    showScanner = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedProduct = product
                    }
                }
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
        // ── ASN Scanner sheet ────────────────────────────────────────────
        .onChange(of: rawScannedASN) { _, code in
            guard let code else { return }
            rawScannedASN = nil
            asnVM.asnQuery = code
            Task {
                if let storeId = appVM.currentStoreId {
                    await asnVM.fetchAndSearch(in: appVM.dataStore, storeId: storeId)
                }
            }
            showASNScanner = false
        }
        .sheet(isPresented: $showASNScanner) {
            NavigationStack {
                asnScannerView
                    .navigationTitle("Scan ASN Label")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showASNScanner = false }
                                .foregroundStyle(RSMSTheme.gold)
                        }
                    }
            }
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

    // MARK: - Segmented Picker

    private var segmentedPicker: some View {
        HStack(spacing: 4) {
            ForEach(LookupTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? RSMSTheme.background : RSMSTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == tab
                            ? RSMSTheme.gold
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Product Lookup Tab

    private var productLookupTab: some View {
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

    // MARK: - ASN Matching Tab

    private var asnMatchingTab: some View {
        Group {
            switch asnVM.state {
            case .idle, .notFound:
                asnSearchView
            case .matched:
                asnReviewView
            case .confirmed:
                asnConfirmedView
            case .error(let msg):
                asnErrorView(message: msg)
            }
        }
        .animation(.spring(response: 0.35), value: asnVM.state)
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
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Search and browse all products with live stock status")
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
                .font(.system(size: 24, weight: .bold))
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
            
            Button(action: { showScanner = true }) {
                Image(systemName: "barcode.viewfinder")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(RSMSTheme.background)
                    .frame(width: 50, height: 50)
                    .background(RSMSTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
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
                
                if let urlString = product.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: categoryIcon(product.category))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(RSMSTheme.gold)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: categoryIcon(product.category))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(RSMSTheme.gold)
                }
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

    // MARK: - ASN Search View

    private var asnSearchView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Enter ASN Number")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Type or scan the ASN label from the incoming shipment")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }

                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        TextField("e.g. ASN-2026-05-987654", text: $asnVM.asnQuery)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .font(.body.monospaced())
                            .padding(14)
                            .background(RSMSTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(RSMSTheme.gold.opacity(0.3), lineWidth: 1)
                            )
                            .onSubmit { submitASNSearch() }

                        Button(action: { showASNScanner = true }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(RSMSTheme.background)
                                .frame(width: 50, height: 50)
                                .background(RSMSTheme.gold)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button(action: submitASNSearch) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("Search Shipment")
                                .font(.headline)
                        }
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            asnVM.asnQuery.trimmingCharacters(in: .whitespaces).isEmpty
                                ? RSMSTheme.gold.opacity(0.4)
                                : RSMSTheme.gold
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(asnVM.asnQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )

                if asnVM.state == .notFound {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(RSMSTheme.warning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Shipment Not Found")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("No in-transit ASN matches \"\(asnVM.asnQuery)\" for this store.")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                    .padding(16)
                    .background(RSMSTheme.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(RSMSTheme.warning.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(24)
        }
    }

    // MARK: - ASN Review View

    private var asnReviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let movement = asnVM.matchedMovement {
                    asnMovementHeaderCard(movement)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("LINE ITEMS")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(RSMSTheme.gold)
                        Spacer()
                        Text("\(asnVM.lineItems.count) products")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(asnVM.lineItems.enumerated()), id: \.element.id) { index, lineItem in
                            asnLineItemRow(lineItem)
                            if index < asnVM.lineItems.count - 1 {
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

                Button {
                    Task {
                        if let storeId = appVM.currentStoreId, let user = appVM.currentUser {
                            await asnVM.receive(
                                dataStore: appVM.dataStore,
                                user: user,
                                storeId: storeId
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if asnVM.isSubmitting {
                            ProgressView().tint(RSMSTheme.background)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm Receipt")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(RSMSTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(RSMSTheme.success)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(asnVM.isSubmitting)
            }
            .padding(24)
        }
    }

    private func asnMovementHeaderCard(_ movement: InventoryMovement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(movement.asnNumber ?? "—")
                        .font(.title3.bold().monospaced())
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(movement.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                Spacer()
                Text("IN TRANSIT")
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(RSMSTheme.warning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RSMSTheme.warning.opacity(0.12))
                    .clipShape(Capsule())
            }

            Rectangle().fill(RSMSTheme.divider).frame(height: 0.5)

            HStack(spacing: 24) {
                asnInfoChip(label: "SOURCE", value: movement.sourceId)
                asnInfoChip(label: "EXPECTED", value: "\(movement.itemsExpected ?? asnVM.lineItems.count) items")
                if let shipped = movement.shippedAt {
                    asnInfoChip(label: "SHIPPED", value: shipped.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .padding(18)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    private func asnInfoChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .lineLimit(1)
        }
    }

    private func asnLineItemRow(_ lineItem: ASNLineItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                if let urlString = lineItem.product.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: asnCategoryIcon(lineItem.product.category))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(RSMSTheme.gold)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: asnCategoryIcon(lineItem.product.category))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(RSMSTheme.gold)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(lineItem.product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                Text("Expected: \(lineItem.expectedQty) units")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    let current = asnVM.receivedQtys[lineItem.id] ?? lineItem.expectedQty
                    if current > 0 { asnVM.receivedQtys[lineItem.id] = current - 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(width: 32, height: 32)
                }

                Text("\(asnVM.receivedQtys[lineItem.id] ?? lineItem.expectedQty)")
                    .font(.subheadline.bold())
                    .foregroundStyle(
                        (asnVM.receivedQtys[lineItem.id] ?? lineItem.expectedQty) == lineItem.expectedQty
                            ? RSMSTheme.success
                            : RSMSTheme.warning
                    )
                    .frame(minWidth: 28, alignment: .center)

                Button {
                    let current = asnVM.receivedQtys[lineItem.id] ?? lineItem.expectedQty
                    asnVM.receivedQtys[lineItem.id] = current + 1
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .background(RSMSTheme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - ASN Confirmed View

    private var asnConfirmedView: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.success.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(RSMSTheme.success)
                    .symbolEffect(.bounce, value: asnVM.state == .confirmed)
            }
            VStack(spacing: 8) {
                Text("Shipment Received")
                    .font(.title2.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Inventory has been updated in Supabase")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            VStack(spacing: 0) {
                asnSummaryRow(label: "ASN Number", value: asnVM.matchedMovement?.asnNumber ?? "—")
                Rectangle().fill(RSMSTheme.divider).frame(height: 0.5).padding(.horizontal, 16)
                asnSummaryRow(label: "Items Received", value: "\(asnVM.totalReceived) / \(asnVM.totalExpected)")
                Rectangle().fill(RSMSTheme.divider).frame(height: 0.5).padding(.horizontal, 16)
                asnSummaryRow(
                    label: "Variances Raised",
                    value: "\(asnVM.varianceCount)",
                    valueColor: asnVM.varianceCount > 0 ? RSMSTheme.warning : RSMSTheme.success
                )
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
            .padding(.horizontal, 24)

            Button("Receive Another Shipment") {
                withAnimation(.spring(response: 0.35)) { asnVM.reset() }
            }
            .font(.headline)
            .foregroundStyle(RSMSTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RSMSTheme.gold)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func asnSummaryRow(label: String, value: String, valueColor: Color = RSMSTheme.textPrimary) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(RSMSTheme.textTertiary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - ASN Error View

    private func asnErrorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.danger)
            Text("Something went wrong")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Try Again") { asnVM.reset() }
                .font(.headline)
                .foregroundStyle(RSMSTheme.gold)
        }
        .padding(32)
    }

    // MARK: - ASN Camera Scanner

    private var asnScannerView: some View {
        ZStack(alignment: .bottom) {
            RSMSTheme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                if cameraAuthDenied {
                    // Permission denied — show settings link
                    VStack(spacing: 14) {
                        Image(systemName: "camera.slash.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(RSMSTheme.gold.opacity(0.5))
                        Text("Camera Access Required")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Please allow camera access in Settings to scan ASN labels.")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.background)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.gold)
                        .clipShape(Capsule())
                    }
                    .padding()
                } else if !cameraAuthorized {
                    ProgressView().tint(RSMSTheme.gold)
                        .padding(.top, 80)
                } else if DataScannerViewController.isSupported {
                    DataScannerRepresentable { code in 
                        rawScannedASN = code 
                    }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(RSMSTheme.border, lineWidth: 1)
                        )
                        .frame(maxHeight: 360)
                        .padding()
                } else {
                    Text("Camera scanner unavailable on this device")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .padding()
                }
                Text("Point the camera at the ASN barcode on the shipment label")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
            }
        }
        .task {
            await requestCameraAccess()
        }
    }

    // MARK: - Camera Permission

    @MainActor
    private func requestCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorized = granted
            cameraAuthDenied = !granted
        case .denied, .restricted:
            cameraAuthorized = false
            cameraAuthDenied = true
        @unknown default:
            cameraAuthorized = false
            cameraAuthDenied = true
        }
    }

    // MARK: - ASN Helpers

    private func submitASNSearch() {
        Task {
            if let storeId = appVM.currentStoreId {
                await asnVM.fetchAndSearch(in: appVM.dataStore, storeId: storeId)
            }
        }
    }

    private func asnCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "handbags", "leather goods": return "handbag.fill"
        case "watches":                   return "watch.analog"
        case "shoes", "heels":            return "shoe.fill"
        case "jewelry", "jewellery":      return "sparkles"
        case "accessories":               return "eyeglasses"
        case "fragrances":                return "bubbles.and.sparkles"
        default:                          return "shippingbox.fill"
        }
    }
}

// MARK: - Product Detail Sheet

struct ProductDetailSheet: View {

    let product: Product
    let stockItem: StockItem?
    var shelfLocation: String? = nil
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
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Product image card (premium luxury standard)
                        if let urlString = product.imageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                progressPlaceholder
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(RSMSTheme.border, lineWidth: 1)
                            )
                        } else {
                            // High-end placeholder when no image URL exists
                            fallbackImagePlaceholder
                        }

                        // Product Title & SKU
                        VStack(spacing: 6) {
                            Text(product.brand.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .tracking(3)
                                .foregroundStyle(RSMSTheme.gold)

                            Text(product.name)
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(product.sku)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(RSMSTheme.textTertiary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(RSMSTheme.surfacePrimary)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 0.5))
                        }

                        // Status Badge
                        HStack {
                            Text(statusLabel)
                                .font(.caption.weight(.bold))
                                .tracking(0.5)
                                .foregroundStyle(statusColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(statusColor.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        // Product Details Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SPECIFICATIONS")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(RSMSTheme.gold)
                                .padding(.horizontal, 16)
                                .padding(.top, 14)

                            VStack(spacing: 0) {
                                if let loc = shelfLocation {
                                    detailRow("Shelf Location", loc)
                                    divider
                                }
                                detailRow("Category", product.category)
                                divider
                                if let sub = product.subcategory {
                                    detailRow("Subcategory", sub)
                                    divider
                                }
                                detailRow("Retail Price", "\(product.currency) \(Int(product.price).formatted())")
                                divider
                                if let col = product.collection {
                                    detailRow("Collection", col)
                                    divider
                                }
                                if let mat = product.material {
                                    detailRow("Material", mat)
                                    divider
                                }
                                if let desc = product.description, !desc.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Description")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                        Text(desc)
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 13)
                                }
                            }
                        }
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))

                        // Stock Info Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("BOUTIQUE INVENTORY STATUS")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(RSMSTheme.gold)
                                .padding(.horizontal, 16)
                                .padding(.top, 14)

                            VStack(spacing: 0) {
                                detailRow("Current Stock Level", "\(qty) units")
                                divider
                                if let loc = stockItem?.location {
                                    detailRow("Display Location", loc.uppercased())
                                    divider
                                }
                                if let status = stockItem?.status {
                                    detailRow("Inventory Status", status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    divider
                                }
                                if let scanned = stockItem?.lastScannedAt {
                                    detailRow("Last Scanned / Verified", scanned.formatted(date: .abbreviated, time: .shortened))
                                }
                            }
                        }
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))

                        // Authenticity Certificate Action
                        NavigationLink {
                            AuthCertificateGeneratorView(preselectedProduct: product)
                        } label: {
                            HStack {
                                Text("Generate Authenticity Certificate")
                                    .font(.headline)
                            }
                            .foregroundStyle(RSMSTheme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(RSMSTheme.gold)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("PRODUCT DETAILS")
                        .font(.system(.caption, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
    }

    // MARK: - Premium Placeholders

    private var progressPlaceholder: some View {
        ZStack {
            RSMSTheme.surfacePrimary
            ProgressView()
                .tint(RSMSTheme.gold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    private var fallbackImagePlaceholder: some View {
        ZStack {
            RSMSTheme.surfacePrimary

            VStack(spacing: 12) {
                Image(systemName: categoryIcon(product.category))
                    .font(.system(size: 48))
                    .foregroundStyle(RSMSTheme.gold.opacity(0.8))
                
                Text("Luxury Collection Asset")
                    .font(.system(.caption, design: .serif))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
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
