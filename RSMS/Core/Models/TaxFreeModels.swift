//
//  TaxFreeModels.swift
//  RSMS
//

import Foundation

public enum TaxFreeStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case refunded = "refunded"
    
    public var id: String { rawValue }
}

public struct TaxFreeConfig: Codable, Identifiable, Hashable {
    public var id: UUID
    public var storeId: UUID
    public var isEnabled: Bool
    public var minPurchaseAmount: Decimal
    public var refundPercentage: Decimal
    public var serviceFee: Decimal
    public var eligibleCountries: [String]
    public var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case isEnabled = "is_enabled"
        case minPurchaseAmount = "min_purchase_amount"
        case refundPercentage = "refund_percentage"
        case serviceFee = "service_fee"
        case eligibleCountries = "eligible_countries"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: UUID = UUID(),
        storeId: UUID,
        isEnabled: Bool = true,
        minPurchaseAmount: Decimal = 50000.00,
        refundPercentage: Decimal = 100.00,
        serviceFee: Decimal = 0.00,
        eligibleCountries: [String] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.storeId = storeId
        self.isEnabled = isEnabled
        self.minPurchaseAmount = minPurchaseAmount
        self.refundPercentage = refundPercentage
        self.serviceFee = serviceFee
        self.eligibleCountries = eligibleCountries
        self.updatedAt = updatedAt
    }
}

public struct TaxFreeTransaction: Codable, Identifiable, Hashable {
    public var id: UUID
    public var orderId: UUID
    public var customerName: String
    public var passportNumber: String
    public var countryOfResidence: String
    public var transactionDate: Date
    public var taxAmount: Decimal
    public var refundAmount: Decimal
    public var status: TaxFreeStatus
    public var createdBy: UUID
    public var createdAt: Date
    public var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case customerName = "customer_name"
        case passportNumber = "passport_number"
        case countryOfResidence = "country_of_residence"
        case transactionDate = "transaction_date"
        case taxAmount = "tax_amount"
        case refundAmount = "refund_amount"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: UUID = UUID(),
        orderId: UUID,
        customerName: String,
        passportNumber: String,
        countryOfResidence: String,
        transactionDate: Date = Date(),
        taxAmount: Decimal,
        refundAmount: Decimal,
        status: TaxFreeStatus = .pending,
        createdBy: UUID,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.orderId = orderId
        self.customerName = customerName
        self.passportNumber = passportNumber
        self.countryOfResidence = countryOfResidence
        self.transactionDate = transactionDate
        self.taxAmount = taxAmount
        self.refundAmount = refundAmount
        self.status = status
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TaxFreeAudit: Codable, Identifiable, Hashable {
    public var id: UUID
    public var taxFreeTransactionId: UUID?
    public var userId: UUID
    public var action: String
    public var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case taxFreeTransactionId = "tax_free_transaction_id"
        case userId = "user_id"
        case action
        case timestamp
    }
    
    public init(
        id: UUID = UUID(),
        taxFreeTransactionId: UUID? = nil,
        userId: UUID,
        action: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.taxFreeTransactionId = taxFreeTransactionId
        self.userId = userId
        self.action = action
        self.timestamp = timestamp
    }
}
