//
//  ReturnViewModel.swift
//  RSMS
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class POSReturnViewModel {
    let dataStore: DataStore
    let returnRepository: ReturnRepository
    private let returnService = ReturnService.shared
    
    var searchText = ""
    var selectedOrder: Order?
    var selectedProduct: Product?
    var quantity = 1
    var reason: String = ""
    
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.returnRepository = ReturnRepository(dataStore: dataStore)
    }
    
    var searchedOrders: [Order] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return dataStore.orders.filter { order in
            // Search by Order ID, Client ID name, or Transaction ID
            order.id.uuidString.lowercased().contains(query) ||
            order.transactionId.uuidString.lowercased().contains(query) ||
            dataStore.client(by: order.clientId)?.fullName.lowercased().contains(query) == true
        }
    }
    
    func selectOrder(_ order: Order) {
        self.selectedOrder = order
        self.selectedProduct = nil
        self.quantity = 1
        self.reason = ""
        self.errorMessage = nil
        self.successMessage = nil
    }
    
    func getCartItems(for order: Order) -> [UniversalCartItem] {
        return dataStore.universalCartItems.filter { $0.cartId == order.cartId }
    }
    
    func getProduct(for productId: UUID) -> Product? {
        return dataStore.product(by: productId)
    }
    
    func getRemainingEligibleQuantity(for order: Order, productId: UUID) -> Int {
        let items = getCartItems(for: order)
        guard let item = items.first(where: { $0.productId == productId }) else { return 0 }
        let totalPurchased = item.quantity
        let alreadyReturned = dataStore.posReturnRequests
            .filter { $0.orderId == order.id && $0.productId == productId && $0.status != .rejected }
            .reduce(0) { $0 + $1.quantity }
        let alreadyExchanged = dataStore.posExchangeRequests
            .filter { $0.orderId == order.id && $0.originalProductId == productId && $0.status != .rejected }
            .reduce(0) { $0 + $1.quantity }
        return max(0, totalPurchased - alreadyReturned - alreadyExchanged)
    }
    
    func submitReturnRequest(associateId: UUID, storeId: UUID) async {
        guard let order = selectedOrder, let product = selectedProduct else {
            self.errorMessage = "Please select an order and a product."
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil
        
        let cartItems = getCartItems(for: order)
        let eligibilityResult = returnService.validateReturnEligibility(
            order: order,
            productId: product.id,
            quantity: quantity,
            cartItems: cartItems,
            existingRequests: dataStore.posReturnRequests
        )
        
        switch eligibilityResult {
        case .failure(let error):
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return
        case .success:
            break
        }
        
        guard let cartItem = cartItems.first(where: { $0.productId == product.id }) else {
            self.errorMessage = "Product item details missing."
            self.isLoading = false
            return
        }
        
        let refundAmount = returnService.calculateRefundAmount(cartItem: cartItem, quantity: quantity)
        
        let request = POSReturnRequest(
            orderId: order.id,
            productId: product.id,
            quantity: quantity,
            reason: reason,
            status: .inspectionPending,
            originalPaidAmount: refundAmount,
            storeId: storeId,
            associateId: associateId
        )
        
        do {
            try await returnRepository.createReturnRequest(request)
            self.successMessage = "Return request submitted successfully and is pending inspection."
            // Reset selection
            self.selectedProduct = nil
            self.quantity = 1
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
}
