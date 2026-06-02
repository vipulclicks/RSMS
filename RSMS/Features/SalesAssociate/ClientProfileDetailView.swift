//
//  ClientProfileDetailView.swift
//  RSMS
//
//  Rich client profile detail view showing contact, consent,
//  sizing, preferences, wishlist, anniversaries, AI recommendations,
//  and purchase history — powered by real Supabase models.
//

import SwiftUI

enum ClientProfileTab: String, CaseIterable {
    case overview = "Overview"
    case personalInfo = "Personal Info"
    case preferences = "Preferences"
    case purchaseHistory = "Purchase History"
    case notes = "Notes"
}

struct ClientProfileDetailView: View {
    let client: ClientProfile
    let dataStore: DataStore
    let associateId: UUID
    @State private var viewModel: ClientProfileDetailViewModel

    // Tab state
    @State private var selectedTab: ClientProfileTab = .overview

    // Wishlist adding state
    @State private var showAddWishlistSheet = false
    @State private var selectedProductIdForWishlist: UUID? = nil
    @State private var wishlistNotes = ""
    @State private var wishlistSearchText = ""
    
    // Curated Cart state
    @State private var selectedCuratedCart: CuratedCart? = nil
    
    // Guided Catalog navigation state
    @State private var navigateToGuidedCatalog = false
    
    // Wishlist navigation state
    @State private var activeWishlistViewModel: ClientWishlistWorkspaceViewModel? = nil
    
    // Edit profile state
    @State private var showEditClientSheet = false
    
    // AI Look Builder state
    @State private var showAILookBuilder = false
    
    // Receipt viewing state from purchase history
    @State private var showHistoryReceipt = false
    @State private var selectedHistoryOrder: Order?
    @State private var selectedHistoryPaymentId: String = ""
    @State private var showHistoryGiftReceipt = false
    @State private var selectedHistoryGiftReceipt: GiftReceipt?

    private var currentClient: ClientProfile {
        dataStore.clients.first(where: { $0.id == client.id }) ?? client
    }

    init(client: ClientProfile, dataStore: DataStore, associateId: UUID = UUID()) {
        self.client = client
        self.dataStore = dataStore
        self.associateId = associateId
        self._viewModel = State(initialValue: ClientProfileDetailViewModel(client: client, dataStore: dataStore))
    }

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    
                    tabBar
                    
                    switch selectedTab {
                    case .overview:
                        overviewTabContent
                    case .personalInfo:
                        personalInfoTabContent
                    case .preferences:
                        preferencesTabContent
                    case .purchaseHistory:
                        purchaseHistoryTabContent
                    case .notes:
                        notesTabContent
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(currentClient.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .tint(RSMSTheme.primary)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditClientSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
                .foregroundStyle(RSMSTheme.primary)
            }
        }
        .sheet(isPresented: $showAddWishlistSheet) {
            addWishlistSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditClientSheet) {
            EditClientProfileView(client: currentClient, dataStore: dataStore)
        }
        .sheet(isPresented: $showAILookBuilder) {
            AILookBuilderView(client: currentClient, dataStore: dataStore, associateId: associateId)
        }
        .sheet(isPresented: $showHistoryReceipt) {
            if let order = selectedHistoryOrder {
                ReceiptView(
                    order: order,
                    client: currentClient,
                    paymentId: selectedHistoryPaymentId,
                    cartItems: dataStore.universalCartItems.filter { $0.cartId == order.cartId }
                )
            }
        }
        .sheet(isPresented: $showHistoryGiftReceipt) {
            if let gr = selectedHistoryGiftReceipt, let order = selectedHistoryOrder {
                GiftReceiptPreviewView(
                    giftReceipt: gr,
                    order: order,
                    cartItems: dataStore.universalCartItems.filter { $0.cartId == order.cartId }
                )
            }
        }
        .navigationDestination(item: $selectedCuratedCart) { cart in
            ShowroomCartView(mode: .savedCart(cart: cart, dataStore: dataStore))
        }
        .navigationDestination(item: $activeWishlistViewModel) { vm in
            ClientWishlistWorkspaceView(viewModel: vm)
        }
        .navigationDestination(isPresented: $navigateToGuidedCatalog) {
            ProductCatalogView(activeClient: currentClient)
        }
        .task {
            do {
                try await dataStore.fetchProducts()
                try await dataStore.fetchWishlistItems(clientId: client.id)
                try await dataStore.fetchCuratedCartsAndItems(forClient: client.id)
                
                // Fetch transactions, orders, tenders, and gift receipts for client history
                let txns: [Transaction] = (try? await SupabaseClient.shared.fetch("transactions", query: ["client_id": "eq.\(client.id)"])) ?? []
                for txn in txns {
                    if !dataStore.transactions.contains(where: { $0.id == txn.id }) {
                        dataStore.transactions.append(txn)
                    }
                    try? await dataStore.fetchTenders(transactionId: txn.id)
                    try? await dataStore.fetchUniversalCartItems(cartId: txn.cartId)
                    
                    let grs: [GiftReceipt] = (try? await SupabaseClient.shared.fetch("gift_receipts", query: ["transaction_id": "eq.\(txn.id)"])) ?? []
                    for gr in grs {
                        if !dataStore.giftReceipts.contains(where: { $0.id == gr.id }) {
                            dataStore.giftReceipts.append(gr)
                        }
                    }
                }
                
                let ords: [Order] = (try? await SupabaseClient.shared.fetch("orders", query: ["client_id": "eq.\(client.id)"])) ?? []
                for ord in ords {
                    if !dataStore.orders.contains(where: { $0.id == ord.id }) {
                        dataStore.orders.append(ord)
                    }
                }
            } catch {
                print("[ClientProfileDetailView] Error loading data: \(error)")
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(ClientProfileTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .bold : .medium)
                                .foregroundStyle(selectedTab == tab ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? RSMSTheme.primary : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
        .overlay(
            Divider().background(RSMSTheme.divider),
            alignment: .bottom
        )
    }

    // MARK: - Tab Contents

    private var overviewTabContent: some View {
        VStack(spacing: 16) {
            catalogSection
            wishlistSection
            curatedCartsSection
            aiLookBuilderSection
        }
    }
    
    private var personalInfoTabContent: some View {
        VStack(spacing: 16) {
            contactSection
            anniversarySection
        }
    }
    
    private var preferencesTabContent: some View {
        VStack(spacing: 16) {
            sizingSection
            styleSection
            detailedPreferencesSection
        }
    }
    
    private var purchaseHistoryTabContent: some View {
        VStack(spacing: 16) {
            purchaseSummarySection
            purchaseHistoryListSection
        }
    }
    
    // MARK: - Previous Transactions List
    
    @ViewBuilder
    private var purchaseHistoryListSection: some View {
        let transactions = viewModel.clientTransactions.sorted(by: { $0.createdAt > $1.createdAt })
        
        if transactions.isEmpty {
            ProfileCard(title: "Previous Transactions") {
                Text("No past transactions found.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ProfileCard(title: "Previous Transactions") {
                VStack(spacing: 16) {
                    ForEach(transactions) { transaction in
                        transactionRow(for: transaction)
                        
                        if transaction.id != transactions.last?.id {
                            Divider().overlay(RSMSTheme.divider)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func transactionRow(for transaction: Transaction) -> some View {
        let tender = viewModel.dataStore.tenders.first { $0.transactionId == transaction.id }
        let items = viewModel.dataStore.universalCartItems.filter { $0.cartId == transaction.cartId }
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(transaction.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                Text("₹\(Int(transaction.totalAmount).formatted())")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.primary)
            }
            
            HStack {
                Text("Payment ID:")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Text(tender?.reference ?? transaction.id.uuidString.prefix(8).uppercased())
                    .font(.caption.monospaced())
                    .foregroundStyle(RSMSTheme.textTertiary)
                
                Spacer()
                
                Text(transaction.status.rawValue.capitalized)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(viewModel.transactionStatusColor(transaction.status).opacity(0.15), in: Capsule())
                    .foregroundStyle(viewModel.transactionStatusColor(transaction.status))
            }
            
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Products Bought:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    ForEach(items) { item in
                        let product = viewModel.dataStore.products.first(where: { $0.id == item.productId })
                        HStack {
                            Text("\(item.quantity)x")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text(product?.name ?? "Unknown Product")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text("₹\(Int(item.unitPrice ?? product?.price ?? 0).formatted())")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Receipt Actions
            HStack(spacing: 12) {
                // View Customer Receipt
                Button {
                    let order = dataStore.orders.first { $0.transactionId == transaction.id } ?? Order(
                        id: UUID(),
                        clientId: client.id,
                        transactionId: transaction.id,
                        cartId: transaction.cartId,
                        status: .confirmed,
                        totalAmount: transaction.totalAmount,
                        discountAmount: 0,
                        finalAmount: transaction.totalAmount,
                        createdAt: transaction.createdAt
                    )
                    selectedHistoryOrder = order
                    selectedHistoryPaymentId = tender?.reference ?? transaction.id.uuidString.prefix(8).uppercased()
                    showHistoryReceipt = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                        Text("View Receipt")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
                
                // View Gift Receipt
                let grs = dataStore.giftReceipts.filter { $0.transactionId == transaction.id }
                if !grs.isEmpty {
                    Button {
                        selectedHistoryGiftReceipt = grs.first
                        selectedHistoryOrder = dataStore.orders.first { $0.transactionId == transaction.id } ?? Order(
                            id: UUID(),
                            clientId: client.id,
                            transactionId: transaction.id,
                            cartId: transaction.cartId,
                            status: .confirmed,
                            totalAmount: transaction.totalAmount,
                            discountAmount: 0,
                            finalAmount: transaction.totalAmount,
                            createdAt: transaction.createdAt
                        )
                        showHistoryGiftReceipt = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gift")
                            Text(grs.count == 1 ? "Gift Receipt" : "Gift Receipts (\(grs.count))")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.success)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.success.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var notesTabContent: some View {
        VStack(spacing: 16) {
            notesSection
        }
    }

    // MARK: - AI Look Builder

    private var aiLookBuilderSection: some View {
        ProfileCard(title: nil) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Look Builder")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Generate personalized looks based on client history")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                Button {
                    showAILookBuilder = true
                } label: {
                    HStack {
                        Text("Create")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.primary)
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack {
            StatusBadge(
                text: currentClient.vipTier.rawValue.uppercased(),
                color: viewModel.tierColor(currentClient.vipTier)
            )
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Catalog Access

    private var catalogSection: some View {
        ProfileCard(title: nil) {
            VStack(spacing: 16) {
                HStack {
                    Text("Guided Catalog")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    Button {
                        navigateToGuidedCatalog = true
                    } label: {
                        Text("Explore")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.primary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Show a 4-item preview grid to match Wishlist and Curated Carts
                let previewProducts = Array(dataStore.products.prefix(4))
                if !previewProducts.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), alignment: .leading, spacing: 16) {
                        ForEach(previewProducts) { product in
                            Button {
                                navigateToGuidedCatalog = true
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let urlString = product.imageURL, let url = URL(string: urlString) {
                                        Color.clear
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay(
                                                AsyncImage(url: url) { phase in
                                                    if let image = phase.image {
                                                        image.resizable().scaledToFill()
                                                    } else {
                                                        Color.gray.opacity(0.1)
                                                    }
                                                }
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RSMSTheme.border.opacity(0.5), lineWidth: 1))
                                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(RSMSTheme.surfaceSecondary)
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay(Image(systemName: "photo").foregroundStyle(RSMSTheme.textTertiary))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .lineLimit(1)
                                        
                                        Text("₹\(Int(product.price).formatted())")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                }
            }
        }
    }
    // MARK: - Contact

    private var contactSection: some View {
        ProfileCard(title: "Contact Information") {
            VStack(spacing: 16) {
                if let email = currentClient.email {
                    HStack {
                        Label("Email", systemImage: "envelope")
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        Text(email).foregroundStyle(RSMSTheme.textSecondary)
                    }
                    Divider().overlay(RSMSTheme.divider)
                }
                if let phone = currentClient.phone {
                    HStack {
                        Label("Phone", systemImage: "phone")
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        Text(phone).foregroundStyle(RSMSTheme.textSecondary)
                    }
                    Divider().overlay(RSMSTheme.divider)
                }
                HStack {
                    Label("Member Since", systemImage: "calendar")
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    Text(currentClient.createdAt, style: .date).foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Purchase Summary

    private var purchaseSummarySection: some View {
        ProfileCard(title: "Purchase Summary") {
            VStack(spacing: 16) {
                HStack {
                    Text("Lifetime Value")
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    Text(viewModel.lifetimeValueFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(RSMSTheme.primary)
                }
                Divider().overlay(RSMSTheme.divider)
                HStack {
                    Text("Transactions")
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    Text("\(viewModel.clientTransactions.count)")
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Sizing Preferences

    @ViewBuilder
    private var sizingSection: some View {
        if !viewModel.sizePreferences.isEmpty {
            ProfileCard(title: "Sizing Preferences") {
                VStack(spacing: 16) {
                    ForEach(viewModel.sizePreferences, id: \.label) { pref in
                        HStack {
                            Text(pref.label)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Spacer()
                            Text(pref.value)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        if pref.label != viewModel.sizePreferences.last?.label {
                            Divider().overlay(RSMSTheme.divider)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Style Preferences

    @ViewBuilder
    private var styleSection: some View {
        let hasCats = currentClient.favoriteCategories?.isEmpty == false
        let hasMetals = currentClient.favoriteMetals?.isEmpty == false
        let hasGems = currentClient.favoriteGemstones?.isEmpty == false
        
        if hasCats || hasMetals || hasGems {
            ProfileCard(title: "Style Preferences") {
                VStack(spacing: 16) {
                    if let cats = currentClient.favoriteCategories, !cats.isEmpty {
                        CPDPreferenceTagRow(title: "Categories", tags: cats, color: RSMSTheme.primary)
                    }
                    if let metals = currentClient.favoriteMetals, !metals.isEmpty {
                        CPDPreferenceTagRow(title: "Metals", tags: metals,
                                            color: Color(red: 0.788, green: 0.659, blue: 0.298))
                    }
                    if let gems = currentClient.favoriteGemstones, !gems.isEmpty {
                        CPDPreferenceTagRow(title: "Gemstones", tags: gems,
                                            color: Color(red: 0.357, green: 0.435, blue: 0.651))
                    }
                }
            }
        }
    }

    // MARK: - Detailed Preferences

    @ViewBuilder
    private var detailedPreferencesSection: some View {
        if !viewModel.detailedPreferences.isEmpty {
            ProfileCard(title: "Detailed Preferences") {
                VStack(spacing: 16) {
                    ForEach(viewModel.detailedPreferences, id: \.label) { pref in
                        HStack {
                            Text(pref.label)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Spacer()
                            Text(pref.value)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        if pref.label != viewModel.detailedPreferences.last?.label {
                            Divider().overlay(RSMSTheme.divider)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Wishlist

    private var wishlistSection: some View {
        let wishlistItems = dataStore.wishlistItems.filter { $0.clientId == currentClient.id }
        let wishlistProducts = dataStore.products.filter { p in wishlistItems.contains(where: { $0.productId == p.id }) }
        
        return ProfileCard(title: nil) {
            VStack(spacing: 16) {
                HStack {
                    Text("Wishlist")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    if wishlistProducts.count > 0 {
                        Button {
                            activeWishlistViewModel = ClientWishlistWorkspaceViewModel(client: viewModel.currentClient, dataStore: viewModel.dataStore, associateId: associateId)
                        } label: {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if wishlistProducts.isEmpty {
                    Button {
                        activeWishlistViewModel = ClientWishlistWorkspaceViewModel(client: viewModel.currentClient, dataStore: viewModel.dataStore, associateId: associateId)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.dashed")
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text("No items in wishlist")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            Spacer()
                            Text("Add Products")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RSMSTheme.primary)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), alignment: .leading, spacing: 16) {
                        ForEach(wishlistProducts.prefix(4)) { product in
                            Button {
                                activeWishlistViewModel = ClientWishlistWorkspaceViewModel(client: viewModel.currentClient, dataStore: viewModel.dataStore, associateId: associateId)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let urlString = product.imageURL, let url = URL(string: urlString) {
                                        Color.clear
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay(
                                                AsyncImage(url: url) { phase in
                                                    if let image = phase.image {
                                                        image.resizable().scaledToFill()
                                                    } else {
                                                        Color.gray.opacity(0.1)
                                                    }
                                                }
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RSMSTheme.border.opacity(0.5), lineWidth: 1))
                                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(RSMSTheme.surfaceSecondary)
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay(Image(systemName: "photo").foregroundStyle(RSMSTheme.textTertiary))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .lineLimit(1)
                                        
                                        Text("₹\(Int(product.price).formatted())")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Anniversaries

    @ViewBuilder
    private var anniversarySection: some View {
        if !viewModel.clientAnniversaries.isEmpty {
            ProfileCard(title: "Important Dates") {
                VStack(spacing: 16) {
                    ForEach(viewModel.clientAnniversaries) { ann in
                        HStack(spacing: 12) {
                            Image(systemName: ann.reminderEnabled ? "bell.fill" : "bell.slash")
                                .font(.caption)
                                .foregroundStyle(ann.reminderEnabled ? RSMSTheme.primary : RSMSTheme.textTertiary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ann.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text(ann.date, format: .dateTime.day().month(.wide))
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            Spacer()
                            if let notes = ann.notes {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                        if ann.id != viewModel.clientAnniversaries.last?.id {
                            Divider().overlay(RSMSTheme.divider)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        if let notes = currentClient.notes, !notes.isEmpty {
            ProfileCard(title: "Associate Notes") {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ProfileCard(title: "Associate Notes") {
                Text("No notes added.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Add to Wishlist Sheet

    private var addWishlistSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    TextField("Search products...", text: $wishlistSearchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                .padding(12)
                .background(RSMSTheme.background, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                let filtered = dataStore.products.filter {
                    wishlistSearchText.isEmpty ||
                    $0.name.localizedCaseInsensitiveContains(wishlistSearchText) ||
                    $0.sku.localizedCaseInsensitiveContains(wishlistSearchText)
                }

                List {
                    ForEach(filtered) { product in
                        Button {
                            selectedProductIdForWishlist = product.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text("SKU: \(product.sku) • ₹\(Int(product.price).formatted())")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                Spacer()
                                if selectedProductIdForWishlist == product.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(RSMSTheme.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(RSMSTheme.border)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)

                if selectedProductIdForWishlist != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Notes (optional)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textSecondary)
                        TextField("e.g. size/fit preference", text: $wishlistNotes)
                            .padding(10)
                            .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    .padding(16)
                    .background(RSMSTheme.background)
                }

                Button {
                    if let prodId = selectedProductIdForWishlist {
                        Task {
                            await viewModel.addToWishlist(productId: prodId, notes: wishlistNotes)
                            selectedProductIdForWishlist = nil
                            wishlistNotes = ""
                            showAddWishlistSheet = false
                        }
                    }
                } label: {
                    Text("Add to Wishlist")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedProductIdForWishlist != nil ? RSMSTheme.primaryGradient : LinearGradient(colors: [RSMSTheme.border], startPoint: .top, endPoint: .bottom))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
                .disabled(selectedProductIdForWishlist == nil)
            }
            .navigationTitle("Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedProductIdForWishlist = nil
                        wishlistNotes = ""
                        showAddWishlistSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Curated Carts Section

    private var curatedCartsSection: some View {
        let carts = dataStore.curatedCarts(for: currentClient.id)
        
        return ProfileCard(title: nil) {
            VStack(spacing: 16) {
                HStack {
                    Text("Curated Carts")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    if let cart = carts.first, cart.items.count > 0 {
                        Button {
                            selectedCuratedCart = cart
                        } label: {
                            Text("See Details")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let cart = carts.first, !cart.items.isEmpty {
                    let displayItems = Array(cart.items.prefix(4))
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), alignment: .leading, spacing: 16) {
                        ForEach(displayItems) { item in
                            if let product = dataStore.products.first(where: { $0.id == item.productId }) {
                                Button {
                                    selectedCuratedCart = cart
                                } label: {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ZStack(alignment: .bottomLeading) {
                                            if let urlString = product.imageURL, let url = URL(string: urlString) {
                                                Color.clear
                                                    .aspectRatio(1, contentMode: .fit)
                                                    .overlay(
                                                        AsyncImage(url: url) { phase in
                                                            if let image = phase.image {
                                                                image.resizable().scaledToFill()
                                                            } else {
                                                                Color.gray.opacity(0.1)
                                                            }
                                                        }
                                                    )
                                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RSMSTheme.border.opacity(0.5), lineWidth: 1))
                                                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            } else {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(RSMSTheme.surfaceSecondary)
                                                    .aspectRatio(1, contentMode: .fit)
                                                    .overlay(Image(systemName: "photo").foregroundStyle(RSMSTheme.textTertiary))
                                            }
                                            
                                            if let note = item.note, !note.isEmpty, let rx = ClientReaction(rawValue: note) {
                                                Text(rx.rawValue.uppercased())
                                                    .font(.system(size: 8, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(rx.color.opacity(0.85))
                                                    .foregroundStyle(.white)
                                                    .clipShape(Capsule())
                                                    .padding(6)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.name)
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(RSMSTheme.textPrimary)
                                                .lineLimit(1)
                                            
                                            Text("₹\(Int(product.price).formatted())")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(RSMSTheme.textSecondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, alignment: .top)
                            }
                        }
                    }
                } else {
                    Text("Cart is empty")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Reusable Profile Card Component

private struct ProfileCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
            content
                .padding(.horizontal, 16)
                .padding(.bottom, title == nil ? 16 : 20)
                .padding(.top, title == nil ? 16 : 0)
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preference Tag Row

private struct CPDPreferenceTagRow: View {
    let title: String
    let tags: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(color.opacity(0.10), in: Capsule())
                            .overlay(Capsule().stroke(color.opacity(0.20), lineWidth: 1))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let mockStore = DataStore()
    return NavigationStack {
        ClientProfileDetailView(client: .preview, dataStore: mockStore)
    }
}
