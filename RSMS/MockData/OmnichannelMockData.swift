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
        createdAt: .now,
        quantity: 1,
        unitPrice: 4800.00,
        reservationDate: Date(),
        customerPhone: "+91 98765 43210"
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
        createdAt: .now,
        quantity: 1,
        unitPrice: 12500.00,
        reservationDate: Date(),
        customerPhone: "+91 91234 56789"
    )

    static let bopisReserved = OmnichannelOrder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000302")!,
        type: .bopis,
        onlineOrderId: "WEB-2026-09101",
        storeId: Store.preview.id,
        clientId: ClientProfile.preview.id,
        associateId: nil,
        productId: Product.preview.id,
        sourceStoreId: nil, sourceDCId: nil,
        status: .reserved,
        shippingAddress: nil, estimatedDelivery: nil,
        preparedBy: nil, preparedAt: nil, pickedUpAt: nil,
        notes: "Client requested gift wrapping.",
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!,
        quantity: 1,
        unitPrice: 4800.00,
        reservationDate: Calendar.current.date(byAdding: .hour, value: -2, to: .now),
        customerPhone: "+91 98765 43210"
    )

    static let bopisReady = OmnichannelOrder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000303")!,
        type: .bopis,
        onlineOrderId: "WEB-2026-09245",
        storeId: Store.preview.id,
        clientId: ClientProfile.previewClient2.id,
        associateId: UserProfile.previewAssociate.id,
        productId: Product.previewWatch.id,
        sourceStoreId: nil, sourceDCId: nil,
        status: .ready,
        shippingAddress: nil, estimatedDelivery: nil,
        preparedBy: UserProfile.previewAssociate.id,
        preparedAt: Calendar.current.date(byAdding: .minute, value: -30, to: .now),
        pickedUpAt: nil,
        notes: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
        quantity: 2,
        unitPrice: 12500.00,
        reservationDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
        customerPhone: "+91 91234 56789"
    )

    static let bopisPickedUp = OmnichannelOrder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000304")!,
        type: .bopis,
        onlineOrderId: "WEB-2026-08990",
        storeId: Store.preview.id,
        clientId: ClientProfile.preview.id,
        associateId: UserProfile.previewAssociate.id,
        productId: Product.preview.id,
        sourceStoreId: nil, sourceDCId: nil,
        status: .pickedUp,
        shippingAddress: nil, estimatedDelivery: nil,
        preparedBy: UserProfile.previewAssociate.id,
        preparedAt: Calendar.current.date(byAdding: .hour, value: -5, to: .now),
        pickedUpAt: Calendar.current.date(byAdding: .hour, value: -3, to: .now),
        notes: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
        quantity: 1,
        unitPrice: 3200.00,
        reservationDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
        customerPhone: "+91 98765 43210"
    )

    static let bopisCancelled = OmnichannelOrder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000305")!,
        type: .bopis,
        onlineOrderId: "WEB-2026-08755",
        storeId: Store.preview.id,
        clientId: ClientProfile.previewClient2.id,
        associateId: nil,
        productId: Product.previewWatch.id,
        sourceStoreId: nil, sourceDCId: nil,
        status: .cancelled,
        shippingAddress: nil, estimatedDelivery: nil,
        preparedBy: nil, preparedAt: nil, pickedUpAt: nil,
        notes: "Client cancelled via app.",
        createdAt: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
        quantity: 1,
        unitPrice: 8900.00,
        reservationDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
        customerPhone: "+91 91234 56789"
    )

    static let all: [OmnichannelOrder] = [
        .previewBOPIS, .previewEndlessAisle,
        .bopisReserved, .bopisReady, .bopisPickedUp, .bopisCancelled
    ]
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
