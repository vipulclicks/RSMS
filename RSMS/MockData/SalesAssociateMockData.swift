//
//  SalesAssociateMockData.swift
//  RSMS
//
//  Preview data for clienteling, appointments, and remote selling.
//  Updated to match Supabase-aligned models.
//

import Foundation

// MARK: - Client Profile Mock Data

extension ClientProfile {
    static let preview = ClientProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
        fullName: "Isabelle Fontaine",
        email: "isabelle.fontaine@email.com",
        phone: "+33 6 11 22 33 44",
        preferredStoreId: Store.preview.id,
        vipTier: .platinum,
        privacyConsentGiven: true,
        consentDate: .now,
        notes: "Prefers private viewings. Anniversary in June.",
        createdAt: .now,
        updatedAt: .now,
        // Size Preferences
        shoeSize: nil,
        ringSize: "52 (EU)",
        braceletSize: "17 cm",
        necklaceLength: "45 cm",
        wristSize: "16 cm",
        beltSize: nil,
        // Category / Material Preferences
        favoriteCategories: ["Jewelry", "Watches"],
        favoriteMetals: ["White Gold", "Platinum"],
        favoriteGemstones: ["Diamond", "Sapphire"],
        // Detailed Preferences
        shoeFitPreference: nil,
        preferredMetal: "Platinum",
        preferredGemstone: "Diamond",
        watchCasePreference: "Round",
        strapMaterialPreference: "Leather",
        preferredBagSize: nil,
        preferredBagStyle: nil,
        preferredMaterial: nil,
        bucklePreference: nil,
        fragranceFamily: "Floral",
        fragranceStrength: "Eau de Parfum",
        scentPreference: nil,
        preferredBrands: nil,
        favoriteColors: nil,
        stylePreference: "Classic",
        giftingPreference: nil,
        shoppingPreference: "In-store appointment"
    )

    static let previewClient2 = ClientProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
        fullName: "Raj Malhotra",
        email: "raj.malhotra@email.com",
        phone: "+91 98 1234 5678",
        preferredStoreId: Store.preview.id,
        vipTier: .gold,
        privacyConsentGiven: true,
        consentDate: .now,
        notes: "Collector of limited editions.",
        createdAt: .now,
        updatedAt: .now,
        shoeSize: nil, ringSize: "60 (EU)", braceletSize: nil,
        necklaceLength: nil, wristSize: "18 cm", beltSize: nil,
        favoriteCategories: ["Watches", "Leather Goods"],
        favoriteMetals: ["Rose Gold"], favoriteGemstones: nil,
        shoeFitPreference: nil, preferredMetal: "Rose Gold",
        preferredGemstone: nil, watchCasePreference: "Chronograph",
        strapMaterialPreference: "Steel", preferredBagSize: nil,
        preferredBagStyle: nil, preferredMaterial: nil,
        bucklePreference: nil, fragranceFamily: nil,
        fragranceStrength: nil, scentPreference: nil,
        preferredBrands: nil, favoriteColors: nil,
        stylePreference: "Sporty Luxury", giftingPreference: nil,
        shoppingPreference: nil
    )

    static let allClients: [ClientProfile] = [.preview, .previewClient2]
}

// MARK: - Client Anniversary Mock Data

extension ClientAnniversary {
    static let preview = ClientAnniversary(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000030")!,
        clientId: ClientProfile.preview.id,
        title: "Wedding Anniversary",
        date: Calendar.current.date(from: DateComponents(month: 6, day: 15))!,
        reminderEnabled: true,
        notes: "25th anniversary — consider bespoke piece"
    )

    static let all: [ClientAnniversary] = [.preview]
}

// MARK: - Wishlist Item Mock Data

extension WishlistItem {
    static let preview = WishlistItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000040")!,
        clientId: ClientProfile.preview.id,
        productId: Product.preview.id,
        addedAt: .now,
        isAvailable: true,
        notifyOnRestock: true,
        notes: "Interested in the blue dial variant"
    )

    static let all: [WishlistItem] = [.preview]
}

// MARK: - Appointment Mock Data

extension Appointment {
    static let preview = Appointment(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000050")!,
        clientId: ClientProfile.preview.id,
        associateId: UserProfile.previewAssociate.id,
        storeId: Store.preview.id,
        dateTime: Calendar.current.date(byAdding: .hour, value: 2, to: .now)!,
        durationMinutes: 45,
        type: .inStore,
        status: .confirmed,
        reminderSentAt: .now,
        videoLink: nil,
        notes: "Anniversary gift consultation — wants to see diamond collection",
        createdAt: .now,
        reminderTimingHours: 24,
        reminderChannel: "Email",
        reminderStatus: "Sent",
        reminderError: nil
    )

    static let previewVideo = Appointment(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000051")!,
        clientId: ClientProfile.previewClient2.id,
        associateId: UserProfile.previewAssociate.id,
        storeId: Store.preview.id,
        dateTime: Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
        durationMinutes: 30,
        type: .video,
        status: .scheduled,
        reminderSentAt: nil,
        videoLink: "https://meet.lumiere.com/raj-session",
        notes: "Follow-up on Chronograph collection",
        createdAt: .now,
        reminderTimingHours: 1,
        reminderChannel: "SMS",
        reminderStatus: "Pending",
        reminderError: nil
    )

    static let previewVideoClient1 = Appointment(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000052")!,
        clientId: ClientProfile.preview.id,
        associateId: UserProfile.previewAssociate.id,
        storeId: Store.preview.id,
        dateTime: Calendar.current.date(byAdding: .minute, value: 5, to: .now)!,
        durationMinutes: 45,
        type: .video,
        status: .confirmed,
        reminderSentAt: nil,
        videoLink: "facetime://lucas.dubois@maisonlumiere.com",
        notes: "Anniversary High Jewelry FaceTime Selection",
        createdAt: .now,
        reminderTimingHours: 24,
        reminderChannel: "Email",
        reminderStatus: "Pending",
        reminderError: nil
    )

    static let all: [Appointment] = [.preview, .previewVideo, .previewVideoClient1]
}

// MARK: - AI Recommendation Mock Data

extension AIRecommendation {
    static let preview = AIRecommendation(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000060")!,
        clientId: ClientProfile.preview.id,
        productId: Product.previewWatch.id,
        type: .crossSell,
        confidence: 0.92,
        reason: "Based on recent diamond jewelry purchases, this client may appreciate a matching diamond watch.",
        isAccepted: nil,
        createdAt: .now
    )

    static let all: [AIRecommendation] = [.preview]
}

// MARK: - Look Builder Outfit Mock Data

extension LookBuilderOutfit {
    static let preview = LookBuilderOutfit(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000070")!,
        associateId: UserProfile.previewAssociate.id,
        clientId: ClientProfile.preview.id,
        name: "Anniversary Evening Look",
        productIds: [Product.preview.id, Product.previewWatch.id],
        imageURL: nil,
        notes: "Diamond necklace + matching watch for the anniversary dinner.",
        createdAt: .now
    )

    static let all: [LookBuilderOutfit] = [.preview]
}

// MARK: - Curated Cart Mock Data

extension CuratedCart {
    static let preview = CuratedCart(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000080")!,
        title: "Anniversary Collection",
        description: "Bespoke selection of platinum and diamond jewelry.",
        items: [UniversalCartItem.previewCuratedItem]
    )
    
    static let all: [CuratedCart] = [.preview]
}

