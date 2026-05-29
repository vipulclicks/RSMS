//
//  POSModels.swift
//  RSMS
//
//  POS, cart, checkout, tender, and returns models
//  aligned with Supabase public schema.
//

import Foundation

// MARK: - Universal Cart

/// A unified shopping cart used for both POS checkout and curated remote selling.
/// Maps to Supabase `universal_carts` table.
/// The `type` field distinguishes POS carts from curated carts.
struct UniversalCart: Codable, Identifiable, Hashable {
    let id: UUID
    let type: CartType
    let associateId: UUID
    let clientId: UUID?
    let storeId: UUID?
    let status: CartStatus
    let note: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, status, note
        case associateId = "associate_id"
        case clientId    = "client_id"
        case storeId     = "store_id"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }
    
    // MARK: - Cart Discount Helpers
    
    /// Parses the applied discount from the note field (as a fallback since DB columns are missing)
    var appliedDiscount: CartDiscount? {
        guard let note = note, note.contains("||DISCOUNT:"),
              let range = note.range(of: "||DISCOUNT:") else {
            return nil
        }
        let jsonString = String(note[range.upperBound...])
        if let data = jsonString.data(using: .utf8) {
            return try? JSONDecoder().decode(CartDiscount.self, from: data)
        }
        return nil
    }
    
    /// Returns a new UniversalCart with the updated discount embedded in the note field
    func applyingDiscount(_ discount: CartDiscount?) -> UniversalCart {
        var baseNote = note ?? ""
        if let range = baseNote.range(of: "||DISCOUNT:") {
            baseNote = String(baseNote[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        
        var newNote: String? = baseNote.isEmpty ? nil : baseNote
        
        if let discount = discount, let data = try? JSONEncoder().encode(discount), let json = String(data: data, encoding: .utf8) {
            let discountString = "||DISCOUNT:\(json)"
            if let existing = newNote {
                newNote = existing + " " + discountString
            } else {
                newNote = discountString
            }
        }
        
        return UniversalCart(
            id: id,
            type: type,
            associateId: associateId,
            clientId: clientId,
            storeId: storeId,
            status: status,
            note: newNote,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

enum CartType: String, Codable, CaseIterable {
    case pos     = "pos"
    case curated = "curated"
}

enum CartStatus: String, Codable, CaseIterable {
    case active    = "active"
    case completed = "completed"
    case abandoned = "abandoned"
    case draft     = "draft"
    case shared    = "shared"
    case viewed    = "viewed"
    case converted = "converted"
    case expired   = "expired"
}

// MARK: - Universal Cart Item

/// A line item within a universal cart.
/// Maps to Supabase `universal_cart_items` table.
struct UniversalCartItem: Codable, Identifiable, Hashable {
    let id: UUID
    let cartId: UUID
    let productId: UUID
    let quantity: Int
    let unitPrice: Double?
    let discountApplied: Double?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id, quantity, note
        case cartId          = "cart_id"
        case productId       = "product_id"
        case unitPrice       = "unit_price"
        case discountApplied = "discount_applied"
    }
}

// MARK: - Discount

/// A promotional discount code.
/// Maps to Supabase `discounts` table.
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
    case percentage  = "percentage"
    case vip         = "vip"
    case promotional = "promotional"
}

// MARK: - Cart Discount (Applied)

enum DiscountApprovalStatus: String, Codable, CaseIterable {
    case pending  = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

/// Represents a discount applied to a specific cart.
/// Temporarily serialized into the cart's note field until DB schema is updated.
struct CartDiscount: Codable, Hashable {
    let type: DiscountType
    let value: Double
    var status: DiscountApprovalStatus
    let appliedBy: UUID
    let appliedAt: Date
}

// MARK: - Approval Workflow

struct DiscountApprovalRequest: Codable, Identifiable, Hashable {
    let id: UUID
    let cartId: UUID
    let clientId: UUID
    let associateId: UUID
    var managerId: UUID?
    let discountType: DiscountType
    let discountValue: Double
    let cartTotal: Double
    let reasonForDiscount: String?
    var status: DiscountApprovalStatus
    let createdAt: Date
    var decisionDate: Date?
    var managerNotes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case cartId = "cart_id"
        case clientId = "client_id"
        case associateId = "associate_id"
        case managerId = "manager_id"
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case cartTotal = "cart_total"
        case reasonForDiscount = "reason_for_discount"
        case createdAt = "created_at"
        case decisionDate = "decision_date"
        case managerNotes = "manager_notes"
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case approvalRequest = "approval_request"
    case approvalDecision = "approval_decision"
}

struct AppNotification: Codable, Identifiable, Hashable {
    let id: UUID
    let recipientId: UUID
    let title: String
    let message: String
    let type: NotificationType
    let relatedEntityId: UUID
    var isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, message, type
        case recipientId = "recipient_id"
        case relatedEntityId = "related_entity_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// MARK: - Transaction

/// A completed (or pending) financial transaction.
/// Maps to Supabase `transactions` table.
struct Transaction: Codable, Identifiable, Hashable {
    let id: UUID
    let cartId: UUID
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
        case cartId      = "cart_id"
        case storeId     = "store_id"
        case associateId = "associate_id"
        case clientId    = "client_id"
        case totalAmount = "total_amount"
        case taxAmount   = "tax_amount"
        case isTaxFree   = "is_tax_free"
        case createdAt   = "created_at"
    }
}

enum TransactionStatus: String, Codable, CaseIterable {
    case pending   = "pending"
    case completed = "completed"
    case voided    = "voided"
    case refunded  = "refunded"
}

// MARK: - Tender

/// A payment method applied to a transaction.
/// Maps to Supabase `tenders` table.
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
    case card         = "card"
    case cash         = "cash"
    case giftCard     = "gift_card"
    case bankTransfer = "bank_transfer"
}

// MARK: - Gift Receipt

/// A gift receipt for a transaction.
/// Maps to Supabase `gift_receipts` table.
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

/// An exchange or return against a previous transaction.
/// Maps to Supabase `exchange_returns` table.
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
    case exchange   = "exchange"
    case returnItem = "return"
}

enum ExchangeReturnStatus: String, Codable, CaseIterable {
    case pending   = "pending"
    case approved  = "approved"
    case completed = "completed"
    case rejected  = "rejected"
}

/// Individual items being exchanged or returned.
/// Maps to Supabase `exchange_return_items` table.
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
