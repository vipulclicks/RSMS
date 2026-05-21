//
//  OmnichannelMockData.swift
//  RSMS
//
//  Preview data for omnichannel orders and ship-from-store.
//  Updated to match Supabase-aligned OmnichannelOrder model.
//

import Foundation

// MARK: - Omnichannel Order Mock Data

extension OmnichannelOrder {
    /// A BOPIS order
    static let previewBOPIS = OmnichannelOrder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000300")!,
        type: .bopis,
        onlineOrderId: "WEB-2026-08842",
        storeId: Store.preview.id,
        clientId: ClientProfile.preview.id,
        associateId: nil,
        productId: Product.preview.id,
        sourceStoreId: nil,
        sourceDCId: nil,
        status: .preparing,
        shippingAddress: nil,
        estimatedDelivery: nil,
        preparedBy: UserProfile.previewAssociate.id,
        preparedAt: nil,
        pickedUpAt: nil,
        notes: "Client will pick up tomorrow between 10 AM and 12 PM.",
        createdAt: .now
    )

    /// An endless-aisle order
    static let previewEndlessAisle = OmnichannelOrder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
        type: .endlessAisle,
        onlineOrderId: nil,
        storeId: Store.preview.id,
        clientId: ClientProfile.previewClient2.id,
        associateId: UserProfile.previewAssociate.id,
        productId: Product.previewWatch.id,
        sourceStoreId: Store.previewMumbai.id,
        sourceDCId: nil,
        status: .confirmed,
        shippingAddress: "15 Avenue Montaigne, 75008 Paris",
        estimatedDelivery: Calendar.current.date(byAdding: .day, value: 5, to: .now),
        preparedBy: nil,
        preparedAt: nil,
        pickedUpAt: nil,
        notes: "Rose gold variant not in stock locally — sourced from Mumbai.",
        createdAt: .now
    )

    static let all: [OmnichannelOrder] = [.previewBOPIS, .previewEndlessAisle]
}

// MARK: - Ship From Store Slip Mock Data

extension ShipFromStoreSlip {
    static let preview = ShipFromStoreSlip(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000310")!,
        orderId: OmnichannelOrder.previewEndlessAisle.id,
        storeId: Store.preview.id,
        trackingNumber: "DHL-FR-9876543210",
        carrier: "DHL Express",
        packingSlipURL: nil,
        packedBy: UserProfile.previewInventory.id,
        shippedAt: nil,
        createdAt: .now
    )

    static let all: [ShipFromStoreSlip] = [.preview]
}
