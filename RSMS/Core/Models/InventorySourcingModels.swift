//
//  InventorySourcingModels.swift
//  RSMS
//
//  Models for Endless Aisle Inventory Sourcing.
//

import Foundation
import SwiftUI

enum InventorySourcingStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case requested = "Requested"
    case searching = "Searching"
    case stockFound = "Stock Found"
    case transferInitiated = "Transfer Initiated"
    case inTransit = "In Transit"
    case received = "Received"
    case available = "Available"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .requested: return RSMSTheme.info
        case .searching: return RSMSTheme.info
        case .stockFound: return RSMSTheme.success
        case .transferInitiated: return RSMSTheme.warning
        case .inTransit: return RSMSTheme.warning
        case .received: return RSMSTheme.warning
        case .available: return RSMSTheme.success
        case .completed: return RSMSTheme.success
        case .cancelled: return RSMSTheme.danger
        }
    }
}

struct InventorySourcingRequest: Codable, Identifiable, Hashable {
    let id: UUID
    let productId: UUID
    let productName: String
    var requestedQuantity: Int
    let requestingStoreId: UUID
    let salesAssociateId: UUID
    let createdAt: Date
    var status: InventorySourcingStatus
    var sourceStoreId: UUID?
    var transferMovementId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case productName = "product_name"
        case requestedQuantity = "requested_quantity"
        case requestingStoreId = "requesting_store_id"
        case salesAssociateId = "sales_associate_id"
        case createdAt = "created_at"
        case status
        case sourceStoreId = "source_store_id"
        case transferMovementId = "transfer_movement_id"
    }

    init(
        id: UUID = UUID(),
        productId: UUID,
        productName: String,
        requestedQuantity: Int,
        requestingStoreId: UUID,
        salesAssociateId: UUID,
        createdAt: Date = Date(),
        status: InventorySourcingStatus = .requested,
        sourceStoreId: UUID? = nil,
        transferMovementId: UUID? = nil
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.requestedQuantity = requestedQuantity
        self.requestingStoreId = requestingStoreId
        self.salesAssociateId = salesAssociateId
        self.createdAt = createdAt
        self.status = status
        self.sourceStoreId = sourceStoreId
        self.transferMovementId = transferMovementId
    }
}
