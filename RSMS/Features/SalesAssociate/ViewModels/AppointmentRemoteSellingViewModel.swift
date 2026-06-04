//
//  AppointmentRemoteSellingViewModel.swift
//  RSMS
//
//  Fetches live appointments, carts, clients and products from Supabase.
//  Replaces hardcoded preview data.
//

import SwiftUI

@Observable
final class AppointmentRemoteSellingViewModel {

    // MARK: - State
    private(set) var appointments: [Appointment] = []
    private(set) var curatedCarts: [UniversalCart] = []
    private(set) var cartItems: [UniversalCartItem] = []
    private(set) var clients: [ClientProfile] = []
    private(set) var products: [Product] = []
    var isLoading = false
    var errorMessage: String? = nil

    // MARK: - Convenience (first items — kept for single-record views)
    var appointment: Appointment? { appointments.first }
    var curatedCart: UniversalCart? { curatedCarts.first }
    var curatedItem: UniversalCartItem? { cartItems.first }
    var client: ClientProfile? { clients.first }

    var cartProduct: Product? {
        guard let item = curatedItem else { return nil }
        return products.first(where: { $0.id == item.productId })
    }

    // MARK: - Load

    @MainActor
    func load(dataStore: DataStore, storeId: UUID? = nil, associateId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await dataStore.fetchAppointments(storeId: storeId, associateId: associateId) }
                group.addTask { try await dataStore.fetchUniversalCarts(associateId: associateId, type: .curated) }
                group.addTask { try await dataStore.fetchClients() }
                group.addTask { try await dataStore.fetchProducts() }
                try await group.waitForAll()
            }

            appointments = dataStore.appointments
            curatedCarts = dataStore.universalCarts.filter { $0.type == .curated }
            clients = dataStore.clients
            products = dataStore.products

            // Load cart items for the first curated cart
            if let firstCart = curatedCarts.first {
                try await dataStore.fetchUniversalCartItems(cartId: firstCart.id)
                cartItems = dataStore.universalCartItems.filter { $0.cartId == firstCart.id }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Formatting

    func formattedDate(_ date: Date) -> String {
        RSMSDateFormatter.dateTime.string(from: date)
    }

    func appointmentStatusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled:  return RSMSTheme.info
        case .confirmed:  return RSMSTheme.success
        case .inProgress: return RSMSTheme.warning
        case .completed:  return RSMSTheme.textSecondary
        case .cancelled:  return RSMSTheme.danger
        case .noShow:     return RSMSTheme.danger
        }
    }

    func cartStatusColor(_ status: CartStatus) -> Color {
        switch status {
        case .draft:     return RSMSTheme.textSecondary
        case .shared:    return RSMSTheme.info
        case .viewed:    return RSMSTheme.warning
        case .converted: return RSMSTheme.success
        case .expired:   return RSMSTheme.danger
        case .active, .completed, .abandoned: return RSMSTheme.textSecondary
        }
    }
}
