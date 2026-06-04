//
//  OmnichannelModels.swift
//  RSMS
//
//  Omnichannel fulfilment models (BOPIS, endless aisle, ship-from-store)
//  — aligned with Supabase public schema.
//

import Foundation

// MARK: - Omnichannel Order

/// Unified model for BOPIS and endless-aisle orders.
/// Maps to Supabase `omnichannel_orders` table.
/// The `type` field distinguishes between BOPIS and endless aisle.
struct OmnichannelOrder: Codable, Identifiable, Hashable {
    let id: UUID
    let type: OmnichannelOrderType
    let onlineOrderId: String?
    let storeId: UUID
    let clientId: UUID
    let associateId: UUID?
    let productId: UUID?
    let sourceStoreId: UUID?
    let sourceDCId: String?
    let status: OmnichannelOrderStatus
    let shippingAddress: String?
    let estimatedDelivery: Date?
    let preparedBy: UUID?
    let preparedAt: Date?
    let pickedUpAt: Date?
    let notes: String?
    let createdAt: Date
    let quantity: Int
    let unitPrice: Decimal?
    let reservationDate: Date?
    let customerPhone: String?

    enum CodingKeys: String, CodingKey {
        case id, type, status, notes
        case onlineOrderId     = "online_order_id"
        case storeId           = "store_id"
        case clientId          = "client_id"
        case associateId       = "associate_id"
        case productId         = "product_id"
        case sourceStoreId     = "source_store_id"
        case sourceDCId        = "source_dc_id"
        case shippingAddress   = "shipping_address"
        case estimatedDelivery = "estimated_delivery"
        case preparedBy        = "prepared_by"
        case preparedAt        = "prepared_at"
        case pickedUpAt        = "picked_up_at"
        case createdAt         = "created_at"
        case quantity
        case unitPrice         = "unit_price"
        case reservationDate   = "reservation_date"
        case customerPhone     = "customer_phone"
    }
}

enum OmnichannelOrderType: String, Codable, CaseIterable {
    case bopis        = "bopis"
    case endlessAisle = "endless_aisle"
}

enum OmnichannelOrderStatus: String, Codable, CaseIterable {
    case reserved   = "reserved"
    case pending    = "pending"
    case preparing  = "preparing"
    case ready      = "ready"
    case pickedUp   = "picked_up"
    case placed     = "placed"
    case confirmed  = "confirmed"
    case shipped    = "shipped"
    case delivered  = "delivered"
    case cancelled  = "cancelled"
}

// MARK: - Ship From Store Packing Slip

/// Packing and shipping details when a store fulfils an online order.
/// Maps to Supabase `ship_from_store_slips` table.
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

// MARK: - BOPIS Pickup Audit

/// Immutable audit record written on every successful pickup completion.
/// Maps to Supabase `bopis_pickup_audit` table.
struct BOPISPickupAudit: Codable, Identifiable {
    let id: UUID
    let orderId: UUID
    let associateId: UUID
    let associateName: String
    let customerName: String
    let pickupAt: Date
    let statusFrom: String
    let statusTo: String
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, notes
        case orderId       = "order_id"
        case associateId   = "associate_id"
        case associateName = "associate_name"
        case customerName  = "customer_name"
        case pickupAt      = "pickup_at"
        case statusFrom    = "status_from"
        case statusTo      = "status_to"
        case createdAt     = "created_at"
    }
}
