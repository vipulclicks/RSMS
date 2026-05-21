//
//  ClientelingView.swift
//  RSMS
//
//  CRM view: client profiles, preferences, anniversaries, wishlists.
//

import SwiftUI

struct ClientelingView: View {
    @State private var viewModel = ClientelingViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                HStack(alignment: .top, spacing: 16) {
                    profileColumn
                    detailColumn
                }
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Clienteling")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            SectionHeader(title: "Client Portfolio", subtitle: "Manage your VIP client relationships")
            Spacer()
        }
    }

    // MARK: - Profile Column

    private var profileColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Client card
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.gold.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Text(String(viewModel.client.fullName.prefix(2)))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.gold)
                }

                VStack(spacing: 6) {
                    Text(viewModel.client.fullName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)

                    StatusBadge(text: viewModel.client.vipTier.rawValue.uppercased(), color: viewModel.tierColor(viewModel.client.vipTier))
                }

                Divider().overlay(RSMSTheme.divider)

                VStack(spacing: 10) {
                    if let email = viewModel.client.email {
                        contactRow(icon: "envelope.fill", value: email)
                    }
                    if let phone = viewModel.client.phone {
                        contactRow(icon: "phone.fill", value: phone)
                    }
                    contactRow(icon: "checkmark.shield.fill",
                               value: viewModel.client.privacyConsentGiven ? "Consent given" : "No consent")
                }

                if let notes = viewModel.client.notes {
                    Divider().overlay(RSMSTheme.divider)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .rsmsCard()

            // Anniversary
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Key Dates")
                HStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.title3)
                        .foregroundStyle(RSMSTheme.gold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.anniversary.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text(viewModel.formattedDate(viewModel.anniversary.date))
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    Spacer()
                    if viewModel.anniversary.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.gold)
                    }
                }
                if let notes = viewModel.anniversary.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            .rsmsCard()
        }
        .frame(maxWidth: 340)
    }

    // MARK: - Detail Column

    private var detailColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Preferences
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Preferences & Sizes")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if let ring = viewModel.client.ringSize {
                        preferenceChip(label: "Ring Size", value: ring, icon: "circle.circle.fill")
                    }
                    if let bracelet = viewModel.client.braceletSize {
                        preferenceChip(label: "Bracelet", value: bracelet, icon: "link.circle.fill")
                    }
                    if let necklace = viewModel.client.necklaceLength {
                        preferenceChip(label: "Necklace", value: necklace, icon: "oval.portrait.fill")
                    }
                    if let wrist = viewModel.client.wristSize {
                        preferenceChip(label: "Wrist", value: wrist, icon: "applewatch")
                    }
                }

                Divider().overlay(RSMSTheme.divider)

                if let favoriteCategories = viewModel.client.favoriteCategories {
                    tagSection(title: "Favorite Categories", tags: favoriteCategories, color: RSMSTheme.gold)
                }

                if let metals = viewModel.client.favoriteMetals {
                    tagSection(title: "Preferred Metals", tags: metals, color: RSMSTheme.info)
                }
                if let gems = viewModel.client.favoriteGemstones {
                    tagSection(title: "Gemstones", tags: gems, color: RSMSTheme.success)
                }
            }
            .rsmsCard()

            // Wishlist
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Wishlist")

                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.surfaceSecondary)
                            .frame(width: 64, height: 64)
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.wishlistProduct?.name ?? "Product")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        if let product = viewModel.wishlistProduct {
                            Text("€\(String(format: "%,.0f", product.price))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(RSMSTheme.gold)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        StatusBadge(
                            text: viewModel.wishlist.isAvailable ? "Available" : "Out of Stock",
                            color: viewModel.wishlist.isAvailable ? RSMSTheme.success : RSMSTheme.danger
                        )
                        if viewModel.wishlist.notifyOnRestock {
                            Label("Notify", systemImage: "bell.fill")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                }

                if let notes = viewModel.wishlist.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .italic()
                }
            }
            .rsmsCard()
        }
    }

    // MARK: - Sub-components

    private func contactRow(icon: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RSMSTheme.gold)
                .frame(width: 20)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
        }
    }

    private func preferenceChip(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RSMSTheme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(RSMSTheme.surfaceSecondary)
        )
    }

    private func tagSection(title: String, tags: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.textSecondary)
            FlowLayout(tags: tags, color: color)
        }
    }
}

#Preview {
    NavigationStack {
        ClientelingView()
    }
}
