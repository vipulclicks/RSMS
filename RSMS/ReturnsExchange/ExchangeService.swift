//
//  ExchangeService.swift
//  RSMS
//

import Foundation

enum ExchangeValidationError: LocalizedError {
    case orderCancelled
    case originalProductNotInOrder
    case quantityExceeded(purchased: Int, alreadyReturned: Int, requested: Int)
    case returnWindowExpired(daysLimit: Int)
    case replacementProductUnavailable(requested: Int, available: Int)
    
    var errorDescription: String? {
        switch self {
        case .orderCancelled:
            return "Cannot exchange items from a cancelled order."
        case .originalProductNotInOrder:
            return "The product to exchange was not part of the original order."
        case .quantityExceeded(let purchased, let alreadyReturned, let requested):
            return "Cannot exchange \(requested) units. Purchased: \(purchased), already returned/exchanged: \(alreadyReturned)."
        case .returnWindowExpired(let limit):
            return "The exchange window of \(limit) days has expired."
        case .replacementProductUnavailable(let requested, let available):
            return "The replacement product is unavailable in inventory. Requested: \(requested), available: \(available)."
        }
    }
}

final class ExchangeService {
    static let shared = ExchangeService()
    
    private init() {}
    
    /// Validates exchange eligibility.
    func validateExchangeEligibility(
        order: Order,
        originalProductId: UUID,
        replacementProductId: UUID,
        quantity: Int,
        cartItems: [UniversalCartItem],
        existingReturns: [POSReturnRequest],
        existingExchanges: [POSExchangeRequest],
        stockItems: [StockItem],
        storeId: UUID,
        returnWindowDays: Int = 30
    ) -> Result<Void, Error> {
        // 1. Check if cancelled
        if order.status == .cancelled {
            return .failure(ExchangeValidationError.orderCancelled)
        }
        
        // 2. Check if original product is in order
        let orderItems = cartItems.filter { $0.cartId == order.cartId }
        guard let originalItem = orderItems.first(where: { $0.productId == originalProductId }) else {
            return .failure(ExchangeValidationError.originalProductNotInOrder)
        }
        
        // 3. Check quantity limits (sum of return requests and exchange requests)
        let purchasedQty = originalItem.quantity
        let alreadyReturnedQty = existingReturns
            .filter { $0.orderId == order.id && $0.productId == originalProductId && $0.status != .rejected }
            .reduce(0) { $0 + $1.quantity }
        let alreadyExchangedQty = existingExchanges
            .filter { $0.orderId == order.id && $0.originalProductId == originalProductId && $0.status != .rejected }
            .reduce(0) { $0 + $1.quantity }
            
        if alreadyReturnedQty + alreadyExchangedQty + quantity > purchasedQty {
            return .failure(ExchangeValidationError.quantityExceeded(
                purchased: purchasedQty,
                alreadyReturned: alreadyReturnedQty + alreadyExchangedQty,
                requested: quantity
            ))
        }
        
        // 4. Check return window
        let days = Calendar.current.dateComponents([.day], from: order.createdAt, to: Date()).day ?? 0
        if days > returnWindowDays {
            return .failure(ExchangeValidationError.returnWindowExpired(daysLimit: returnWindowDays))
        }
        
        // 5. Check replacement inventory availability
        let replacementStock = stockItems.first { $0.productId == replacementProductId && $0.storeId == storeId }
        let availableQty = replacementStock?.quantity ?? 0
        if availableQty < quantity {
            return .failure(ExchangeValidationError.replacementProductUnavailable(requested: quantity, available: availableQty))
        }
        
        return .success(())
    }
    
    /// Calculates the exchange difference: Replacement Value - Returned Value.
    func calculateExchangeDifference(
        originalItem: UniversalCartItem,
        originalProduct: Product? = nil,
        replacementProduct: Product,
        quantity: Int
    ) -> (returnedValue: Decimal, replacementValue: Decimal, difference: Decimal) {
        // Prefer catalog product price over stale cart item unitPrice
        let catalogPrice = originalProduct?.price.toDecimal
        let unitPrice = catalogPrice ?? originalItem.unitPrice?.toDecimal ?? 0
        let discount = originalItem.discountApplied?.toDecimal ?? 0
        let actualUnitPrice = max(0, unitPrice - discount)
        let returnedValue = actualUnitPrice * Decimal(quantity)
        
        let replacementValue = replacementProduct.price.toDecimal * Decimal(quantity)
        let difference = replacementValue - returnedValue
        
        return (returnedValue, replacementValue, difference)
    }

}
