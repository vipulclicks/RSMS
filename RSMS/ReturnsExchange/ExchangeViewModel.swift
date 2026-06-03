//
//  ExchangeViewModel.swift
//  RSMS
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class POSExchangeViewModel {
    let dataStore: DataStore
    let exchangeRepository: ExchangeRepository
    private let exchangeService = ExchangeService.shared
    
    var selectedOrder: Order?
    var selectedProductToExchange: Product?
    var selectedReplacementProduct: Product?
    var quantity = 1
    var reason: String = ""
    
    // Calculations
    var returnedValue: Decimal = 0
    var replacementValue: Decimal = 0
    var differenceAmount: Decimal = 0
    
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.exchangeRepository = ExchangeRepository(dataStore: dataStore)
    }
    
    func selectOrder(_ order: Order) {
        self.selectedOrder = order
        self.selectedProductToExchange = nil
        self.selectedReplacementProduct = nil
        self.quantity = 1
        self.reason = ""
        self.returnedValue = 0
        self.replacementValue = 0
        self.differenceAmount = 0
        self.errorMessage = nil
        self.successMessage = nil
    }
    
    func selectProductToExchange(_ product: Product) {
        self.selectedProductToExchange = product
        self.selectedReplacementProduct = nil
        self.quantity = 1
        self.errorMessage = nil
        self.successMessage = nil
        recalculateDifference()
    }
    
    func selectReplacementProduct(_ product: Product) {
        self.selectedReplacementProduct = product
        self.errorMessage = nil
        self.successMessage = nil
        recalculateDifference()
    }
    
    func updateQuantity(_ qty: Int) {
        self.quantity = qty
        recalculateDifference()
    }
    
    func recalculateDifference() {
        guard let order = selectedOrder,
              let origProduct = selectedProductToExchange,
              let replProduct = selectedReplacementProduct else {
            return
        }
        
        let cartItems = dataStore.universalCartItems.filter { $0.cartId == order.cartId }
        guard let cartItem = cartItems.first(where: { $0.productId == origProduct.id }) else {
            return
        }
        
        let results = exchangeService.calculateExchangeDifference(
            originalItem: cartItem,
            replacementProduct: replProduct,
            quantity: quantity
        )
        
        self.returnedValue = results.returnedValue
        self.replacementValue = results.replacementValue
        self.differenceAmount = results.difference
    }
    
    func submitExchangeRequest(associateId: UUID, storeId: UUID) async {
        guard let order = selectedOrder,
              let origProduct = selectedProductToExchange,
              let replProduct = selectedReplacementProduct else {
            self.errorMessage = "Please complete product selections first."
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil
        
        let cartItems = dataStore.universalCartItems.filter { $0.cartId == order.cartId }
        
        let validationResult = exchangeService.validateExchangeEligibility(
            order: order,
            originalProductId: origProduct.id,
            replacementProductId: replProduct.id,
            quantity: quantity,
            cartItems: cartItems,
            existingReturns: dataStore.posReturnRequests,
            existingExchanges: dataStore.posExchangeRequests,
            stockItems: dataStore.stockItems,
            storeId: storeId
        )
        
        switch validationResult {
        case .failure(let error):
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return
        case .success:
            break
        }
        
        recalculateDifference()
        
        let request = POSExchangeRequest(
            orderId: order.id,
            originalProductId: origProduct.id,
            replacementProductId: replProduct.id,
            quantity: quantity,
            reason: reason,
            status: .inspectionPending,
            returnedItemValue: returnedValue,
            replacementItemValue: replacementValue,
            differenceAmount: differenceAmount,
            storeId: storeId,
            associateId: associateId
        )
        
        do {
            try await exchangeRepository.createExchangeRequest(request)
            self.successMessage = "Exchange request submitted successfully and is pending inspection."
            // Reset selection
            self.selectedProductToExchange = nil
            self.selectedReplacementProduct = nil
            self.quantity = 1
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
}
