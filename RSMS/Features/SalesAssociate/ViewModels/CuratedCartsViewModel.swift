// CuratedCartsViewModel.swift
import Foundation
import Observation

@Observable
final class CuratedCartsViewModel {
    private let dataStore: DataStore
    
    var isLoading = false
    var errorMessage: String?
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    func curatedCarts(for clientId: UUID) -> [CuratedCart] {
        dataStore.curatedCarts(for: clientId)
    }
    
    func productName(for productId: UUID) -> String {
        dataStore.productName(for: productId)
    }
    
    func product(for productId: UUID) -> Product? {
        dataStore.product(by: productId)
    }
}
