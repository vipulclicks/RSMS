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
            consentSection
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
                        Image(systemName: "sparkles")
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
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.primary.opacity(0.12))
                    .frame(width: 80, height: 80)
                Text(viewModel.initials)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(RSMSTheme.primary)
            }
            .padding(.top, 16)

            Text(currentClient.fullName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
                .multilineTextAlignment(.center)

            StatusBadge(
                text: currentClient.vipTier.rawValue.uppercased(),
                color: viewModel.tierColor(currentClient.vipTier)
            )
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

    // MARK: - Consent Banner

    private var consentSection: some View {
        HStack(spacing: 12) {
            Image(systemName: currentClient.privacyConsentGiven
                  ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .font(.title2)
                .foregroundStyle(currentClient.privacyConsentGiven ? RSMSTheme.success : RSMSTheme.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text(currentClient.privacyConsentGiven
                      ? "Privacy Consent Given" : "Privacy Consent Not Given")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(currentClient.privacyConsentGiven
                                     ? RSMSTheme.success : RSMSTheme.warning)
                if currentClient.privacyConsentGiven, let date = currentClient.consentDate {
                    Text("Consented on \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } else if !currentClient.privacyConsentGiven {
                    Text("Client data cannot be used for marketing.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(
            (currentClient.privacyConsentGiven ? RSMSTheme.success : RSMSTheme.warning).opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke((currentClient.privacyConsentGiven ? RSMSTheme.success : RSMSTheme.warning).opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 16)
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
