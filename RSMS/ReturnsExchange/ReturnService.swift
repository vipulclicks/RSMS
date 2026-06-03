//
//  ReturnService.swift
//  RSMS
//

import Foundation

enum ReturnValidationError: LocalizedError {
    case orderCancelled
    case productNotInOrder
    case quantityExceeded(purchased: Int, alreadyReturned: Int, requested: Int)
    case returnWindowExpired(daysLimit: Int)
    
    var errorDescription: String? {
        switch self {
        case .orderCancelled:
            return "Cannot return items from a cancelled order."
        case .productNotInOrder:
            return "The product was not part of the original order."
        case .quantityExceeded(let purchased, let alreadyReturned, let requested):
            return "Cannot return \(requested) units. Purchased: \(purchased), already returned/pending: \(alreadyReturned)."
        case .returnWindowExpired(let limit):
            return "The return window of \(limit) days has expired."
        }
    }
}

final class ReturnService {
    static let shared = ReturnService()
    
    private init() {}
    
    /// Checks if a product in an order is eligible for return.
    func validateReturnEligibility(
        order: Order,
        productId: UUID,
        quantity: Int,
        cartItems: [UniversalCartItem],
        existingRequests: [POSReturnRequest],
        returnWindowDays: Int = 30
    ) -> Result<Void, Error> {
        // 1. Check if cancelled
        if order.status == .cancelled {
            return .failure(ReturnValidationError.orderCancelled)
        }
        
        // 2. Check if product is in original order
        let orderItems = cartItems.filter { $0.cartId == order.cartId }
        guard let originalItem = orderItems.first(where: { $0.productId == productId }) else {
            return .failure(ReturnValidationError.productNotInOrder)
        }
        
        // 3. Check quantity limits
        let purchasedQty = originalItem.quantity
        let alreadyReturnedQty = existingRequests
            .filter { $0.orderId == order.id && $0.productId == productId && $0.status != .rejected }
            .reduce(0) { $0 + $1.quantity }
        
        if alreadyReturnedQty + quantity > purchasedQty {
            return .failure(ReturnValidationError.quantityExceeded(
                purchased: purchasedQty,
                alreadyReturned: alreadyReturnedQty,
                requested: quantity
            ))
        }
        
        // 4. Check return window
        let days = Calendar.current.dateComponents([.day], from: order.createdAt, to: Date()).day ?? 0
        if days > returnWindowDays {
            return .failure(ReturnValidationError.returnWindowExpired(daysLimit: returnWindowDays))
        }
        
        return .success(())
    }
    
    /// Calculates the exact original paid amount for the return request using Decimal.
    func calculateRefundAmount(
        cartItem: UniversalCartItem,
        quantity: Int
    ) -> Decimal {
        let unitPrice = cartItem.unitPrice?.toDecimal ?? 0
        let discount = cartItem.discountApplied?.toDecimal ?? 0
        let actualUnitPrice = max(0, unitPrice - discount)
        return actualUnitPrice * Decimal(quantity)
    }
}

extension Double {
    var toDecimal: Decimal {
        Decimal(string: String(format: "%.2f", self)) ?? Decimal(self)
    }
}
