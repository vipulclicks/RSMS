//
//  POSMockData.swift
//  RSMS
//
//  Preview data for POS, carts, transactions, and returns.
//  Updated to match Supabase-aligned UniversalCart models.
//

import Foundation

// MARK: - Universal Cart Mock Data

extension UniversalCart {
    /// A POS cart session
    static let previewPOS = UniversalCart(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000200")!,
        type: .pos,
        associateId: UserProfile.previewAssociate.id,
        clientId: ClientProfile.preview.id,
        storeId: Store.preview.id,
        status: .active,
        note: nil,
        createdAt: .now,
        updatedAt: .now
    )

    /// A curated cart for remote selling
    static let previewCurated = UniversalCart(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
        type: .curated,
        associateId: UserProfile.previewAssociate.id,
        clientId: ClientProfile.preview.id,
        storeId: Store.preview.id,
        status: .shared,
        note: "Anniversary selection — platinum and diamond pieces",
        createdAt: .now,
        updatedAt: .now
    )

    static let all: [UniversalCart] = [.previewPOS, .previewCurated]
}

// MARK: - Universal Cart Item Mock Data

extension UniversalCartItem {
    static let previewPOSItem = UniversalCartItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000210")!,
        cartId: UniversalCart.previewPOS.id,
        productId: Product.preview.id,
        quantity: 1,
        unitPrice: 24500.00,
        discountApplied: nil,
        note: nil
    )

    static let previewCuratedItem = UniversalCartItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000211")!,
        cartId: UniversalCart.previewCurated.id,
        productId: Product.previewWatch.id,
        quantity: 1,
        unitPrice: nil,
        discountApplied: nil,
        note: "Client expressed interest during last visit"
    )

    static let all: [UniversalCartItem] = [.previewPOSItem, .previewCuratedItem]
}

// MARK: - Discount Mock Data

extension Discount {
    static let preview = Discount(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000220")!,
        code: "VIP10",
        type: .percentage,
        value: 10.0,
        validFrom: Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
        validTo: Calendar.current.date(byAdding: .month, value: 2, to: .now)!,
        conditions: "VIP clients only, min purchase €5,000",
        isActive: true,
        createdAt: .now
    )

    static let all: [Discount] = [.preview]
}

// MARK: - Transaction Mock Data

extension Transaction {
    static let preview = Transaction(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000230")!,
        cartId: UniversalCart.previewPOS.id,
        storeId: Store.preview.id,
        associateId: UserProfile.previewAssociate.id,
        clientId: ClientProfile.preview.id,
        totalAmount: 24500.00,
        taxAmount: 4900.00,
        currency: "EUR",
        status: .completed,
        isTaxFree: false,
        createdAt: .now
    )

    static let all: [Transaction] = [.preview]
}

// MARK: - Tender Mock Data

extension Tender {
    static let preview = Tender(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000240")!,
        transactionId: Transaction.preview.id,
        method: .card,
        amount: 24500.00,
        reference: "VISA •••• 4242"
    )

    static let all: [Tender] = [.preview]
}

// MARK: - Gift Receipt Mock Data

extension GiftReceipt {
    static let preview = GiftReceipt(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000250")!,
        transactionId: Transaction.preview.id,
        recipientNote: "Happy Anniversary, my love ♥",
        printedAt: nil
    )

    static let all: [GiftReceipt] = [.preview]
}

// MARK: - Exchange Return Mock Data

extension ExchangeReturn {
    static let preview = ExchangeReturn(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000260")!,
        originalTransactionId: Transaction.preview.id,
        storeId: Store.preview.id,
        type: .exchange,
        reason: "Client prefers rose gold variant",
        status: .pending,
        refundAmount: nil,
        processedBy: UserProfile.previewAssociate.id,
        createdAt: .now
    )

    static let all: [ExchangeReturn] = [.preview]
}

// MARK: - Exchange Return Item Mock Data

extension ExchangeReturnItem {
    static let preview = ExchangeReturnItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000270")!,
        exchangeReturnId: ExchangeReturn.preview.id,
        productId: Product.preview.id,
        quantity: 1,
        reason: "Prefers rose gold"
    )

    static let all: [ExchangeReturnItem] = [.preview]
}
