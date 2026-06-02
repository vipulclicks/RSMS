import SwiftUI

struct EventDetailView: View {
    let event: ClientEvent
    @Bindable var viewModel: BoutiqueEventsViewModel
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddGuestModal = false
    @State private var showingEditModal = false
    @State private var showingDeleteAlert = false
    
    // Derived to stay updated with view model changes
    var currentEvent: ClientEvent {
        viewModel.events(from: appVM.dataStore).first(where: { $0.id == event.id }) ?? event
    }
    
    var invitations: [EventInvitation] {
        viewModel.invitations(for: currentEvent.id, from: appVM.dataStore)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                eventHeroSection
                
                rsvpTrackerSection
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 32)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle(currentEvent.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditModal = true
                    } label: {
                        Label("Edit Event", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Event", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddGuestModal) {
            AddGuestFormView(eventId: currentEvent.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditModal) {
            EditEventFormView(event: currentEvent, viewModel: viewModel)
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteEvent(id: currentEvent.id, dataStore: appVM.dataStore)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .task {
            await viewModel.fetchInvitations(for: currentEvent.id, dataStore: appVM.dataStore)
            // Ensure clients are loaded to resolve guest names
            if appVM.dataStore.clients.isEmpty {
                try? await appVM.dataStore.fetchClients()
            }
        }
    }
    
    private var eventHeroSection: some View {
        let attendingCount = invitations.filter { $0.status == .confirmed || $0.status == .attended }.count
        let pendingCount = invitations.filter { $0.status == .invited || $0.status == .pending }.count
        
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 16) {
                Text(currentEvent.type.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.cream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if currentEvent.type == .trunkShow {
                                LinearGradient(colors: [RSMSTheme.primaryDark, RSMSTheme.primaryDark.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            } else {
                                LinearGradient(colors: [RSMSTheme.gold, RSMSTheme.gold.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            }
                        }
                    )
                    .clipShape(Capsule())
                
                Text(currentEvent.title)
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                HStack(spacing: 24) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.gold)
                        Text(currentEvent.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.gold)
                        Text(currentEvent.location ?? "TBA")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(attendingCount)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.success)
                    Text("Attending")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                VStack(spacing: 4) {
                    Text("\(pendingCount)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.warning)
                    Text("Pending")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
        )
    }
    
    private var rsvpTrackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "RSVP Tracker", subtitle: "Manage guest invitations and attendance")
                Spacer()
                Button {
                    showingAddGuestModal = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text("Add Guest")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.primaryDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.primaryDark.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            if invitations.isEmpty {
                ContentUnavailableView("No Guests Invited", systemImage: "envelope.badge", description: Text("Start building your VIP list by adding guests."))
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(invitations) { guest in
                        guestRow(guest)
                        if guest.id != invitations.last?.id {
                            Divider()
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(RSMSTheme.surfacePrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
            }
        }
    }
    
    private func guestRow(_ guest: EventInvitation) -> some View {
        let client = appVM.dataStore.clients.first { $0.id == guest.clientId }
        let clientName = client?.fullName ?? "VIP Guest"
        
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.surfaceSecondary)
                    .frame(width: 44, height: 44)
                Text(String(clientName.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.primaryDark)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(clientName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(client?.email ?? "No email")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            
            Spacer()
            
            Menu {
                ForEach([RSVPStatus.invited, RSVPStatus.pending, RSVPStatus.confirmed, RSVPStatus.declined], id: \.self) { status in
                    Button {
                        Task {
                            await viewModel.updateGuestStatus(invitation: guest, newStatus: status, dataStore: appVM.dataStore)
                        }
                    } label: {
                        HStack {
                            Text(status.rawValue.capitalized)
                            if guest.status == status {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor(for: guest.status))
                        .frame(width: 8, height: 8)
                    
                    Text(guest.status.rawValue.capitalized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor(for: guest.status))
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor(for: guest.status).opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private func statusColor(for status: RSVPStatus) -> Color {
        switch status {
        case .invited, .pending: return RSMSTheme.warning
        case .confirmed, .attended: return RSMSTheme.success
        case .declined, .noShow: return RSMSTheme.danger
        }
    }
}
