//
//  SalesAssociateMockData.swift
//  RSMS_Mock_Data
//
//  Created by Prem Kumar on 18/05/26.
//

import Foundation

// MARK: - ClientProfile

extension ClientProfile {
    static let preview = ClientProfile(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
        fullName: "Isabella Rossi",
        email: "isabella.rossi@example.com",
        phone: "+39 345 678 9012",
        preferredStoreId: Store.preview.id,
        vipTier: .gold,
        privacyConsentGiven: true,
        consentDate: .now.addingTimeInterval(-100 * 86400),
        notes: "Prefers rose gold. Allergic to nickel.",
        createdAt: .now.addingTimeInterval(-365 * 86400),
        updatedAt: .now
    )
}

// MARK: - ClientPreference

extension ClientPreference {
    static let preview = ClientPreference(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000010")!,
        clientId: ClientProfile.preview.id,
        ringSize: "52",
        braceletSize: "16",
        necklaceLength: "42cm",
        wristSize: "15cm",
        favoriteCategories: ["Haute Joaillerie", "Watches"],
        favoriteMetals: ["Rose Gold", "Platinum"],
        favoriteGemstones: ["Diamond", "Sapphire"],
        notes: "Loves vintage styles.",
        updatedAt: .now
    )
}

// MARK: - ClientAnniversary

extension ClientAnniversary {
    static let previewBirthday = ClientAnniversary(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000020")!,
        clientId: ClientProfile.preview.id,
        title: "Birthday",
        date: Calendar.current.date(from: DateComponents(year: 1985, month: 8, day: 15)) ?? .now,
        reminderEnabled: true,
        notes: "Send orchids."
    )
}

// MARK: - WishlistItem

extension WishlistItem {
    static let preview = WishlistItem(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000030")!,
        clientId: ClientProfile.preview.id,
        productId: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!, // Needs product ID from Inventory
        addedAt: .now.addingTimeInterval(-5 * 86400),
        isAvailable: true,
        notifyOnRestock: false,
        notes: "Waiting for bonus before buying."
    )
}

// MARK: - Appointment

extension Appointment {
    static let preview = Appointment(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000040")!,
        clientId: ClientProfile.preview.id,
        associateId: UserProfile.previewAssociate.id,
        storeId: Store.preview.id,
        dateTime: .now.addingTimeInterval(2 * 86400), // 2 days from now
        durationMinutes: 60,
        type: .inStore,
        status: .confirmed,
        reminderSentAt: .now,
        videoLink: nil,
        notes: "Looking for an anniversary gift for husband.",
        createdAt: .now.addingTimeInterval(-1 * 86400)
    )
}

// MARK: - CuratedCart & Item

extension CuratedCart {
    static let preview = CuratedCart(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000050")!,
        clientId: ClientProfile.preview.id,
        associateId: UserProfile.previewAssociate.id,
        note: "A selection of our finest rose gold pieces for your consideration.",
        status: .shared,
        createdAt: .now,
        updatedAt: .now
    )
}

extension CuratedCartItem {
    static let preview = CuratedCartItem(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000060")!,
        cartId: CuratedCart.preview.id,
        productId: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
        note: "This matches your ring."
    )
}

// MARK: - AIRecommendation

extension AIRecommendation {
    static let preview = AIRecommendation(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000070")!,
        clientId: ClientProfile.preview.id,
        productId: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
        type: .crossSell,
        confidence: 0.89,
        reason: "Frequently bought with items on wishlist.",
        isAccepted: nil,
        createdAt: .now
    )
}

// MARK: - LookBuilderOutfit

extension LookBuilderOutfit {
    static let preview = LookBuilderOutfit(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000080")!,
        associateId: UserProfile.previewAssociate.id,
        clientId: ClientProfile.preview.id,
        name: "Summer Evening Gala",
        productIds: [
            UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            UUID(uuidString: "30000000-0000-0000-0000-000000000003")!
        ],
        imageURL: nil,
        notes: "Perfect for the charity event.",
        createdAt: .now
    )
}
