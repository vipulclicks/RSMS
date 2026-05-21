//
//  ClientProfileDetailView.swift
//  RSMS
//
//  Rich client profile detail view showing contact, consent,
//  sizing, preferences, wishlist, anniversaries, AI recommendations,
//  and purchase history — powered by real Supabase models.
//

import SwiftUI

struct ClientProfileDetailView: View {
    let client: ClientProfile
    let dataStore: DataStore
    @State private var viewModel: ClientProfileDetailViewModel

    // Wishlist adding state
    @State private var showAddWishlistSheet = false
    @State private var selectedProductIdForWishlist: UUID? = nil
    @State private var wishlistNotes = ""
    @State private var wishlistSearchText = ""

    init(client: ClientProfile, dataStore: DataStore) {
        self.client = client
        self.dataStore = dataStore
        self._viewModel = State(initialValue: ClientProfileDetailViewModel(client: client, dataStore: dataStore))
    }

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            List {
                heroSection
                consentSection
                contactSection
                purchaseSummarySection
                sizingSection
                styleSection
                detailedPreferencesSection
                wishlistSection
                anniversarySection
                recommendationsSection
                notesSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(client.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .tint(RSMSTheme.primary)
        .sheet(isPresented: $showAddWishlistSheet) {
            addWishlistSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        Section {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Text(viewModel.initials)
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundStyle(RSMSTheme.primary)
                }
                .padding(.top, 16)

                Text(client.fullName)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .multilineTextAlignment(.center)

                StatusBadge(
                    text: client.vipTier.rawValue.uppercased(),
                    color: viewModel.tierColor(client.vipTier)
                )
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - Consent Banner

    private var consentSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: client.privacyConsentGiven
                      ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(client.privacyConsentGiven ? RSMSTheme.success : RSMSTheme.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text(client.privacyConsentGiven
                         ? "Privacy Consent Given" : "Privacy Consent Not Given")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(client.privacyConsentGiven
                                         ? RSMSTheme.success : RSMSTheme.warning)
                    if client.privacyConsentGiven, let date = client.consentDate {
                        Text("Consented on \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    } else if !client.privacyConsentGiven {
                        Text("Client data cannot be used for marketing.")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(
                (client.privacyConsentGiven ? RSMSTheme.success : RSMSTheme.warning).opacity(0.08),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke((client.privacyConsentGiven ? RSMSTheme.success : RSMSTheme.warning).opacity(0.25), lineWidth: 1)
            )
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - Contact

    private var contactSection: some View {
        Section("Contact Information") {
            if let email = client.email {
                LabeledContent {
                    Text(email).foregroundStyle(RSMSTheme.textSecondary)
                } label: {
                    Label("Email", systemImage: "envelope")
                }
            }
            if let phone = client.phone {
                LabeledContent {
                    Text(phone).foregroundStyle(RSMSTheme.textSecondary)
                } label: {
                    Label("Phone", systemImage: "phone")
                }
            }
            LabeledContent {
                Text(client.createdAt, style: .date).foregroundStyle(RSMSTheme.textSecondary)
            } label: {
                Label("Member Since", systemImage: "calendar")
            }
        }
    }

    // MARK: - Purchase Summary

    private var purchaseSummarySection: some View {
        Section("Purchase Summary") {
            LabeledContent("Lifetime Value") {
                Text(viewModel.lifetimeValueFormatted)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(RSMSTheme.primary)
            }
            LabeledContent("Transactions") {
                Text("\(viewModel.clientTransactions.count)")
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
    }

    // MARK: - Sizing Preferences

    @ViewBuilder
    private var sizingSection: some View {
        if !viewModel.sizePreferences.isEmpty {
            Section("Sizing Preferences") {
                ForEach(viewModel.sizePreferences, id: \.label) { pref in
                    LabeledContent(pref.label) {
                        Text(pref.value).foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Style Preferences

    private var styleSection: some View {
        Section("Style Preferences") {
            if let cats = client.favoriteCategories, !cats.isEmpty {
                CPDPreferenceTagRow(title: "Categories", tags: cats, color: RSMSTheme.primary)
            }
            if let metals = client.favoriteMetals, !metals.isEmpty {
                CPDPreferenceTagRow(title: "Metals", tags: metals,
                                    color: Color(red: 0.788, green: 0.659, blue: 0.298))
            }
            if let gems = client.favoriteGemstones, !gems.isEmpty {
                CPDPreferenceTagRow(title: "Gemstones", tags: gems,
                                    color: Color(red: 0.357, green: 0.435, blue: 0.651))
            }
        }
    }

    // MARK: - Detailed Preferences

    @ViewBuilder
    private var detailedPreferencesSection: some View {
        if !viewModel.detailedPreferences.isEmpty {
            Section("Detailed Preferences") {
                ForEach(viewModel.detailedPreferences, id: \.label) { pref in
                    LabeledContent(pref.label) {
                        Text(pref.value).foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Wishlist

    private var wishlistSection: some View {
        Section {
            if viewModel.clientWishlist.isEmpty {
                Text("No wishlist items")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            } else {
                ForEach(viewModel.clientWishlist) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.primary.opacity(0.6))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.productName(for: item.productId))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            if let notes = item.notes {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                        Spacer()
                        if !item.isAvailable {
                            StatusBadge(text: "Out of Stock", color: RSMSTheme.warning)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.removeFromWishlist(itemId: item.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Wishlist")
                Spacer()
                Button {
                    showAddWishlistSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Item")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.primary)
                }
            }
        }
    }

    // MARK: - Anniversaries

    private var anniversarySection: some View {
        Section("Important Dates") {
            if viewModel.clientAnniversaries.isEmpty {
                Text("No dates recorded")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            } else {
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
                }
            }
        }
    }

    // MARK: - AI Recommendations

    private var recommendationsSection: some View {
        Section("AI Recommendations") {
            if viewModel.clientRecommendations.isEmpty {
                Text("No recommendations yet")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            } else {
                ForEach(viewModel.clientRecommendations) { rec in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(viewModel.productName(for: rec.productId))
                                .font(.system(size: 15, weight: .semibold, design: .serif))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Spacer()
                            StatusBadge(
                                text: viewModel.recommendationTypeLabel(rec.type),
                                color: RSMSTheme.info
                            )
                        }
                        HStack(spacing: 12) {
                            CircularProgressView(
                                progress: rec.confidence,
                                label: "Match",
                                value: viewModel.confidenceText(rec.confidence),
                                size: 50
                            )
                            if let reason = rec.reason {
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        if let notes = client.notes, !notes.isEmpty {
            Section("Associate Notes") {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
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
                                    Text("SKU: \(product.sku) • €\(Int(product.price).formatted())")
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
