//
//  OmnichannelViewModel.swift
//  RSMS
//
//  ViewModel for the Omnichannel Fulfilment screen.
//  CRUD for BOPIS, endless aisle orders, and ship-from-store slips.
//

import SwiftUI

@Observable
final class OmnichannelViewModel {

    private let dataStore: DataStore
    private let storeId: UUID
    private let associateId: UUID

    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, storeId: UUID, associateId: UUID) {
        self.dataStore   = dataStore
        self.storeId     = storeId
        self.associateId = associateId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchClients()
            try await dataStore.fetchProducts()
            try await dataStore.fetchOmnichannelOrders(storeId: storeId)
            try await dataStore.fetchShipFromStoreSlips(storeId: storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - BOPIS Orders
    var bopisOrders: [OmnichannelOrder] {
        dataStore.omnichannelOrders.filter { $0.type == .bopis && $0.storeId == storeId }
    }

    func createBOPISOrder(_ order: OmnichannelOrder) async throws {
        try await dataStore.createOmnichannelOrder(order)
    }

    func prepareBOPIS(_ order: OmnichannelOrder) async throws {
        let updated = OmnichannelOrder(
            id: order.id, type: order.type, onlineOrderId: order.onlineOrderId,
            storeId: order.storeId, clientId: order.clientId, associateId: order.associateId,
            productId: order.productId, sourceStoreId: order.sourceStoreId, sourceDCId: order.sourceDCId,
            status: .preparing, shippingAddress: order.shippingAddress,
            estimatedDelivery: order.estimatedDelivery, preparedBy: associateId,
            preparedAt: .now, pickedUpAt: order.pickedUpAt, notes: order.notes, createdAt: order.createdAt
        )
        try await dataStore.updateOmnichannelOrder(updated)
    }

    func markReady(_ order: OmnichannelOrder) async throws {
        let updated = OmnichannelOrder(
            id: order.id, type: order.type, onlineOrderId: order.onlineOrderId,
            storeId: order.storeId, clientId: order.clientId, associateId: order.associateId,
            productId: order.productId, sourceStoreId: order.sourceStoreId, sourceDCId: order.sourceDCId,
            status: .ready, shippingAddress: order.shippingAddress,
            estimatedDelivery: order.estimatedDelivery, preparedBy: order.preparedBy,
            preparedAt: order.preparedAt, pickedUpAt: order.pickedUpAt, notes: order.notes, createdAt: order.createdAt
        )
        try await dataStore.updateOmnichannelOrder(updated)
    }

    func markPickedUp(_ order: OmnichannelOrder) async throws {
        let updated = OmnichannelOrder(
            id: order.id, type: order.type, onlineOrderId: order.onlineOrderId,
            storeId: order.storeId, clientId: order.clientId, associateId: order.associateId,
            productId: order.productId, sourceStoreId: order.sourceStoreId, sourceDCId: order.sourceDCId,
            status: .pickedUp, shippingAddress: order.shippingAddress,
            estimatedDelivery: order.estimatedDelivery, preparedBy: order.preparedBy,
            preparedAt: order.preparedAt, pickedUpAt: .now, notes: order.notes, createdAt: order.createdAt
        )
        try await dataStore.updateOmnichannelOrder(updated)
    }

    // MARK: - Endless Aisle Orders
    var endlessAisleOrders: [OmnichannelOrder] {
        dataStore.omnichannelOrders.filter { $0.type == .endlessAisle && $0.storeId == storeId }
    }

    func createEndlessAisleOrder(_ order: OmnichannelOrder) async throws {
        try await dataStore.createOmnichannelOrder(order)
    }

    // MARK: - Ship From Store
    var shipSlips: [ShipFromStoreSlip] {
        dataStore.shipFromStoreSlips.filter { $0.storeId == storeId }
    }

    func createShipSlip(_ slip: ShipFromStoreSlip) async throws {
        try await dataStore.createShipFromStoreSlip(slip)
    }

    func updateTracking(_ slip: ShipFromStoreSlip) async throws {
        try await dataStore.updateShipFromStoreSlip(slip)
    }

    // MARK: - Helpers
    func clientName(for id: UUID) -> String { dataStore.clientName(for: id) }
    func productName(for id: UUID?) -> String {
        guard let id else { return "Multiple Items" }
        return dataStore.productName(for: id)
    }

    func orderStatusColor(_ status: OmnichannelOrderStatus) -> Color {
        switch status {
        case .pending:    return RSMSTheme.textSecondary
        case .preparing:  return RSMSTheme.warning
        case .ready:      return RSMSTheme.info
        case .pickedUp:   return RSMSTheme.success
        case .placed:     return RSMSTheme.textSecondary
        case .confirmed:  return RSMSTheme.info
        case .shipped:    return RSMSTheme.gold
        case .delivered:  return RSMSTheme.success
        case .cancelled:  return RSMSTheme.danger
        }
    }
}
