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
    var activeClient: ClientProfile? = nil
    
    @State private var viewModel: ProductCatalogViewModel?
    @State private var selectedProduct: Product?
    @State private var showFilterSheet = false
    @State private var showClientPickerSheet = false
    
    // Custom premium toast states
    @State private var toastMessage: String? = nil
    @State private var showToast = false
    @State private var toastTimer: Timer? = nil

    private func triggerToast(message: String) {
        toastTimer?.invalidate()
        toastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showToast = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showToast = false
            }
        }
    }

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            if let vm = viewModel {
                catalogContent(vm)
            } else {
                ProgressView()
                    .tint(RSMSTheme.primary)
            }
            
            // Premium glassmorphic toast notification
            if showToast, let message = toastMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20, weight: .bold))
                        Text(message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(RSMSTheme.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(RSMSTheme.surfacePrimary)
                            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .zIndex(100)
            }
        }
        .navigationTitle(activeClient != nil ? "Guided Catalog" : "Product Catalog")
        .navigationBarTitleDisplayMode(.large)
        .task {
            guard viewModel == nil else { return }
            let vm = ProductCatalogViewModel(
                dataStore: appViewModel.dataStore,
                storeId: appViewModel.currentUser?.storeId,
                activeClient: activeClient,
                associateId: appViewModel.currentUser?.id
            )
            await vm.load()
            viewModel = vm
        }
        .onAppear {
            // Re-fetch stock items every time the catalog becomes visible
            // so that completed transfers are reflected immediately
            Task {
                if let storeId = appViewModel.currentUser?.storeId {
                    try? await appViewModel.dataStore.fetchStockItems(storeId: storeId)
                }
            }
        }
        .sheet(item: $selectedProduct) { product in
            if let vm = viewModel {
                CatalogProductDetailSheet(
                    product: product,
                    stockQuantity: vm.stockQuantity(for: product.id),
                    onAddToCart: {
                        if vm.isInCart(product.id) {
                            triggerToast(message: "\(product.name) already exists in the cart")
                        } else {
                            vm.addToCart(product)
                            triggerToast(message: "\(product.name) added to curated cart")
                        }
                    },
                    activeClient: vm.activeClient,
                    isWishlisted: vm.isProductInWishlist(product.id),
                    sizeLabel: vm.clientSizeLabel(for: product),
                    isPreferenceMatch: vm.activeClient != nil ? vm.hasPreferenceMatch(for: product, client: vm.activeClient!) : false,
                    onWishlistToggle: {
                        Task {
                            await vm.toggleWishlist(for: product)
                        }
                    },
                    isInCart: vm.isInCart(product.id)
                )
            }
        }
        .sheet(isPresented: $showClientPickerSheet) {
            ClientSelectionSheet(onSelect: { client in
                if let vm = viewModel {
                    Task {
                        await vm.selectClient(client)
                    }
                }
                showClientPickerSheet = false
            })
        }
    }

    // MARK: - Catalog Content

    @ViewBuilder
    private func catalogContent(_ vm: ProductCatalogViewModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
                clientContextBanner(vm)
                
                if vm.activeClient != nil && !vm.recommendedProducts.isEmpty {
                    curatedRecommendationsCarousel(vm)
                }
                
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
                                     onClear: { vm.clearCart() },
                                     viewModel: vm)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vm.cartItems.count)
    }

    // MARK: - Client Context Banner

    @ViewBuilder
    private func clientContextBanner(_ vm: ProductCatalogViewModel) -> some View {
        if let client = vm.activeClient {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Text(client.fullName.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(client.fullName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(RSMSTheme.primary)
                    
                    Text("UPDATED \(Date().formatted(date: .abbreviated, time: .omitted).uppercased())")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .tracking(1.0)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }

    private func nextMilestoneText(for client: ClientProfile) -> String {
        let anns = appViewModel.dataStore.clientAnniversaries.filter { $0.clientId == client.id }
        guard !anns.isEmpty else {
            if let notes = client.notes, notes.localizedCaseInsensitiveContains("anniversary") || notes.localizedCaseInsensitiveContains("gala") {
                return notes
            }
            return ""
        }
        
        let cal = Calendar.current
        let now = Date.now
        
        let soonest = anns.compactMap { ann -> (ClientAnniversary, Int)? in
            let components = cal.dateComponents([.month, .day], from: ann.date)
            guard let next = cal.nextDate(after: now, matching: components, matchingPolicy: .nextTime) else { return nil }
            let diff = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: next)).day ?? 999
            return (ann, diff)
        }
        .sorted { $0.1 < $1.1 }
        .first
        
        if let (ann, days) = soonest {
            if days == 0 {
                return "🎁 \(ann.title) is TODAY!"
            } else if days == 1 {
                return "🎁 \(ann.title) is tomorrow"
            } else if days <= 30 {
                return "🎁 \(ann.title) in \(days) days"
            }
        }
        return ""
    }

    // MARK: - Curated Recommendations Carousel

    @ViewBuilder
    private func curatedRecommendationsCarousel(_ vm: ProductCatalogViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended For This Client")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(vm.recommendedProducts) { product in
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(RSMSTheme.primary.opacity(0.04))
                                    .frame(width: 140, height: 100)
                                
                                if let urlString = product.imageURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        if let img = phase.image {
                                            img.resizable()
                                                .scaledToFill()
                                                .frame(width: 140, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            Image(systemName: product.categoryIconName)
                                                .font(.title2)
                                                .foregroundStyle(RSMSTheme.primary.opacity(0.2))
                                                .frame(width: 140, height: 100)
                                        }
                                    }
                                } else {
                                    Image(systemName: product.categoryIconName)
                                        .font(.title2)
                                        .foregroundStyle(RSMSTheme.primary.opacity(0.2))
                                        .frame(width: 140, height: 100)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .lineLimit(1)
                                
                                Text(product.brand)
                                    .font(.system(size: 10))
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                
                                Text("₹\(Int(product.price).formatted())")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            .frame(width: 140, alignment: .leading)
                        }
                        .onTapGesture {
                            selectedProduct = product
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
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
        .padding(.top, 16)
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
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 24)],
                      spacing: 24) {
                ForEach(vm.filteredProducts) { product in
                    ProductCatalogCard(
                        product: product,
                        stockQty: vm.stockQuantity(for: product.id),
                        isInCart: vm.isInCart(product.id),
                        activeClient: vm.activeClient,
                        isWishlisted: vm.isProductInWishlist(product.id),
                        sizeLabel: vm.clientSizeLabel(for: product),
                        isPreferenceMatch: vm.activeClient != nil ? vm.hasPreferenceMatch(for: product, client: vm.activeClient!) : false,
                        onWishlistToggle: {
                            Task {
                                await vm.toggleWishlist(for: product)
                            }
                        }
                    )
                    .onTapGesture { selectedProduct = product }
                    .overlay(alignment: .topTrailing) {
                        let stockQty = vm.stockQuantity(for: product.id)
                        let isInCart = vm.isInCart(product.id)
                        Group {
                            if stockQty > 0 || isInCart {
                                Button {
                                    if vm.isInCart(product.id) {
                                        triggerToast(message: "\(product.name) already exists in the cart")
                                    } else {
                                        vm.toggleCartItem(product)
                                        triggerToast(message: "\(product.name) added to curated cart")
                                    }
                                } label: {
                                    Image(systemName: vm.isInCart(product.id) ? "checkmark.circle.fill" : "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(vm.isInCart(product.id) ? Color.green : RSMSTheme.primary)
                                        .background(Circle().fill(RSMSTheme.cream))
                                        .scaleEffect(vm.isInCart(product.id) ? 1.25 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: vm.isInCart(product.id))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(10)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, vm.cartItems.count > 0 ? 100 : 40)
        }
    }

    // Filter functionality has been removed in favor of a minimal UI
}

// MARK: - Product Catalog Card

struct ProductCatalogCard: View {
    let product: Product
    let stockQty: Int
    let isInCart: Bool
    
    let activeClient: ClientProfile?
    let isWishlisted: Bool
    let sizeLabel: String?
    let isPreferenceMatch: Bool
    let onWishlistToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Product image
            ZStack(alignment: .topLeading) {
                productImage
                
                if activeClient != nil {
                    Button {
                        onWishlistToggle()
                    } label: {
                        Image(systemName: isWishlisted ? "heart.fill" : "heart")
                            .font(.system(size: 15))
                            .foregroundStyle(isWishlisted ? Color.red : RSMSTheme.primary)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.85)))
                            .shadow(color: .black.opacity(0.08), radius: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(product.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)

                Text(product.brand)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                if activeClient != nil {
                    HStack(spacing: 6) {
                        if let size = sizeLabel {
                            Text(size)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(RSMSTheme.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RSMSTheme.surfaceSecondary, in: Capsule())
                        }
                        
                        if isPreferenceMatch {
                            Text("✦ STYLE MATCH")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(RSMSTheme.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RSMSTheme.primary.opacity(0.08), in: Capsule())
                        }
                    }
                }

                HStack {
                    Text(product.formattedPrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(RSMSTheme.primary)
                    Spacer()
                    StockBadge(quantity: stockQty)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(RSMSTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isInCart ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var productImage: some View {
        ZStack {
            Rectangle()
                .fill(RSMSTheme.surfaceSecondary)
                .frame(height: 220)

            if let urlString = product.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipped()
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
        Text(statusText.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(1.0)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor, in: Capsule())
            .shadow(color: statusColor.opacity(0.35), radius: 3, x: 0, y: 1.5)
    }

    private var statusColor: Color {
        if quantity == 0 { return RSMSTheme.danger }
        if quantity <= 3 { return RSMSTheme.warning }
        return RSMSTheme.success
    }

    private var statusText: String {
        if quantity == 0 { return "Out Of Stock" }
        if quantity <= 3 { return "Few Left" }
        return "In Stock"
    }
}

// MARK: - Catalog Cart Badge (Mini floating bar)

struct CatalogCartBadge: View {
    let count: Int
    let dataStore: DataStore
    let items: [CartSelectionItem]
    let onClear: () -> Void
    var viewModel: ProductCatalogViewModel? = nil

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
            CartSelectionPreviewSheet(items: items, dataStore: dataStore, onClear: onClear, viewModel: viewModel)
        }
    }
}

// MARK: - Cart Selection Preview Sheet

struct CartSelectionPreviewSheet: View {
    let items: [CartSelectionItem]
    let dataStore: DataStore
    let onClear: () -> Void
    var viewModel: ProductCatalogViewModel? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    if let product = dataStore.product(by: item.productId) {
                        HStack(spacing: 12) {
                            if let urlString = product.imageURL, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.gray.opacity(0.1)
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border.opacity(0.5), lineWidth: 1))
                            } else {
                                Image(systemName: product.categoryIconName)
                                    .font(.title3)
                                    .foregroundStyle(RSMSTheme.primary)
                                    .frame(width: 48, height: 48)
                                    .background(RSMSTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text(product.formattedPrice)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            Spacer()
                            
                            // Remove individual item
                            if let vm = viewModel {
                                Button {
                                    vm.removeFromCart(product.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Curated Cart (\(items.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear All") { onClear() }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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
    
    let activeClient: ClientProfile?
    let isWishlisted: Bool
    let sizeLabel: String?
    let isPreferenceMatch: Bool
    let onWishlistToggle: () -> Void
    let isInCart: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var addedToCart: Bool

    init(product: Product, stockQuantity: Int, onAddToCart: @escaping () -> Void, activeClient: ClientProfile?, isWishlisted: Bool, sizeLabel: String?, isPreferenceMatch: Bool, onWishlistToggle: @escaping () -> Void, isInCart: Bool) {
        self.product = product
        self.stockQuantity = stockQuantity
        self.onAddToCart = onAddToCart
        self.activeClient = activeClient
        self.isWishlisted = isWishlisted
        self.sizeLabel = sizeLabel
        self.isPreferenceMatch = isPreferenceMatch
        self.onWishlistToggle = onWishlistToggle
        self.isInCart = isInCart
        self._addedToCart = State(initialValue: isInCart)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        heroImage
                        
                        if activeClient != nil {
                            clientellingContextBox
                        }
                        
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

    private var clientellingContextBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clientelling Insights")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
                
            HStack(spacing: 12) {
                if let size = sizeLabel {
                    Label(size, systemImage: "ruler")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RSMSTheme.surfaceSecondary, in: Capsule())
                }
                
                if isPreferenceMatch {
                    Label("Style Match", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RSMSTheme.primary.opacity(0.08), in: Capsule())
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
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
            HStack(spacing: 12) {
                if activeClient != nil {
                    Button {
                        onWishlistToggle()
                    } label: {
                        HStack {
                            Text(isWishlisted ? "Wishlisted" : "Add to Wishlist")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isWishlisted ? Color.red : RSMSTheme.primary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isWishlisted ? Color.red.opacity(0.3) : RSMSTheme.primary.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                if stockQuantity == 0 {
                    Button {
                        // Out of stock, action disabled
                    } label: {
                        Text("Out of Stock")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(RSMSTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(true)
                } else {
                    Button {
                        onAddToCart()
                        addedToCart = true
                    } label: {
                        Text(addedToCart ? "Added" : "Add to Cart")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RSMSTheme.cream)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(addedToCart ? AnyShapeStyle(Color.green) : AnyShapeStyle(RSMSTheme.primaryGradient))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(addedToCart)
                }
            }
            
            if stockQuantity == 0 {
                NavigationLink(destination: InventorySourcingRequestFormView(product: product)) {
                    Text("Request Item From Another Store")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.primary.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Client Selection Sheet

struct ClientSelectionSheet: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    let onSelect: (ClientProfile) -> Void
    @State private var searchText = ""
    
    var filteredClients: [ClientProfile] {
        let clients = appViewModel.dataStore.clients
        guard !searchText.isEmpty else { return clients }
        return clients.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredClients) { client in
                    Button {
                        onSelect(client)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(RSMSTheme.primary.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Text(client.fullName.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.fullName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text(client.vipTier.rawValue.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search clients...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
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
