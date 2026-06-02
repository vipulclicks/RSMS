//
//  POSCheckoutViewModel.swift
//  RSMS
//
//  ViewModel for the POS & Checkout screen.
//  CRUD for cart sessions, items, discounts, transactions,
//  tenders, gift receipts, and exchange/returns.
//

import SwiftUI

@Observable
final class POSCheckoutViewModel {

    private let dataStore: DataStore
    private let associateId: UUID
    private let _storeId: UUID
    
    /// Public read-only access for views that need just the storeId (e.g. to fetch sales goals)
    var currentStoreId: UUID { _storeId }

    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, associateId: UUID, storeId: UUID) {
        self.dataStore   = dataStore
        self.associateId = associateId
        self._storeId    = storeId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchClients()
            try await dataStore.fetchUniversalCarts(associateId: associateId, type: .pos)
            try await dataStore.fetchDiscounts()
            try? await dataStore.fetchDiscountApprovalRequests()
            try? await dataStore.fetchAppNotifications()
            try await dataStore.fetchTransactions(storeId: _storeId)
            try await dataStore.fetchExchangeReturns(storeId: _storeId)
            try? await dataStore.fetchSalesGoals(storeId: _storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Cart Sessions (POS)
    var activeCarts: [UniversalCart] {
        dataStore.universalCarts.filter { $0.type == .pos && $0.status == .active && $0.associateId == associateId }
    }

    func createCartSession(clientId: UUID? = nil) async throws -> UniversalCart {
        let cart = UniversalCart(
            id: UUID(), type: .pos, associateId: associateId,
            clientId: clientId, storeId: _storeId, status: .active,
            note: nil, createdAt: .now, updatedAt: .now
        )
        return try await dataStore.createUniversalCart(cart)
    }

    func cartItems(for cartId: UUID) -> [UniversalCartItem] {
        dataStore.universalCartItems.filter { $0.cartId == cartId }
    }

    func addItemToCart(cartId: UUID, productId: UUID, quantity: Int = 1, unitPrice: Double) async throws {
        let item = UniversalCartItem(
            id: UUID(), cartId: cartId, productId: productId,
            quantity: quantity, unitPrice: unitPrice, discountApplied: nil, note: nil
        )
        try await dataStore.createUniversalCartItem(item)
    }

    func removeItemFromCart(id: UUID) async throws {
        try await dataStore.deleteUniversalCartItem(id: id)
    }

    // MARK: - Discounts
    var activeDiscounts: [Discount] { dataStore.discounts.filter(\.isActive) }

    func applyDiscount(cartItemId: UUID, discountAmount: Double) async throws {
        guard let item = dataStore.universalCartItems.first(where: { $0.id == cartItemId }) else { return }
        let updated = UniversalCartItem(
            id: item.id, cartId: item.cartId, productId: item.productId,
            quantity: item.quantity, unitPrice: item.unitPrice,
            discountApplied: discountAmount, note: item.note
        )
        try await dataStore.updateUniversalCartItem(updated)
    }

    // MARK: - Checkout
    func checkout(cart: UniversalCart, totalAmount: Double, taxAmount: Double, tenderMethod: TenderMethod, isTaxFree: Bool = false, razorpayPaymentId: String? = nil) async throws {
        // 1. Create Transaction
        let txn = Transaction(
            id: UUID(), cartId: cart.id, storeId: _storeId, associateId: associateId,
            clientId: cart.clientId, totalAmount: totalAmount, taxAmount: taxAmount,
            currency: "INR", status: .completed, isTaxFree: isTaxFree, createdAt: .now
        )
        do {
            try await dataStore.createTransaction(txn)
        } catch {
            print("[POSCheckoutViewModel] Failed to create transaction: \(error)")
        }

        // 2. Create tender
        let tender = Tender(
            id: UUID(), transactionId: txn.id, method: tenderMethod,
            amount: totalAmount, reference: razorpayPaymentId
        )
        do {
            try await dataStore.createTender(tender)
        } catch {
            print("[POSCheckoutViewModel] Failed to create tender: \(error)")
        }

        // 3. Update cart status locally and ignore backend error if it fails
        let completed = UniversalCart(
            id: cart.id, type: cart.type, associateId: cart.associateId,
            clientId: cart.clientId, storeId: cart.storeId, status: .completed,
            note: cart.note, createdAt: cart.createdAt, updatedAt: .now
        )
        
        // Update local state first to ensure UI clears
        if let i = dataStore.universalCarts.firstIndex(where: { $0.id == cart.id }) { 
            dataStore.universalCarts[i] = completed 
        }
        
        // Then try backend (will fail if RLS prevents it, but UI is already updated)
        do {
            try await dataStore.updateUniversalCart(completed)
        } catch {
            print("[POSCheckoutViewModel] Failed to update cart: \(error)")
        }

        // 4. Audit
        dataStore.logAudit(storeId: _storeId, action: "Checkout Completed", entityType: "Transaction", entityId: txn.id, performedBy: associateId)
        
        // 5. Calculate previous achieved for this month (excluding the current transaction)
        let currentMonth = Calendar.current.component(.month, from: .now)
        let currentYear = Calendar.current.component(.year, from: .now)
        
        let previousAchieved = dataStore.transactions
            .filter { 
                $0.associateId == associateId &&
                $0.id != txn.id &&
                Calendar.current.component(.month, from: $0.createdAt) == currentMonth &&
                Calendar.current.component(.year, from: $0.createdAt) == currentYear
            }
            .reduce(0) { $0 + $1.totalAmount }
        
        // 6. Clear in-memory cart items so UI reflects empty cart post-payment
        await MainActor.run {
            dataStore.universalCartItems.removeAll { $0.cartId == cart.id }
        }
        
        // 7. Auto-assign Commission (Static Tiered calculation based on Monthly Sales)
        var commissionAmount: Double = 0.0
        
        let tier1Threshold: Double = 1_000_000
        let tier2Threshold: Double = 2_000_000
        
        var remainingAmount = totalAmount
        var currentAchieved = previousAchieved
        
        // Tier 1: 0 to 10,00,000 (2%)
        if currentAchieved < tier1Threshold {
            let amountInTier1 = min(remainingAmount, tier1Threshold - currentAchieved)
            commissionAmount += amountInTier1 * 0.02
            remainingAmount -= amountInTier1
            currentAchieved += amountInTier1
        }
        
        // Tier 2: 10,00,001 to 20,00,000 (3%)
        if remainingAmount > 0 && currentAchieved < tier2Threshold {
            let amountInTier2 = min(remainingAmount, tier2Threshold - currentAchieved)
            commissionAmount += amountInTier2 * 0.03
            remainingAmount -= amountInTier2
            currentAchieved += amountInTier2
        }
        
        // Tier 3: Above 20,00,000 (5%)
        if remainingAmount > 0 {
            commissionAmount += remainingAmount * 0.05
        }
        
        let effectiveRate = totalAmount > 0 ? commissionAmount / totalAmount : 0.0
        
        if commissionAmount > 0 {
            let commission = Commission(
                id: UUID(),
                staffId: associateId,
                transactionId: txn.id,
                amount: commissionAmount,
                rate: effectiveRate,
                status: .approved,
                createdAt: .now
            )
            do {
                try await dataStore.createCommission(commission)
            } catch {
                print("[POSCheckoutViewModel] Failed to create commission: \(error)")
            }
        }
    }

    // MARK: - Gift Receipts
    func printGiftReceipt(transactionId: UUID, note: String?) async throws {
        let receipt = GiftReceipt(
            id: UUID(), transactionId: transactionId,
            recipientNote: note, printedAt: .now
        )
        try await dataStore.createGiftReceipt(receipt)
    }

    // MARK: - Returns / Exchanges
    var exchangeReturns: [ExchangeReturn] { dataStore.exchangeReturns.filter { $0.storeId == _storeId } }

    func processReturn(originalTransactionId: UUID, type: ExchangeReturnType, reason: String, refundAmount: Double?) async throws {
        let er = ExchangeReturn(
            id: UUID(), originalTransactionId: originalTransactionId, storeId: _storeId,
            type: type, reason: reason, status: .pending,
            refundAmount: refundAmount, processedBy: associateId, createdAt: .now
        )
        try await dataStore.createExchangeReturn(er)
        dataStore.logAudit(storeId: _storeId, action: "\(type.rawValue.capitalized) Initiated", entityType: "ExchangeReturn", entityId: er.id, performedBy: associateId)
    }

    // MARK: - Helpers
    func productName(for id: UUID) -> String { dataStore.productName(for: id) }
    func clientName(for id: UUID?) -> String {
        guard let id else { return "Walk-in" }
        return dataStore.clientName(for: id)
    }

    func transactionStatusColor(_ status: TransactionStatus) -> Color {
        switch status {
        case .pending:   return RSMSTheme.warning
        case .completed: return RSMSTheme.success
        case .voided:    return RSMSTheme.danger
        case .refunded:  return RSMSTheme.info
        }
    }
}
