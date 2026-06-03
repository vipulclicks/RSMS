//
//  ExchangeModels.swift
//  RSMS
//

import Foundation

enum POSExchangeStatus: String, Codable, CaseIterable, Identifiable {
    case requested = "requested"
    case inspectionPending = "inspection_pending"
    case approved = "approved"
    case paymentPending = "payment_pending"
    case completed = "completed"
    case rejected = "rejected"
    
    var id: String { rawValue }
}

struct POSExchangeRequest: Codable, Identifiable, Hashable {
    let id: UUID
    let orderId: UUID
    let originalProductId: UUID
    let replacementProductId: UUID
    let quantity: Int
    let reason: String
    var status: POSExchangeStatus
    let returnedItemValue: Decimal
    let replacementItemValue: Decimal
    let differenceAmount: Decimal
    var inspectionCondition: POSInspectionCondition?
    var inspectionNotes: String?
    var inspectedBy: UUID?
    var inspectedAt: Date?
    let createdAt: Date
    var updatedAt: Date
    let storeId: UUID
    let associateId: UUID
    
    init(
        id: UUID = UUID(),
        orderId: UUID,
        originalProductId: UUID,
        replacementProductId: UUID,
        quantity: Int,
        reason: String,
        status: POSExchangeStatus = .requested,
        returnedItemValue: Decimal,
        replacementItemValue: Decimal,
        differenceAmount: Decimal,
        inspectionCondition: POSInspectionCondition? = nil,
        inspectionNotes: String? = nil,
        inspectedBy: UUID? = nil,
        inspectedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        storeId: UUID,
        associateId: UUID
    ) {
        self.id = id
        self.orderId = orderId
        self.originalProductId = originalProductId
        self.replacementProductId = replacementProductId
        self.quantity = quantity
        self.reason = reason
        self.status = status
        self.returnedItemValue = returnedItemValue
        self.replacementItemValue = replacementItemValue
        self.differenceAmount = differenceAmount
        self.inspectionCondition = inspectionCondition
        self.inspectionNotes = inspectionNotes
        self.inspectedBy = inspectedBy
        self.inspectedAt = inspectedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.storeId = storeId
        self.associateId = associateId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case originalProductId = "original_product_id"
        case replacementProductId = "replacement_product_id"
        case quantity
        case reason
        case status
        case returnedItemValue = "returned_item_value"
        case replacementItemValue = "replacement_item_value"
        case differenceAmount = "difference_amount"
        case inspectionCondition = "inspection_condition"
        case inspectionNotes = "inspection_notes"
        case inspectedBy = "inspected_by"
        case inspectedAt = "inspected_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case storeId = "store_id"
        case associateId = "associate_id"
    }
}
