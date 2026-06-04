//
//  EventInvitationViewModel.swift
//  RSMS
//
//  State and actions for Boutique Manager client event invitations.
//

import Foundation

@Observable
final class EventInvitationViewModel {
    private(set) var events: [ClientEvent] = []
    private(set) var invitations: [EventInvitation] = []
    var selectedEventId: UUID?
    var searchText = ""
    var isLoading = false
    var isSending = false
    var errorMessage: String?

    var selectedEvent: ClientEvent? {
        events.first { $0.id == selectedEventId } ?? events.first
    }

    var selectedEventInvitations: [EventInvitation] {
        guard let eventId = selectedEvent?.id else { return [] }
        return invitations
            .filter { $0.eventId == eventId }
            .sorted { $0.sentAt > $1.sentAt }
    }

    var acceptedInvitations: [EventInvitation] {
        selectedEventInvitations.filter { $0.status == .confirmed || $0.status == .attended }
    }

    var pendingCount: Int {
        selectedEventInvitations.filter { $0.status == .invited }.count
    }

    var declinedCount: Int {
        selectedEventInvitations.filter { $0.status == .declined }.count
    }

    var acceptedCount: Int {
        acceptedInvitations.count
    }

    func uninvitedClients(from clients: [ClientProfile]) -> [ClientProfile] {
        guard let eventId = selectedEvent?.id else { return [] }
        let invitedClientIds = Set(invitations.filter { $0.eventId == eventId }.map(\.clientId))
        let available = clients.filter { !invitedClientIds.contains($0.id) }
        guard !searchText.isEmpty else { return available.sorted { $0.fullName < $1.fullName } }
        return available
            .filter { $0.fullName.localizedCaseInsensitiveContains(searchText) || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false) }
            .sorted { $0.fullName < $1.fullName }
    }

    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await dataStore.fetchClientEvents(storeId: storeId)
            try await dataStore.fetchClients()
            try await dataStore.fetchEventInvitations(eventIds: dataStore.clientEvents.map(\.id))

            events = dataStore.clientEvents.sorted { $0.date > $1.date }
            invitations = dataStore.eventInvitations
            if selectedEventId == nil || !events.contains(where: { $0.id == selectedEventId }) {
                selectedEventId = events.first?.id
            }
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
    }

    @MainActor
    func createEvent(
        title: String,
        description: String?,
        type: ClientEventType,
        date: Date,
        endDate: Date?,
        capacity: Int,
        location: String?,
        storeId: UUID,
        createdBy: UUID,
        dataStore: DataStore
    ) async {
        errorMessage = nil
        let event = ClientEvent(
            id: UUID(),
            storeId: storeId,
            title: title,
            description: description,
            type: type,
            date: date,
            endDate: endDate,
            capacity: capacity,
            location: location,
            createdBy: createdBy,
            createdAt: .now
        )

        do {
            let created = try await dataStore.createClientEvent(event)
            events.insert(created, at: 0)
            selectedEventId = created.id
        } catch {
            errorMessage = "Failed to create event: \(error.localizedDescription)"
        }
    }

    @MainActor
    func sendInvitations(to clients: [ClientProfile], dataStore: DataStore) async {
        guard let eventId = selectedEvent?.id, !clients.isEmpty else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }

        let now = Date()
        let newInvitations = clients.map {
            EventInvitation(
                id: UUID(),
                eventId: eventId,
                clientId: $0.id,
                status: .invited,
                sentAt: now,
                respondedAt: nil,
                plusOne: false
            )
        }

        do {
            let created = try await dataStore.createEventInvitations(newInvitations)
            invitations.append(contentsOf: created)
            searchText = ""
            
            // Trigger the Supabase Edge Function to send emails
            try await dataStore.sendInviteEmails(invitationIds: created.map { $0.id })
            
        } catch {
            errorMessage = "Failed to send invitations: \(error.localizedDescription)"
        }
    }

    @MainActor
    func updateRSVP(_ invitation: EventInvitation, status: RSVPStatus, dataStore: DataStore) async {
        let updated = EventInvitation(
            id: invitation.id,
            eventId: invitation.eventId,
            clientId: invitation.clientId,
            status: status,
            sentAt: invitation.sentAt,
            respondedAt: status == .invited ? nil : .now,
            plusOne: invitation.plusOne
        )

        do {
            try await dataStore.updateEventInvitation(updated)
            if let index = invitations.firstIndex(where: { $0.id == updated.id }) {
                invitations[index] = updated
            }
        } catch {
            errorMessage = "Failed to update RSVP: \(error.localizedDescription)"
        }
    }
}
