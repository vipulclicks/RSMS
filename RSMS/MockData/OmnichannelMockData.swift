//
//  OmnichannelMockData.swift
//  RSMS_Mock_Data
//
//  Created by Prem Kumar on 18/05/26.
//

import Foundation

// MARK: - BOPISOrder

extension BOPISOrder {
    static let preview = BOPISOrder(
        id: UUID(uuidString: "60000000-0000-0000-0000-000000000001")!,
        onlineOrderId: "ONL-987654",
        storeId: Store.preview.id,
        clientId: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!, // ClientProfile.preview.id
        status: .ready,
        preparedBy: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, // UserProfile.previewInventory.id
        preparedAt: .now.addingTimeInterval(-2 * 3600),
        pickedUpAt: nil,
        notes: "Client arriving at 5 PM.",
        createdAt: .now.addingTimeInterval(-24 * 3600)
    )
}

// MARK: - EndlessAisleOrder

extension EndlessAisleOrder {
    static let preview = EndlessAisleOrder(
        id: UUID(uuidString: "60000000-0000-0000-0000-000000000010")!,
        storeId: Store.preview.id,
        associateId: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, // UserProfile.previewAssociate.id
        clientId: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!, // ClientProfile.preview.id
        productId: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!, // Product.previewRing.id
        sourceStoreId: nil,
        sourceDCId: "DC-EUROPE-01",
        status: .confirmed,
        shippingAddress: "45 Rue du Faubourg Saint-Honoré, 75008 Paris, France",
        estimatedDelivery: .now.addingTimeInterval(3 * 86400),
        createdAt: .now
    )
}

// MARK: - ShipFromStoreSlip

extension ShipFromStoreSlip {
    static let preview = ShipFromStoreSlip(
        id: UUID(uuidString: "60000000-0000-0000-0000-000000000020")!,
        orderId: UUID(uuidString: "60000000-0000-0000-0000-000000000010")!, // EndlessAisleOrder.preview.id
        storeId: Store.preview.id,
        trackingNumber: "DHL-123456789",
        carrier: "DHL Express",
        packingSlipURL: "https://example.com/slips/slip-123.pdf",
        packedBy: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, // UserProfile.previewInventory.id
        shippedAt: .now.addingTimeInterval(-1 * 3600),
        createdAt: .now.addingTimeInterval(-3 * 3600)
    )
}
