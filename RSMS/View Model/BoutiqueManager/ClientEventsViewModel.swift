//
//  ClientEventsViewModel.swift
//  RSMS
//
//  ViewModel for the Client Events & VIP Experiences screen.
//  CRUD for events and invitations with RSVP analytics.
//

import SwiftUI

@Observable
final class ClientEventsViewModel {

    private let dataStore: DataStore
    private let storeId: UUID

    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, storeId: UUID) {
        self.dataStore = dataStore
        self.storeId   = storeId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchClientEvents(storeId: storeId)
            try await dataStore.fetchClients()
            // Load invitations for all events
            for event in dataStore.clientEvents {
                try await dataStore.fetchEventInvitations(eventId: event.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Events
    var events: [ClientEvent] { dataStore.clientEvents.filter { $0.storeId == storeId } }
    var upcomingEvents: [ClientEvent] { events.filter { $0.date > .now }.sorted { $0.date < $1.date } }

    func createEvent(_ event: ClientEvent) async throws {
        try await dataStore.createClientEvent(event)
    }

    func updateEvent(_ event: ClientEvent) async throws {
        try await dataStore.updateClientEvent(event)
    }

    func deleteEvent(id: UUID) async throws {
        try await dataStore.deleteClientEvent(id: id)
    }

    // MARK: - Invitations
    func invitations(for eventId: UUID) -> [EventInvitation] {
        dataStore.eventInvitations.filter { $0.eventId == eventId }
    }

    func sendInvitation(_ invitation: EventInvitation) async throws {
        try await dataStore.createEventInvitation(invitation)
    }

    func updateRSVP(_ invitation: EventInvitation) async throws {
        try await dataStore.updateEventInvitation(invitation)
    }

    // MARK: - Analytics
    func rsvpCounts(for eventId: UUID) -> (confirmed: Int, declined: Int, pending: Int, attended: Int) {
        let invs = invitations(for: eventId)
        return (
            confirmed: invs.filter { $0.status == .confirmed }.count,
            declined:  invs.filter { $0.status == .declined }.count,
            pending:   invs.filter { $0.status == .invited }.count,
            attended:  invs.filter { $0.status == .attended }.count
        )
    }

    func capacityUsage(for event: ClientEvent) -> Double {
        let confirmed = invitations(for: event.id).filter { $0.status == .confirmed || $0.status == .attended }.count
        guard event.capacity > 0 else { return 0 }
        return Double(confirmed) / Double(event.capacity)
    }

    // MARK: - Helpers
    func clientName(for id: UUID) -> String { dataStore.clientName(for: id) }
    func creatorName(for id: UUID) -> String { dataStore.userName(for: id) }

    func eventTypeColor(_ type: ClientEventType) -> Color {
        switch type {
        case .trunkShow:      return RSMSTheme.gold
        case .vipPreview:     return RSMSTheme.info
        case .launch:         return RSMSTheme.success
        case .privateViewing: return RSMSTheme.warning
        }
    }

    func rsvpColor(_ status: RSVPStatus) -> Color {
        switch status {
        case .invited:   return RSMSTheme.textSecondary
        case .confirmed: return RSMSTheme.success
        case .declined:  return RSMSTheme.danger
        case .attended:  return RSMSTheme.gold
        case .noShow:    return RSMSTheme.warning
        }
    }
}
