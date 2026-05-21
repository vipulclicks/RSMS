//
//  ClientelingView.swift
//  RSMS
//
//  CRM view: client profiles, preferences, anniversaries, wishlists.
//

import SwiftUI

struct ClientelingView: View {
    private let client = ClientProfile.preview
    private let anniversary = ClientAnniversary.preview
    private let wishlist = WishlistItem.preview
    private let products = Product.all

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
                    Text(String(client.fullName.prefix(2)))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.gold)
                }

                VStack(spacing: 6) {
                    Text(client.fullName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)

                    StatusBadge(text: client.vipTier.rawValue.uppercased(), color: tierColor(client.vipTier))
                }

                Divider().overlay(RSMSTheme.divider)

                VStack(spacing: 10) {
                    if let email = client.email {
                        contactRow(icon: "envelope.fill", value: email)
                    }
                    if let phone = client.phone {
                        contactRow(icon: "phone.fill", value: phone)
                    }
                    contactRow(icon: "checkmark.shield.fill",
                               value: client.privacyConsentGiven ? "Consent given" : "No consent")
                }

                if let notes = client.notes {
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
                        Text(anniversary.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text(formattedDate(anniversary.date))
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    Spacer()
                    if anniversary.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.gold)
                    }
                }
                if let notes = anniversary.notes {
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
                    if let ring = client.ringSize {
                        preferenceChip(label: "Ring Size", value: ring, icon: "circle.circle.fill")
                    }
                    if let bracelet = client.braceletSize {
                        preferenceChip(label: "Bracelet", value: bracelet, icon: "link.circle.fill")
                    }
                    if let necklace = client.necklaceLength {
                        preferenceChip(label: "Necklace", value: necklace, icon: "oval.portrait.fill")
                    }
                    if let wrist = client.wristSize {
                        preferenceChip(label: "Wrist", value: wrist, icon: "applewatch")
                    }
                }

                Divider().overlay(RSMSTheme.divider)

                if let favoriteCategories = client.favoriteCategories {
                    tagSection(title: "Favorite Categories", tags: favoriteCategories, color: RSMSTheme.gold)
                }

                if let metals = client.favoriteMetals {
                    tagSection(title: "Preferred Metals", tags: metals, color: RSMSTheme.info)
                }
                if let gems = client.favoriteGemstones {
                    tagSection(title: "Gemstones", tags: gems, color: RSMSTheme.success)
                }
            }
            .rsmsCard()

            // Wishlist
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Wishlist")

                let product = products.first(where: { $0.id == wishlist.productId })
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
                        Text(product?.name ?? "Product")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        if let product {
                            Text("€\(String(format: "%,.0f", product.price))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(RSMSTheme.gold)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        StatusBadge(
                            text: wishlist.isAvailable ? "Available" : "Out of Stock",
                            color: wishlist.isAvailable ? RSMSTheme.success : RSMSTheme.danger
                        )
                        if wishlist.notifyOnRestock {
                            Label("Notify", systemImage: "bell.fill")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                }

                if let notes = wishlist.notes {
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

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        return f.string(from: date)
    }

    private func tierColor(_ tier: VIPTier) -> Color {
        switch tier {
        case .standard: return RSMSTheme.textSecondary
        case .silver:   return Color(hex: "C0C0C0")
        case .gold:     return RSMSTheme.gold
        case .platinum: return Color(hex: "B0C4DE")
        case .prive:    return RSMSTheme.danger
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: View {
    let tags: [String]
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.12))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClientelingView()
    }
}
