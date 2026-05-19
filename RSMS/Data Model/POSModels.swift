//
//  POSModels.swift
//  RSMS_Mock_Data
//
//  Created by Prem Kumar on 18/05/26.
//

import Foundation

// MARK: - Cart Session

struct CartSession: Codable, Identifiable, Hashable {
    let id: UUID
    let associateId: UUID
    let clientId: UUID?
    let storeId: UUID
    let status: CartStatus
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case associateId = "associate_id"
        case clientId    = "client_id"
        case storeId     = "store_id"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }
}

enum CartStatus: String, Codable, CaseIterable {
    case active    = "active"
    case completed = "completed"
    case abandoned = "abandoned"
}

// MARK: - Cart Item

struct CartItem: Codable, Identifiable, Hashable {
    let id: UUID
    let sessionId: UUID
    let productId: UUID
    let quantity: Int
    let unitPrice: Double
    let discountApplied: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, quantity, notes
        case sessionId       = "session_id"
        case productId       = "product_id"
        case unitPrice       = "unit_price"
        case discountApplied = "discount_applied"
    }
}

// MARK: - Discount

struct Discount: Codable, Identifiable, Hashable {
    let id: UUID
    let code: String
    let type: DiscountType
    let value: Double
    let validFrom: Date
    let validTo: Date
    let conditions: String?
    let isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, code, type, value, conditions
        case validFrom = "valid_from"
        case validTo   = "valid_to"
        case isActive  = "is_active"
        case createdAt = "created_at"
    }
}

enum DiscountType: String, Codable, CaseIterable {
    case percentage = "percentage"
    case fixed      = "fixed"
}

// MARK: - Transaction

struct Transaction: Codable, Identifiable, Hashable {
    let id: UUID
    let cartSessionId: UUID
    let storeId: UUID
    let associateId: UUID
    let clientId: UUID?
    let totalAmount: Double
    let taxAmount: Double
    let currency: String
    let status: TransactionStatus
    let isTaxFree: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, currency, status
        case cartSessionId = "cart_session_id"
        case storeId       = "store_id"
        case associateId   = "associate_id"
        case clientId      = "client_id"
        case totalAmount   = "total_amount"
        case taxAmount     = "tax_amount"
        case isTaxFree     = "is_tax_free"
        case createdAt     = "created_at"
    }
}

enum TransactionStatus: String, Codable, CaseIterable {
    case pending   = "pending"
    case completed = "completed"
    case voided    = "voided"
    case refunded  = "refunded"
}

// MARK: - Tender

struct Tender: Codable, Identifiable, Hashable {
    let id: UUID
    let transactionId: UUID
    let method: TenderMethod
    let amount: Double
    let reference: String?

    enum CodingKeys: String, CodingKey {
        case id, method, amount, reference
        case transactionId = "transaction_id"
    }
}

enum TenderMethod: String, Codable, CaseIterable {
    case card     = "card"
    case cash     = "cash"
    case giftCard = "gift_card"
    case bankTransfer = "bank_transfer"
}

// MARK: - Gift Receipt

struct GiftReceipt: Codable, Identifiable, Hashable {
    let id: UUID
    let transactionId: UUID
    let recipientNote: String?
    let printedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case transactionId = "transaction_id"
        case recipientNote = "recipient_note"
        case printedAt     = "printed_at"
    }
}

// MARK: - Exchange / Return

struct ExchangeReturn: Codable, Identifiable, Hashable {
    let id: UUID
    let originalTransactionId: UUID
    let storeId: UUID
    let type: ExchangeReturnType
    let reason: String
    let status: ExchangeReturnStatus
    let refundAmount: Double?
    let processedBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, reason, status
        case originalTransactionId = "original_transaction_id"
        case storeId               = "store_id"
        case refundAmount          = "refund_amount"
        case processedBy           = "processed_by"
        case createdAt             = "created_at"
    }
}

enum ExchangeReturnType: String, Codable, CaseIterable {
    case exchange = "exchange"
    case returnItem = "return"
}

enum ExchangeReturnStatus: String, Codable, CaseIterable {
    case pending   = "pending"
    case approved  = "approved"
    case completed = "completed"
    case rejected  = "rejected"
}

/// Represents the individual items being exchanged or returned.
struct ExchangeReturnItem: Codable, Identifiable, Hashable {
    let id: UUID
    let exchangeReturnId: UUID
    let productId: UUID
    let quantity: Int
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case id, quantity, reason
        case exchangeReturnId = "exchange_return_id"
        case productId        = "product_id"
    }
}
