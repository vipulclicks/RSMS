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
        // 1. Create transaction (ignore backend error so UI continues)
        let txn = Transaction(
            id: UUID(), cartId: cart.id, storeId: _storeId, associateId: associateId,
            clientId: cart.clientId, totalAmount: totalAmount, taxAmount: taxAmount,
            currency: "INR", status: .completed, isTaxFree: isTaxFree, createdAt: .now
        )
        try? await dataStore.createTransaction(txn)

        // 2. Create tender
        let tender = Tender(
            id: UUID(), transactionId: txn.id, method: tenderMethod,
            amount: totalAmount, reference: razorpayPaymentId
        )
        try? await dataStore.createTender(tender)
        
        // 2.1 Create commission (5% rate, pending status)
        let commissionRate = 0.05
        let commission = Commission(
            id: UUID(),
            staffId: associateId,
            transactionId: txn.id,
            amount: totalAmount * commissionRate,
            rate: commissionRate,
            status: .pending,
            createdAt: .now
        )
        try? await dataStore.createCommission(commission)

        // 3. Update cart status locally and persist to Supabase
        let completed = UniversalCart(
            id: cart.id, type: cart.type, associateId: cart.associateId,
            clientId: cart.clientId, storeId: cart.storeId, status: .completed,
            note: cart.note, createdAt: cart.createdAt, updatedAt: .now
        )
        
        // Update local state first to ensure UI clears
        if let i = dataStore.universalCarts.firstIndex(where: { $0.id == cart.id }) {
            dataStore.universalCarts[i] = completed
        }
        
        // Then persist to Supabase — log if it fails so RLS issues are visible in the console
        do {
            try await dataStore.updateUniversalCart(completed)
        } catch {
            print("[POSCheckoutViewModel] ⚠️ Failed to update cart status to 'completed' in Supabase: \(error)")
            print("[POSCheckoutViewModel] ℹ️ If this is an RLS error, add an UPDATE policy on 'universal_carts' for the sales_associate role.")
        }

        // 4. Audit
        dataStore.logAudit(storeId: _storeId, action: "Checkout Completed", entityType: "Transaction", entityId: txn.id, performedBy: associateId)
        
        // 5. Update Sales Goal Achieved Amount
        if let currentGoal = dataStore.salesGoals
            .filter({ $0.staffId == associateId && $0.period == .monthly })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
        {
            let updatedGoal = SalesGoal(
                id: currentGoal.id,
                staffId: currentGoal.staffId,
                storeId: currentGoal.storeId,
                targetAmount: currentGoal.targetAmount,
                achievedAmount: currentGoal.achievedAmount + totalAmount,
                period: currentGoal.period,
                startDate: currentGoal.startDate,
                endDate: currentGoal.endDate,
                createdAt: currentGoal.createdAt
            )
            // Optimistic local update FIRST (so UI reacts immediately)
            if let i = dataStore.salesGoals.firstIndex(where: { $0.id == currentGoal.id }) {
                dataStore.salesGoals[i] = updatedGoal
            }
            // Then persist to Supabase — log error if it fails, do not silently swallow
            do {
                try await dataStore.updateSalesGoal(updatedGoal)
            } catch {
                print("[POSCheckoutViewModel] ⚠️ Failed to persist sales goal update: \(error)")
            }
        }
        
        // 6. Delete cart items from Supabase AND clear from memory
        // Each deleteUniversalCartItem call handles both the backend DELETE and the local removeAll.
        // Capture IDs first because the array mutates during deletion.
        let itemsToDelete = dataStore.universalCartItems.filter { $0.cartId == cart.id }
        for item in itemsToDelete {
            try? await dataStore.deleteUniversalCartItem(id: item.id)
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
