//
//  POSMockData.swift
//  RSMS
//
//  RSMS_Mock_Data
//

import Foundation

// MARK: - CartSession

extension CartSession {
    static let preview = CartSession(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!,
        associateId: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, // UserProfile.previewAssociate.id
        clientId: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!, // ClientProfile.preview.id
        storeId: Store.preview.id,
        status: .active,
        createdAt: .now,
        updatedAt: .now
    )
}

// MARK: - CartItem

extension CartItem {
    static let preview = CartItem(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000010")!,
        sessionId: CartSession.preview.id,
        productId: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!, // Product.previewWatch.id
        quantity: 1,
        unitPrice: 24500.00,
        discountApplied: nil,
        notes: nil
    )
}

// MARK: - Discount

extension Discount {
    static let preview = Discount(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000020")!,
        code: "VIP-SUMMER",
        type: .percentage,
        value: 10.0,
        validFrom: .now.addingTimeInterval(-10 * 86400),
        validTo: .now.addingTimeInterval(20 * 86400),
        conditions: "Applies to selected collections only.",
        isActive: true,
        createdAt: .now
    )
}

// MARK: - Transaction

extension Transaction {
    static let preview = Transaction(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000030")!,
        cartSessionId: CartSession.preview.id,
        storeId: Store.preview.id,
        associateId: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        clientId: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
        totalAmount: 24500.00,
        taxAmount: 4083.33,
        currency: "EUR",
        status: .completed,
        isTaxFree: false,
        createdAt: .now
    )
}

// MARK: - Tender

extension Tender {
    static let previewCard = Tender(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000040")!,
        transactionId: Transaction.preview.id,
        method: .card,
        amount: 20000.00,
        reference: "AUTH-8989"
    )
    
    static let previewCash = Tender(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000041")!,
        transactionId: Transaction.preview.id,
        method: .cash,
        amount: 4500.00,
        reference: nil
    )
}

// MARK: - GiftReceipt

extension GiftReceipt {
    static let preview = GiftReceipt(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000050")!,
        transactionId: Transaction.preview.id,
        recipientNote: "Happy Anniversary, my love!",
        printedAt: .now
    )
}

// MARK: - ExchangeReturn

extension ExchangeReturn {
    static let preview = ExchangeReturn(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000060")!,
        originalTransactionId: Transaction.preview.id,
        storeId: Store.preview.id,
        type: .returnItem,
        reason: "Customer changed mind.",
        status: .completed,
        refundAmount: 24500.00,
        processedBy: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        createdAt: .now
    )
}

extension ExchangeReturnItem {
    static let preview = ExchangeReturnItem(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000070")!,
        exchangeReturnId: ExchangeReturn.preview.id,
        productId: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
        quantity: 1,
        reason: "Does not fit properly."
    )
}
