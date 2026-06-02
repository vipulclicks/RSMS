import Foundation
import SwiftUI

@Observable
final class BoutiqueEventsViewModel {
    var isLoading = false
    var error: Error?
    
    init() {}
    
    // Fetch all events for the boutique
    func fetchEvents(storeId: UUID, dataStore: DataStore) async {
        isLoading = true
        do {
            try await dataStore.fetchClientEvents(storeId: storeId)
        } catch {
            self.error = error
            print("Failed to fetch events: \(error)")
        }
        isLoading = false
    }
    
    // Fetch invitations for a specific event
    func fetchInvitations(for eventId: UUID, dataStore: DataStore) async {
        isLoading = true
        do {
            try await dataStore.fetchEventInvitations(eventId: eventId)
        } catch {
            self.error = error
            print("Failed to fetch invitations: \(error)")
        }
        isLoading = false
    }
    
    // Get events
    func events(from dataStore: DataStore) -> [ClientEvent] {
        return dataStore.clientEvents
    }
    
    // Get invitations
    func invitations(for eventId: UUID, from dataStore: DataStore) -> [EventInvitation] {
        return dataStore.eventInvitations.filter { $0.eventId == eventId }
    }
    
    // Create an event
    func addEvent(title: String, date: Date, venue: String, type: ClientEventType, storeId: UUID, dataStore: DataStore, createdBy: UUID?) async {
        let newEvent = ClientEvent(
            id: UUID(),
            storeId: storeId,
            title: title,
            description: nil,
            type: type,
            date: date,
            endDate: nil,
            capacity: 50,
            location: venue,
            createdBy: createdBy ?? UUID(),
            createdAt: Date()
        )
        
        do {
            try await dataStore.createClientEvent(newEvent)
        } catch {
            print("Failed to create event: \(error)")
        }
    }
    
    // Update an event
    func updateEvent(_ event: ClientEvent, dataStore: DataStore) async {
        do {
            try await dataStore.updateClientEvent(event)
        } catch {
            print("Failed to update event: \(error)")
        }
    }
    
    // Delete an event
    func deleteEvent(id: UUID, dataStore: DataStore) async {
        do {
            try await dataStore.deleteClientEvent(id: id)
        } catch {
            print("Failed to delete event: \(error)")
        }
    }
    
    // Add guest to event
    func addGuest(to eventId: UUID, clientId: UUID, dataStore: DataStore) async {
        let inv = EventInvitation(
            id: UUID(),
            eventId: eventId,
            clientId: clientId,
            status: .invited,
            sentAt: Date(),
            respondedAt: nil,
            plusOne: false
        )
        
        do {
            try await dataStore.createEventInvitation(inv)
        } catch {
            print("Failed to invite guest: \(error)")
        }
    }
    
    // Update guest RSVP
    func updateGuestStatus(invitation: EventInvitation, newStatus: RSVPStatus, dataStore: DataStore) async {
        var updated = invitation
        // Note: EventInvitation's status is a 'let'. We must recreate it.
        let newInv = EventInvitation(
            id: invitation.id,
            eventId: invitation.eventId,
            clientId: invitation.clientId,
            status: newStatus,
            sentAt: invitation.sentAt,
            respondedAt: Date(),
            plusOne: invitation.plusOne
        )
        
        do {
            try await dataStore.updateEventInvitation(newInv)
        } catch {
            print("Failed to update status: \(error)")
        }
    }
    
}
