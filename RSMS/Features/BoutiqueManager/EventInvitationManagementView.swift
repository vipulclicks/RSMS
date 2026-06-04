//
//  EventInvitationManagementView.swift
//  RSMS
//
//  Boutique Manager workflow for event invitations and RSVP tracking.
//

import SwiftUI

struct EventInvitationManagementView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel = EventInvitationViewModel()
    @State private var showInviteSheet = false
    @State private var showCreateEventSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        if viewModel.isLoading {
                            ProgressView("Loading events...")
                                .frame(maxWidth: .infinity, minHeight: 220)
                        } else if viewModel.events.isEmpty {
                            emptyState
                        } else {
                            eventSelector
                            rsvpSummary
                            invitationList
                            attendeeList
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Client Events")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Event", systemImage: "calendar.badge.plus") {
                        showCreateEventSheet = true
                    }
                }
            }
            .sheet(isPresented: $showInviteSheet) {
                ClientInviteSheet(viewModel: viewModel, clients: appVM.dataStore.clients)
            }
            .sheet(isPresented: $showCreateEventSheet) {
                EventCreationSheet(viewModel: viewModel)
            }
            .alert("Event Invitations", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                guard let storeId = appVM.currentStoreId else { return }
                await viewModel.load(dataStore: appVM.dataStore, storeId: storeId)
            }
            .refreshable {
                guard let storeId = appVM.currentStoreId else { return }
                await viewModel.load(dataStore: appVM.dataStore, storeId: storeId)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Event Invitations")
                    .font(.title2.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Track invited clients, RSVP responses, and accepted attendees.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            Spacer()

            Button("Invite Clients", systemImage: "paperplane.fill") {
                showInviteSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(RSMSTheme.primaryDark)
            .disabled(viewModel.selectedEvent == nil)
        }
    }

    private var eventSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Events")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.events) { event in
                        Button {
                            viewModel.selectedEventId = event.id
                        } label: {
                            EventSelectionCard(event: event, isSelected: viewModel.selectedEvent?.id == event.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var rsvpSummary: some View {
        ViewThatFits {
            HStack(spacing: 12) {
                rsvpMetricCards
            }
            VStack(spacing: 12) {
                rsvpMetricCards
            }
        }
    }

    @ViewBuilder
    private var rsvpMetricCards: some View {
        RSVPMetricCard(title: "Accepted", value: viewModel.acceptedCount, color: RSMSTheme.success, icon: "checkmark.circle.fill")
        RSVPMetricCard(title: "Pending", value: viewModel.pendingCount, color: RSMSTheme.warning, icon: "clock.fill")
        RSVPMetricCard(title: "Declined", value: viewModel.declinedCount, color: RSMSTheme.danger, icon: "xmark.circle.fill")
    }

    private var invitationList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Invited Clients")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                Text("\(viewModel.selectedEventInvitations.count) total")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            if viewModel.selectedEventInvitations.isEmpty {
                EmptyPanel(title: "No invitations sent", subtitle: "Select Invite Clients to send this event to one or more clients.", icon: "person.crop.circle.badge.plus")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.selectedEventInvitations) { invitation in
                        InvitationRow(
                            invitation: invitation,
                            client: appVM.dataStore.client(by: invitation.clientId),
                            eventTitle: viewModel.selectedEvent?.title ?? "the event"
                        ) { status in
                            Task {
                                await viewModel.updateRSVP(invitation, status: status, dataStore: appVM.dataStore)
                            }
                        }
                    }
                }
            }
        }
    }

    private var attendeeList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accepted Attendees")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)

            if viewModel.acceptedInvitations.isEmpty {
                EmptyPanel(title: "No accepted RSVPs yet", subtitle: "Clients with Accepted responses will appear here.", icon: "person.2.slash")
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.acceptedInvitations) { invitation in
                        let client = appVM.dataStore.client(by: invitation.clientId)
                        HStack(spacing: 12) {
                            ClientInitialsView(name: client?.fullName ?? "Unknown Client")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client?.fullName ?? "Unknown Client")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text(client?.email ?? client?.phone ?? "No contact details")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(RSMSTheme.success)
                        }
                        .padding(14)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyPanel(title: "No client events", subtitle: "Create an event before sending invitations.", icon: "calendar.badge.plus")
            .frame(maxWidth: .infinity, minHeight: 260)
    }
}

private struct EventSelectionCard: View {
    let event: ClientEvent
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.primary)
                Text(event.type.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.textSecondary)
            }

            Text(event.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.textPrimary)
                .lineLimit(2)
                .frame(width: 190, alignment: .leading)

            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(isSelected ? RSMSTheme.cream.opacity(0.85) : RSMSTheme.textSecondary)
        }
        .padding(16)
        .frame(width: 230, alignment: .leading)
        .background(isSelected ? AnyShapeStyle(RSMSTheme.primaryGradient) : AnyShapeStyle(RSMSTheme.surfacePrimary))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1)
        )
    }
}

private struct RSVPMetricCard: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minWidth: 130, maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct InvitationRow: View {
    let invitation: EventInvitation
    let client: ClientProfile?
    let eventTitle: String
    let onStatusChange: (RSVPStatus) -> Void
    @State private var isSharePresented = false

    var body: some View {
        HStack(spacing: 12) {
            ClientInitialsView(name: client?.fullName ?? "Unknown Client")

            VStack(alignment: .leading, spacing: 4) {
                Text(client?.fullName ?? "Unknown Client")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(client?.email ?? client?.phone ?? "No contact details")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            Spacer()

            StatusBadge(text: invitation.status.displayName, color: invitation.status.color)

            Menu {
                Button("Share Invite Link", systemImage: "square.and.arrow.up") {
                    isSharePresented = true
                }
                Divider()
                Button("Accepted") { onStatusChange(.confirmed) }
                Button("Declined") { onStatusChange(.declined) }
                Button("Pending") { onStatusChange(.invited) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            .accessibilityLabel("Change RSVP status")
        }
        .padding(14)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $isSharePresented) {
            shareSheet
        }
    }
    
    private var shareSheet: some View {
        let acceptURL = "\(SupabaseConfig.projectURL)/functions/v1/rsvp?id=\(invitation.id)&status=confirmed"
        let declineURL = "\(SupabaseConfig.projectURL)/functions/v1/rsvp?id=\(invitation.id)&status=declined"
        
        let message = """
        You are cordially invited to \(eventTitle)!
        
        Please let us know if you can make it by clicking one of the links below:
        
        ✅ ACCEPT:
        \(acceptURL)
        
        ❌ DECLINE:
        \(declineURL)
        """
        
        return ActivityViewControllerRepresentable(activityItems: [message])
    }
}

private struct ClientInviteSheet: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    let viewModel: EventInvitationViewModel
    let clients: [ClientProfile]
    @State private var selectedClientIds: Set<UUID> = []

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section {
                    TextField("Search clients", text: $viewModel.searchText)
                        .textInputAutocapitalization(.words)
                }
                .listRowBackground(RSMSTheme.surfacePrimary)

                Section("Available Clients") {
                    ForEach(viewModel.uninvitedClients(from: clients)) { client in
                        Button {
                            toggle(client.id)
                        } label: {
                            HStack {
                                ClientInitialsView(name: client.fullName)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(client.fullName)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text(client.email ?? client.phone ?? "No contact details")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: selectedClientIds.contains(client.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedClientIds.contains(client.id) ? RSMSTheme.success : RSMSTheme.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(RSMSTheme.surfacePrimary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Invite Clients")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isSending ? "Sending..." : "Send") {
                        let selected = clients.filter { selectedClientIds.contains($0.id) }
                        Task {
                            await viewModel.sendInvitations(to: selected, dataStore: appVM.dataStore)
                            dismiss()
                        }
                    }
                    .disabled(selectedClientIds.isEmpty || viewModel.isSending)
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedClientIds.contains(id) {
            selectedClientIds.remove(id)
        } else {
            selectedClientIds.insert(id)
        }
    }
}

private struct EventCreationSheet: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    let viewModel: EventInvitationViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var type: ClientEventType = .vipPreview
    @State private var date = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var capacity = 25
    @State private var location = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                    Picker("Type", selection: $type) {
                        ForEach(ClientEventType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    DatePicker("Starts", selection: $date)
                    Toggle("Set end time", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Ends", selection: $endDate)
                    }
                    Stepper("Capacity: \(capacity)", value: $capacity, in: 1...500)
                    TextField("Location", text: $location)
                }
                .listRowBackground(RSMSTheme.surfacePrimary)
            }
            .scrollContentBackground(.hidden)
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard let storeId = appVM.currentStoreId, let userId = appVM.currentUser?.id else { return }
                        Task {
                            await viewModel.createEvent(
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                description: description.nilIfBlank,
                                type: type,
                                date: date,
                                endDate: hasEndDate ? endDate : nil,
                                capacity: capacity,
                                location: location.nilIfBlank,
                                storeId: storeId,
                                createdBy: userId,
                                dataStore: appVM.dataStore
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct EmptyPanel: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(title)
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ClientInitialsView: View {
    let name: String

    var body: some View {
        Text(initials)
            .font(.caption.weight(.bold))
            .foregroundStyle(RSMSTheme.primary)
            .frame(width: 38, height: 38)
            .background(RSMSTheme.primary.opacity(0.1))
            .clipShape(Circle())
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }
}

private extension ClientEventType {
    var displayName: String {
        switch self {
        case .trunkShow: return "Trunk Show"
        case .vipPreview: return "VIP Preview"
        case .launch: return "Launch"
        case .privateViewing: return "Private Viewing"
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

#Preview {
    EventInvitationManagementView()
        .environment(AppViewModel())
}
