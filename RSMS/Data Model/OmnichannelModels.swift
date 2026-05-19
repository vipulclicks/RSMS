//
//  OmnichannelModels.swift
//  RSMS_Mock_Data
//
//  Created by Prem Kumar on 18/05/26.
//

import Foundation

// MARK: - BOPIS Order

/// Represents an order where a customer buys something online and picks it up at a physical store.
struct BOPISOrder: Codable, Identifiable, Hashable {
    let id: UUID
    let onlineOrderId: String
    let storeId: UUID
    let clientId: UUID
    let status: BOPISStatus
    let preparedBy: UUID?
    let preparedAt: Date?
    let pickedUpAt: Date?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case onlineOrderId = "online_order_id"
        case storeId       = "store_id"
        case clientId      = "client_id"
        case preparedBy    = "prepared_by"
        case preparedAt    = "prepared_at"
        case pickedUpAt    = "picked_up_at"
        case createdAt     = "created_at"
    }
}

enum BOPISStatus: String, Codable, CaseIterable {
    case pending   = "pending"
    case preparing = "preparing"
    case ready     = "ready"
    case pickedUp  = "picked_up"
    case cancelled = "cancelled"
}

// MARK: - Endless Aisle Order

/// Used when a customer orders an item in the store that isn't currently in stock there, so it can be shipped to them.
struct EndlessAisleOrder: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let associateId: UUID
    let clientId: UUID
    let productId: UUID
    let sourceStoreId: UUID?
    let sourceDCId: String?
    let status: EndlessAisleStatus
    let shippingAddress: String?
    let estimatedDelivery: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case storeId           = "store_id"
        case associateId       = "associate_id"
        case clientId          = "client_id"
        case productId         = "product_id"
        case sourceStoreId     = "source_store_id"
        case sourceDCId        = "source_dc_id"
        case shippingAddress   = "shipping_address"
        case estimatedDelivery = "estimated_delivery"
        case createdAt         = "created_at"
    }
}

enum EndlessAisleStatus: String, Codable, CaseIterable {
    case placed    = "placed"
    case confirmed = "confirmed"
    case shipped   = "shipped"
    case delivered = "delivered"
    case cancelled = "cancelled"
}

// MARK: - Ship From Store Packing Slip

/// Details the packing and shipping information when a store fulfills an online order by shipping it directly to the customer.
struct ShipFromStoreSlip: Codable, Identifiable, Hashable {
    let id: UUID
    let orderId: UUID
    let storeId: UUID
    let trackingNumber: String?
    let carrier: String?
    let packingSlipURL: String?
    let packedBy: UUID?
    let shippedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, carrier
        case orderId        = "order_id"
        case storeId        = "store_id"
        case trackingNumber = "tracking_number"
        case packingSlipURL = "packing_slip_url"
        case packedBy       = "packed_by"
        case shippedAt      = "shipped_at"
        case createdAt      = "created_at"
    }
}
