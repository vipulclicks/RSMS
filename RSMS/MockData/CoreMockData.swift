//
//  CoreMockData.swift
//  RSMS_Mock_Data
//
//  Created by Prem Kumar on 18/05/26.
//

import Foundation

// MARK: - Store Mock Data

extension Store {
    static let preview = Store(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Maison Lumière — Paris Vendôme",
        code: "PAR-VND-01",
        country: "France",
        city: "Paris",
        address: "23 Place Vendôme, 75001 Paris",
        timezone: "Europe/Paris",
        phone: "+33 1 42 60 00 00",
        email: "vendome@maisonlumiere.com",
        isActive: true,
        createdAt: .now,
        updatedAt: .now
    )

    static let previewMumbai = Store(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Maison Lumière — Mumbai Palladium",
        code: "MUM-PLD-01",
        country: "India",
        city: "Mumbai",
        address: "Palladium Mall, Lower Parel, Mumbai 400013",
        timezone: "Asia/Kolkata",
        phone: "+91 22 4000 0000",
        email: "mumbai@maisonlumiere.com",
        isActive: true,
        createdAt: .now,
        updatedAt: .now
    )

    static let all: [Store] = [.preview, .previewMumbai]
}

// MARK: - UserProfile Mock Data

extension UserProfile {
    static let previewManager = UserProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
        email: "sophie.martin@maisonlumiere.com",
        fullName: "Sophie Martin",
        role: .boutiqueManager,
        storeId: Store.preview.id,
        avatarURL: nil,
        phone: "+33 6 12 34 56 78",
        isActive: true,
        createdAt: .now,
        updatedAt: .now
    )

    static let previewAssociate = UserProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        email: "lucas.dubois@maisonlumiere.com",
        fullName: "Lucas Dubois",
        role: .salesAssociate,
        storeId: Store.preview.id,
        avatarURL: nil,
        phone: "+33 6 98 76 54 32",
        isActive: true,
        createdAt: .now,
        updatedAt: .now
    )

    static let previewInventory = UserProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
        email: "emma.leroy@maisonlumiere.com",
        fullName: "Emma Leroy",
        role: .inventoryController,
        storeId: Store.preview.id,
        avatarURL: nil,
        phone: "+33 6 55 44 33 22",
        isActive: true,
        createdAt: .now,
        updatedAt: .now
    )

    static let all: [UserProfile] = [.previewManager, .previewAssociate, .previewInventory]
}
