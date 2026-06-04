//
//  ReturnModels.swift
//  RSMS
//

import Foundation

enum POSInspectionCondition: String, Codable, CaseIterable, Identifiable {
    case new = "New"
    case opened = "Opened"
    case used = "Used"
    case damaged = "Damaged"
    case defective = "Defective"
    
    var id: String { rawValue }
}

enum POSReturnStatus: String, Codable, CaseIterable, Identifiable {
    case requested = "requested"
    case inspectionPending = "inspection_pending"
    case approved = "approved"
    case rejected = "rejected"
    case refunded = "refunded"
    
    var id: String { rawValue }
}

struct POSReturnRequest: Codable, Identifiable, Hashable {
    let id: UUID
    let orderId: UUID
    let productId: UUID
    let quantity: Int
    let reason: String
    var status: POSReturnStatus
    let originalPaidAmount: Decimal
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
        productId: UUID,
        quantity: Int,
        reason: String,
        status: POSReturnStatus = .requested,
        originalPaidAmount: Decimal,
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
        self.productId = productId
        self.quantity = quantity
        self.reason = reason
        self.status = status
        self.originalPaidAmount = originalPaidAmount
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
        case productId = "product_id"
        case quantity
        case reason
        case status
        case originalPaidAmount = "original_paid_amount"
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

struct POSReturnAuditLog: Codable, Identifiable, Hashable {
    let id: UUID
    let requestId: UUID
    let requestType: String // "return" or "exchange"
    let userId: UUID
    let userRole: String
    let timestamp: Date
    let action: String
    let previousStatus: String?
    let newStatus: String
    let notes: String?
    
    init(
        id: UUID = UUID(),
        requestId: UUID,
        requestType: String,
        userId: UUID,
        userRole: String,
        timestamp: Date = Date(),
        action: String,
        previousStatus: String?,
        newStatus: String,
        notes: String? = nil
    ) {
        self.id = id
        self.requestId = requestId
        self.requestType = requestType
        self.userId = userId
        self.userRole = userRole
        self.timestamp = timestamp
        self.action = action
        self.previousStatus = previousStatus
        self.newStatus = newStatus
        self.notes = notes
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case requestId = "request_id"
        case requestType = "request_type"
        case userId = "user_id"
        case userRole = "user_role"
        case timestamp
        case action
        case previousStatus = "previous_status"
        case newStatus = "new_status"
        case notes
    }
}
