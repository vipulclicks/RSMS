//
//  AppointmentViewModel.swift
//  RSMS
//
//  ViewModel for the Appointments & Remote Selling screen.
//  CRUD for appointments and curated carts.
//

import SwiftUI

@Observable
final class AppointmentViewModel {

    private let dataStore: DataStore
    let associateId: UUID
    let storeId: UUID

    var selectedDate: Date = .now
    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, associateId: UUID, storeId: UUID) {
        self.dataStore   = dataStore
        self.associateId = associateId
        self.storeId     = storeId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchStores()
            try await dataStore.fetchClients()
            try await dataStore.fetchProducts()
            try await dataStore.fetchAppointments(associateId: associateId)
            try await dataStore.fetchUniversalCarts(associateId: associateId, type: .curated)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Stores
    var stores: [Store] { dataStore.stores }

    // MARK: - Appointments
    var appointments: [Appointment] { dataStore.appointments.filter { $0.associateId == associateId } }

    var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.status == .scheduled || $0.status == .confirmed }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var statusCounts: [(status: AppointmentStatus, count: Int)] {
        Dictionary(grouping: appointments, by: \.status).map { ($0.key, $0.value.count) }
    }

    func createAppointment(_ a: Appointment) async throws {
        try await dataStore.createAppointment(a)
    }

    func updateAppointment(_ a: Appointment) async throws {
        try await dataStore.updateAppointment(a)
    }

    func cancelAppointment(id: UUID) async throws {
        try await dataStore.deleteAppointment(id: id)
    }

    // MARK: - Curated Carts (Remote Selling)
    var curatedCarts: [UniversalCart] {
        dataStore.universalCarts.filter { $0.associateId == associateId && $0.type == .curated }
    }

    func cartItems(for cartId: UUID) -> [UniversalCartItem] {
        dataStore.universalCartItems.filter { $0.cartId == cartId }
    }

    func createCuratedCart(_ cart: UniversalCart) async throws {
        try await dataStore.createUniversalCart(cart)
    }

    func addCartItem(_ item: UniversalCartItem) async throws {
        try await dataStore.createUniversalCartItem(item)
    }

    func removeCartItem(id: UUID) async throws {
        try await dataStore.deleteUniversalCartItem(id: id)
    }

    func shareCart(_ cart: UniversalCart) async throws {
        // Update status to shared
        let shared = UniversalCart(
            id: cart.id, type: cart.type, associateId: cart.associateId,
            clientId: cart.clientId, storeId: cart.storeId, status: .shared,
            note: cart.note, createdAt: cart.createdAt, updatedAt: .now
        )
        try await dataStore.updateUniversalCart(shared)
    }

    // MARK: - Helpers
    func clientName(for id: UUID?) -> String {
        guard let id else { return "Walk-in Client" }
        return dataStore.clientName(for: id)
    }

    func statusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled:   return RSMSTheme.info
        case .confirmed:   return RSMSTheme.success
        case .inProgress:  return RSMSTheme.warning
        case .completed:   return RSMSTheme.gold
        case .cancelled, .noShow: return RSMSTheme.danger
        }
    }

    func typeIcon(_ type: AppointmentType) -> String {
        switch type {
        case .inStore: return "building.2.fill"
        case .video:   return "video.fill"
        case .phone:   return "phone.fill"
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
