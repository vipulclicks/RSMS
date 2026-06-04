//
//  AppointmentRemoteSellingView.swift
//  RSMS
//
//  Premium Apple-inspired appointment booking experience for luxury retail.
//  Fully responsive, supporting iPad multi-column overlay and iPhone bottom sheets.
//

import SwiftUI
import Combine

struct AppointmentRemoteSellingView: View {
    @Bindable var viewModel: AppointmentViewModel
    @Binding var navigationPath: NavigationPath
    @Binding var showNotifications: Bool
    @Environment(DataStore.self) private var dataStore
    @Environment(AppViewModel.self) private var appViewModel

    // Search and Filters
    @State private var searchText = ""
    @State private var selectedStatusFilter: AppointmentStatus? = nil
    @State private var showPastAppointments = false

    // Sheets Presentation
    @State private var showClientSelection = false
    @State private var showBookingForm = false
    @State private var appointmentToReschedule: Appointment? = nil
    @State private var appointmentToAddNotes: Appointment? = nil

    // State for scheduling / quick actions
    @State private var selectedClientForBooking: ClientProfile? = nil
    @State private var selectedAppointmentForAction: Appointment? = nil
    @State private var appointmentToDelete: Appointment? = nil
    @State private var showDeleteConfirmation = false
    @State private var consultationManager = VideoConsultationManager()

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                // Appointments List
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // SECTION 1: TODAY'S APPOINTMENTS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Schedule")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .padding(.horizontal, 24)
                            
                            if viewModel.todaysInStoreAppointments.isEmpty && viewModel.todaysVideoAppointments.isEmpty {
                                emptyStateCard(title: "No appointments today", message: "Enjoy your day or schedule a new consultation.")
                                    .padding(.horizontal, 24)
                            } else {
                                if !viewModel.todaysInStoreAppointments.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("In-Store")
                                            .font(.headline)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                            .padding(.horizontal, 24)
                                        
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340, maximum: 500), spacing: 20)], spacing: 20) {
                                            ForEach(viewModel.todaysInStoreAppointments) { appt in
                                                glassmorphicAppointmentCard(appt)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                                
                                if !viewModel.todaysVideoAppointments.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Video Consultations")
                                            .font(.headline)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                            .padding(.horizontal, 24)
                                        
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340, maximum: 500), spacing: 20)], spacing: 20) {
                                            ForEach(viewModel.todaysVideoAppointments) { appt in
                                                glassmorphicAppointmentCard(appt)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                        
                        Divider().padding(.horizontal, 24)
                        
                        // SECTION 2: OTHER APPOINTMENTS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Other Appointments")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .padding(.horizontal, 24)
                            
                            // Horizontal Filter Pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    filterPill(title: "Upcoming", isSelected: !showPastAppointments) {
                                        showPastAppointments = false
                                    }
                                    filterPill(title: "Past", isSelected: showPastAppointments) {
                                        showPastAppointments = true
                                    }
                                    
                                    Divider().frame(height: 20)

                                    filterPill(title: "All Statuses", isSelected: selectedStatusFilter == nil) {
                                        selectedStatusFilter = nil
                                    }
                                    let essentialStatuses: [AppointmentStatus] = [.scheduled, .completed, .cancelled]
                                    ForEach(essentialStatuses, id: \.self) { status in
                                        let title = status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
                                        filterPill(title: title, isSelected: selectedStatusFilter == status) {
                                            selectedStatusFilter = status
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            let otherAppts = viewModel.filteredOtherAppointments(statusFilter: selectedStatusFilter, searchText: searchText)
                            let timeFilteredAppts = showPastAppointments ? otherAppts.filter { $0.dateTime <= Date() } : otherAppts.filter { $0.dateTime > Date() }
                            
                            if timeFilteredAppts.isEmpty {
                                emptyStateCard(title: "No \(showPastAppointments ? "past" : "upcoming") appointments found", message: "Try adjusting your filters or search terms.")
                                    .padding(.horizontal, 24)
                            } else {
                                let inStore = timeFilteredAppts.filter { $0.type == .inStore }
                                let video = timeFilteredAppts.filter { $0.type == .video }
                                
                                if !inStore.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("In-Store")
                                            .font(.headline)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                            .padding(.horizontal, 24)
                                        
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340, maximum: 500), spacing: 20)], spacing: 20) {
                                            ForEach(inStore) { appt in
                                                glassmorphicAppointmentCard(appt)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                                
                                if !video.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Video Consultations")
                                            .font(.headline)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                            .padding(.horizontal, 24)
                                        
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340, maximum: 500), spacing: 20)], spacing: 20) {
                                            ForEach(video) { appt in
                                                glassmorphicAppointmentCard(appt)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .navigationTitle("Appointments")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search...")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                showClientSelection = true
                            } label: {
                                Image(systemName: "plus").accessibilityLabel("Add")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            
                            Button {
                                showNotifications = true
                            } label: {
                                let unreadCount = appViewModel.dataStore.appNotifications.filter { $0.recipientId == appViewModel.currentUser?.id && !$0.isRead }.count
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.primary)
                                    
                                    if unreadCount > 0 {
                                        Circle()
                                            .fill(RSMSTheme.danger)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                            }
                            
                            Button {
                                navigationPath.append("Profile")
                            } label: {
                                let initials = appViewModel.currentUser?.fullName.split(separator: " ").prefix(2)
                                    .compactMap { $0.first.map(String.init) }.joined().uppercased() ?? ""
                                ProfileAvatarView(avatarURL: appViewModel.currentUser?.avatarURL, initials: initials, size: 30)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showClientSelection) {
            clientSelectionSheet
        }
        .sheet(item: $selectedClientForBooking) { client in
            bookingFormSheet(client: client)
        }
        .sheet(item: $appointmentToReschedule) { appointment in
            rescheduleSheet(appointment: appointment)
        }
        .sheet(item: $appointmentToAddNotes) { appointment in
            addNotesSheet(appointment: appointment)
        }
        .fullScreenCover(isPresented: $consultationManager.showFaceTimeCompanion) {
            if let appointment = consultationManager.activeAppointment {
                FaceTimeVideoConsultationSheet(
                    appointment: appointment,
                    client: nil,
                    viewModel: viewModel,
                    consultationManager: consultationManager,
                    onDismiss: {
                        selectedAppointmentForAction = nil
                    }
                )
            }
        }
        .alert("FaceTime Error", isPresented: $consultationManager.showFaceTimeError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(consultationManager.errorMessage)
        }
        .task {
            await viewModel.processAutomaticReminders()
        }
        .alert("Cancel Appointment", isPresented: $showDeleteConfirmation, presenting: appointmentToDelete) { appointment in
            Button("Cancel Appointment", role: .destructive) {
                Task {
                    let updatedApp = Appointment(
                        id: appointment.id,
                        clientId: appointment.clientId,
                        associateId: appointment.associateId,
                        storeId: appointment.storeId,
                        dateTime: appointment.dateTime,
                        durationMinutes: appointment.durationMinutes,
                        type: appointment.type,
                        status: .cancelled,
                        reminderSentAt: appointment.reminderSentAt,
                        videoLink: appointment.videoLink,
                        notes: appointment.notes,
                        createdAt: appointment.createdAt,
                        reminderTimingHours: appointment.reminderTimingHours,
                        reminderChannel: appointment.reminderChannel,
                        reminderStatus: appointment.reminderStatus,
                        reminderError: appointment.reminderError
                    )
                    try? await viewModel.updateAppointment(updatedApp)
                }
            }
            Button("Keep Appointment", role: .cancel) {}
        } message: { appointment in
            Text("Are you sure you want to cancel this appointment? This action cannot be undone.")
        }
    }

    // MARK: - Dashboard Header removed in favor of native navigation title

    // MARK: - Search & Filters

    
    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? RSMSTheme.primary : RSMSTheme.surfacePrimary,
                    in: Capsule()
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Glassmorphic Card

    private func glassmorphicAppointmentCard(_ appointment: Appointment) -> some View {
        let statusColor = viewModel.statusColor(appointment.status)
        let client = dataStore.clients.first(where: { $0.id == appointment.clientId })

        return VStack(alignment: .leading, spacing: 0) {
            // Top Badge Row
            HStack(alignment: .top) {
                StatusBadge(
                    text: appointment.type == .video ? "VIDEO" : "IN-STORE",
                    color: appointment.type == .video ? RSMSTheme.primary : RSMSTheme.textSecondary
                )
                Spacer()
                StatusBadge(
                    text: appointment.status.rawValue.replacingOccurrences(of: "_", with: " ").uppercased(),
                    color: statusColor
                )
            }
            .padding(.bottom, 12)

            // Main Info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Text(clientInitials(for: client))
                        .font(.body.weight(.bold))
                        .foregroundStyle(RSMSTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(client?.fullName ?? "Unknown Client")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(appointment.dateTime.formatted(date: .abbreviated, time: .shortened))
                        Text("• \(appointment.durationMinutes)m")
                    }
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            .padding(.bottom, 12)
            
            // Truncated Notes Preview
            if let notes = appointment.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(2)
                    .padding(.bottom, 8)
            }
            
            Spacer(minLength: 0)

            Divider().overlay(RSMSTheme.divider).padding(.bottom, 12)

            // Bottom Actions Row
            HStack(spacing: 12) {
                if appointment.type == .video && (appointment.status == .scheduled || appointment.status == .confirmed || appointment.status == .inProgress) {
                    Button {
                        if appointment.status != .inProgress {
                            Task {
                                let updatedApp = Appointment(
                                    id: appointment.id, clientId: appointment.clientId, associateId: appointment.associateId, storeId: appointment.storeId, dateTime: appointment.dateTime, durationMinutes: appointment.durationMinutes, type: appointment.type, status: .inProgress, reminderSentAt: appointment.reminderSentAt, videoLink: appointment.videoLink, notes: appointment.notes, createdAt: appointment.createdAt, reminderTimingHours: appointment.reminderTimingHours, reminderChannel: appointment.reminderChannel, reminderStatus: appointment.reminderStatus, reminderError: appointment.reminderError
                                )
                                try? await viewModel.updateAppointment(updatedApp)
                            }
                        }
                        consultationManager.startVideoConsultation(for: appointment)
                    } label: {
                        Label(appointment.status == .inProgress ? "Join Call" : "Start Call", systemImage: "video.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.cream)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RSMSTheme.primaryGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                Spacer()

                Menu {
                    if let c = client {
                        Button {
                            navigationPath.append(c)
                        } label: {
                            Label("Client Profile", systemImage: "person.crop.circle")
                        }
                    }

                    Button {
                        appointmentToReschedule = appointment
                    } label: {
                        Label("Reschedule", systemImage: "calendar.badge.clock")
                    }

                    Button {
                        appointmentToAddNotes = appointment
                    } label: {
                        Label("Add Notes / Details", systemImage: "square.and.pencil")
                    }

                    Menu {
                        ForEach(AppointmentStatus.allCases, id: \.self) { status in
                            Button {
                                Task {
                                    let updatedApp = Appointment(
                                        id: appointment.id, clientId: appointment.clientId, associateId: appointment.associateId, storeId: appointment.storeId, dateTime: appointment.dateTime, durationMinutes: appointment.durationMinutes, type: appointment.type, status: status, reminderSentAt: appointment.reminderSentAt, videoLink: appointment.videoLink, notes: appointment.notes, createdAt: appointment.createdAt, reminderTimingHours: appointment.reminderTimingHours, reminderChannel: appointment.reminderChannel, reminderStatus: appointment.reminderStatus, reminderError: appointment.reminderError
                                    )
                                    try? await viewModel.updateAppointment(updatedApp)
                                }
                            } label: {
                                HStack {
                                    Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    if appointment.status == status { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Divider()

                    Button(role: .destructive) {
                        appointmentToDelete = appointment
                        showDeleteConfirmation = true
                    } label: {
                        Label("Cancel Appointment", systemImage: "trash")
                    }
                } label: {
                    Text("Options")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.primary.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding(16)
        .frame(minHeight: 220, alignment: .top)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }


    // MARK: - Search Existing Clients Sheet

    private var clientSelectionSheet: some View {
        ClientSearchPickerSheet(
            onCancel: { showClientSelection = false },
            onSelect: { client in
                showClientSelection = false
                // Wait briefly before launching the booking form to let the modal dismiss animation finish
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    selectedClientForBooking = client
                }
            }
        )
    }

    // MARK: - Create Booking Form Sheet

    private func bookingFormSheet(client: ClientProfile) -> some View {
        AppointmentBookingFormSheet(
            client: client,
            viewModel: viewModel,
            onDismiss: {
                selectedClientForBooking = nil
            }
        )
    }

    // MARK: - Reschedule Sheet

    private func rescheduleSheet(appointment: Appointment) -> some View {
        RescheduleAppointmentSheet(
            appointment: appointment,
            viewModel: viewModel,
            onDismiss: {
                appointmentToReschedule = nil
            }
        )
    }

    // MARK: - Add Notes Sheet

    private func addNotesSheet(appointment: Appointment) -> some View {
        AddNotesAppointmentSheet(
            appointment: appointment,
            viewModel: viewModel,
            onDismiss: {
                appointmentToAddNotes = nil
            }
        )
    }

    // MARK: - Helpers

    private func emptyStateCard(title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(title)
                .font(.headline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }

    private func clientInitials(for client: ClientProfile?) -> String {
        guard let name = client?.fullName else { return "C" }
        return name.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

// MARK: - Client Search & Picker Sheet

private struct ClientSearchPickerSheet: View {
    @Environment(DataStore.self) private var dataStore
    let onCancel: () -> Void
    let onSelect: (ClientProfile) -> Void

    @State private var searchQuery = ""

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        TextField("Search by name, email, phone...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    .padding(12)
                    .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    let filtered = dataStore.clients.filter { c in
                        searchQuery.isEmpty ||
                        c.fullName.localizedCaseInsensitiveContains(searchQuery) ||
                        (c.email?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                        (c.phone?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                        c.id.uuidString.localizedCaseInsensitiveContains(searchQuery)
                    }

                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.largeTitle)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text("No clients matched search")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(filtered) { client in
                                    Button {
                                        onSelect(client)
                                    } label: {
                                        clientSelectionCard(client)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private func clientSelectionCard(_ client: ClientProfile) -> some View {
        let initials = client.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()

        return HStack(spacing: 14) {
            // Initials Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.primary.opacity(0.12))
                    .frame(width: 50, height: 50)
                Text(initials)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(RSMSTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Name (No loyalty tiers!)
                Text(client.fullName)
                    .font(.body.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)

                // Pref categories
                if let cats = client.favoriteCategories, !cats.isEmpty {
                    Text(cats.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("No category preferences logged")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .lineLimit(1)
                }

                // Recent interaction indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text("Last active recently")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .padding(14)
        .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.border, lineWidth: 1))
    }
}

// MARK: - Appointment Booking Form Sheet

private struct AppointmentBookingFormSheet: View {
    let client: ClientProfile
    let viewModel: AppointmentViewModel
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel

    // Booking Fields
    @State private var appointmentType: AppointmentType = .inStore
    @State private var date = Date.now.addingTimeInterval(3600 * 24) // Tomorrow
    @State private var selectedTime = "10:00 AM"
    @State private var durationMinutes = 45
    @State private var notes = ""
    @State private var selectedOccasion = "Styling Consultation"
    @State private var tags: Set<String> = []

    // Video consultation specific fields
    @State private var videoLink = ""
    @State private var calendarSyncEnabled = true
    @State private var cameraChecking = false
    @State private var cameraOk = true
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    // FaceTime Integration Fields
    @State private var facetimeContact = ""
    @State private var facetimeLink = ""
    @State private var facetimeNotes = ""

    // Reminders Config
    @State private var reminderTimingHours = 24
    @State private var reminderChannel = "Email"

    private func isValidFaceTimeContact(_ contact: String) -> Bool {
        let trimmed = contact.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        
        if trimmed.contains("@") {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: trimmed)
        } else {
            // Basic phone verification: only permit numbers and some common symbols, min 5 chars
            let allowedCharacters = CharacterSet(charactersIn: "0123456789+-() ")
            return trimmed.unicodeScalars.allSatisfy { allowedCharacters.contains($0) } && trimmed.count >= 5
        }
    }

    private var currentStoreName: String {
        let storeId = appViewModel.currentUser?.storeId ?? viewModel.storeId
        if let store = viewModel.stores.first(where: { $0.id == storeId }) {
            return store.name
        }
        return viewModel.stores.first?.name ?? "Maison Lumière Vendôme"
    }

    var locations: [String] {
        viewModel.stores.map { $0.name }
    }
    @State private var selectedLocation = ""

    let availableTimes = ["09:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM", "01:00 PM", "02:00 PM", "03:00 PM", "04:30 PM"]
    let occasions = ["Styling Consultation", "VIP Consultation", "Birthday", "Anniversary", "Wedding", "Video Consultation"]
    let availableTags = ["Fine Watches", "High Jewellery", "Ready-to-Wear", "Leather Goods", "Perfumes"]

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Client Info Recap (No loyalty tier!)
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(RSMSTheme.primary.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Text(String(client.fullName.prefix(1)))
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.fullName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text(client.email ?? client.phone ?? "No contact logged")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 12))

                        // Type Selection
                        LuxuryFormCard(title: "Consultation Type", icon: "square.grid.2x2") {
                            Picker("Type", selection: $appointmentType) {
                                Text("In-Store Visit").tag(AppointmentType.inStore)
                                Text("Video Consultation").tag(AppointmentType.video)
                            }
                            .pickerStyle(.segmented)
                        }

                        // Date & Location
                        LuxuryFormCard(title: "Date & Location", icon: "calendar") {
                            DatePicker("Select Date", selection: $date, displayedComponents: .date)
                                .tint(RSMSTheme.primary)
                                .font(.subheadline)

                            // Time Slot Chips
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Available Time Slots")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textSecondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(availableTimes, id: \.self) { time in
                                            Button {
                                                selectedTime = time
                                            } label: {
                                                Text(time)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(selectedTime == time ? RSMSTheme.cream : RSMSTheme.textPrimary)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(selectedTime == time ? RSMSTheme.primaryGradient : LinearGradient(colors: [RSMSTheme.surfacePrimary], startPoint: .top, endPoint: .bottom), in: Capsule())
                                                    .overlay(Capsule().stroke(selectedTime == time ? RSMSTheme.primary : RSMSTheme.border, lineWidth: 1))
                                            }
                                        }
                                    }
                                }
                            }


                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assigned Specialist")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Text(appViewModel.currentUser?.fullName ?? "Antoine Laurent")
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(RSMSTheme.border, lineWidth: 1)
                                    )
                            }
                        }

                        // FaceTime Configuration Section (shows only if video is selected)
                        if appointmentType == .video {
                            LuxuryFormCard(title: "FaceTime Configuration", icon: "video.fill") {
                                // FaceTime Contact Input (Required)
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Text("FaceTime Contact (Email or Phone)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                        Text("*")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.danger)
                                    }

                                    TextField("e.g. client@email.com or +33 6 1234 5678", text: $facetimeContact)
                                        .font(.subheadline)
                                        .padding(12)
                                        .background(RSMSTheme.background)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(RSMSTheme.border, lineWidth: 1)
                                        )
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }

                                // FaceTime Meeting Link (Optional)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("FaceTime Meeting Link (Optional)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)

                                    HStack {
                                        TextField("https://facetime.apple.com/join/...", text: $facetimeLink)
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .keyboardType(.URL)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                        
                                        Spacer()
                                        
                                        Button {
                                            let uuidSuffix = String(UUID().uuidString.prefix(6)).lowercased()
                                            facetimeLink = "https://facetime.apple.com/join/lumiere-consult-\(uuidSuffix)"
                                        } label: {
                                            Text(facetimeLink.isEmpty ? "Generate" : "Regenerate")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(RSMSTheme.primary)
                                        }
                                    }
                                    .padding(12)
                                    .background(RSMSTheme.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(RSMSTheme.border, lineWidth: 1)
                                    )
                                }

                                // FaceTime Specific Notes/Instructions (Optional)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("FaceTime Notes / Instructions (Optional)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)

                                    TextField("e.g. Please join 5 mins before...", text: $facetimeNotes, axis: .vertical)
                                        .lineLimit(2...3)
                                        .font(.subheadline)
                                        .padding(12)
                                        .background(RSMSTheme.background)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(RSMSTheme.border, lineWidth: 1)
                                        )
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                }

                                Toggle("Add to Apple Calendar", isOn: $calendarSyncEnabled)
                                    .tint(RSMSTheme.primary)
                                    .font(.subheadline)
                            }
                        }

                        // Reminder settings card
                        LuxuryFormCard(title: "Appointment Reminders", icon: "bell.fill") {
                            if appViewModel.currentUser?.role == .salesAssociate || appViewModel.currentUser?.role == .boutiqueManager {
                                LuxuryPicker(
                                    title: "Reminder Timing",
                                    selection: Binding(
                                        get: { "\(reminderTimingHours) Hours Before" },
                                        set: { val in
                                            if let hr = Int(val.split(separator: " ").first ?? "") {
                                                reminderTimingHours = hr
                                            }
                                        }
                                    ),
                                    options: ["1 Hours Before", "24 Hours Before", "48 Hours Before"]
                                )

                                LuxuryPicker(
                                    title: "Preferred Channel",
                                    selection: $reminderChannel,
                                    options: ["Email", "SMS", "Both"]
                                )
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.shield")
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Text("Only authorized roles may manage reminder settings.")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                            }
                        }

                        // Client Preferences & Interests
                        LuxuryFormCard(title: "Preferences & Occasion", icon: "tag.fill") {
                            LuxuryPicker(title: "Special Occasion", selection: $selectedOccasion, options: occasions)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Product Interest Tags")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textSecondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(availableTags, id: \.self) { tag in
                                            let isSelected = tags.contains(tag)
                                            Button {
                                                if isSelected {
                                                    tags.remove(tag)
                                                } else {
                                                    tags.insert(tag)
                                                }
                                            } label: {
                                                Text(tag)
                                                    .font(.caption.weight(.medium))
                                                    .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.textPrimary)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(isSelected ? RSMSTheme.primaryGradient : LinearGradient(colors: [RSMSTheme.surfacePrimary], startPoint: .top, endPoint: .bottom), in: Capsule())
                                                    .overlay(Capsule().stroke(isSelected ? RSMSTheme.primary : RSMSTheme.border, lineWidth: 1))
                                            }
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Consultation Notes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                TextField("Enter consultation notes...", text: $notes, axis: .vertical)
                                    .lineLimit(3...5)
                                    .padding(10)
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                        }

                        // Save Button
                        Button {
                            Task {
                                // FaceTime Validation
                                if appointmentType == .video {
                                    let contactTrimmed = facetimeContact.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if contactTrimmed.isEmpty {
                                        errorMessage = "FaceTime Contact (Email or Phone) is required for video consultations."
                                        showErrorAlert = true
                                        return
                                    }
                                    if !isValidFaceTimeContact(contactTrimmed) {
                                        errorMessage = "Please enter a valid email address or phone number for the FaceTime Contact."
                                        showErrorAlert = true
                                        return
                                    }
                                }

                                // Combine notes with occasion and tags
                                var combinedNotes = "[Occasion: \(selectedOccasion)] "
                                if !tags.isEmpty {
                                    combinedNotes += "[Interests: \(tags.joined(separator: ", "))] "
                                }
                                combinedNotes += notes

                                // Construct appointment date with selected time slot
                                let calendar = Calendar.current
                                var components = calendar.dateComponents([.year, .month, .day], from: date)
                                // Parse selectedTime e.g., "10:00 AM" or "02:00 PM"
                                let parts = selectedTime.split(separator: " ")
                                if parts.count == 2 {
                                    let timeParts = parts[0].split(separator: ":")
                                    if timeParts.count == 2, let hr = Int(timeParts[0]), let min = Int(timeParts[1]) {
                                        var finalHr = hr
                                        if parts[1] == "PM" && finalHr < 12 { finalHr += 12 }
                                        if parts[1] == "AM" && finalHr == 12 { finalHr = 0 }
                                        components.hour = finalHr
                                        components.minute = min
                                    }
                                }

                                let finalDate = calendar.date(from: components) ?? date
                                let associateId = appViewModel.currentUser?.id ?? viewModel.associateId
                                let profileStoreId = appViewModel.currentUser?.storeId ?? viewModel.storeId
                                 // 1. Logging setup
                                 print("[RSMS Debug] Attempting to schedule appointment:")
                                 print("[RSMS Debug]   - Fetching Associate ID: \(associateId)")
                                 print("[RSMS Debug]   - Selected Location Name: \(selectedLocation)")
                                 print("[RSMS Debug]   - Associate Store ID from Profile: \(profileStoreId)")
                                 print("[RSMS Debug]   - Valid stores found in DB: \(viewModel.stores.map { "\($0.name) (ID: \($0.id))" })")

                                 // 2. Validate and retrieve store_id based on selection or profile
                                 var storeIdToUse: UUID? = nil
                                 if let selectedStore = viewModel.stores.first(where: { $0.name == selectedLocation }) {
                                     storeIdToUse = selectedStore.id
                                 } else if viewModel.stores.contains(where: { $0.id == profileStoreId }) {
                                     storeIdToUse = profileStoreId
                                 } else if let fallbackStore = viewModel.stores.first {
                                     // Prevent insert failure by falling back to a valid store ID
                                     storeIdToUse = fallbackStore.id
                                     print("[RSMS Debug]   - Warning: Selected location/profile store not found in stores table. Falling back to valid Store ID: \(fallbackStore.id)")
                                 }

                                 guard let finalStoreId = storeIdToUse else {
                                     print("[RSMS Debug]   - Error: Validation failed. No valid stores exist in the database.")
                                     self.errorMessage = "Unable to schedule appointment. Store information is missing or invalid."
                                     self.showErrorAlert = true
                                     return
                                 }

                                var videoLinkPayload: String? = nil
                                if appointmentType == .video {
                                    let config = FaceTimeConfig(
                                        contact: facetimeContact.trimmingCharacters(in: .whitespacesAndNewlines),
                                        meetingLink: facetimeLink.isEmpty ? nil : facetimeLink.trimmingCharacters(in: .whitespacesAndNewlines),
                                        notes: facetimeNotes.isEmpty ? nil : facetimeNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                                    )
                                    if let encodedData = try? JSONEncoder().encode(config),
                                       let jsonString = String(data: encodedData, encoding: .utf8) {
                                        videoLinkPayload = jsonString
                                    }
                                }

                                let newApp = Appointment(
                                    id: UUID(),
                                    clientId: client.id,
                                    associateId: associateId,
                                    storeId: finalStoreId,
                                    dateTime: finalDate,
                                    durationMinutes: durationMinutes,
                                    type: appointmentType,
                                    status: .scheduled,
                                    reminderSentAt: nil,
                                    videoLink: videoLinkPayload,
                                    notes: combinedNotes,
                                    createdAt: Date(),
                                    reminderTimingHours: reminderTimingHours,
                                    reminderChannel: reminderChannel,
                                    reminderStatus: "Pending",
                                    reminderError: nil
                                )

                                print("[RSMS Debug]   - Appointment payload to insert: \(newApp)")

                                do {
                                    try await viewModel.createAppointment(newApp)
                                    print("[RSMS Debug] Supabase insert success")
                                    dismiss()
                                    onDismiss()
                                } catch {
                                    print("[RSMS Debug] Supabase insert error: \(error.localizedDescription)")
                                    self.errorMessage = "Unable to schedule appointment. Store information is missing or invalid."
                                    self.showErrorAlert = true
                                }
                            }
                        } label: {
                            Text("Schedule Consultation")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.cream)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RSMSTheme.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 12, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
            .alert("Booking Error", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { msg in
                Text(msg)
            }
            .onAppear {
                if let currentStoreId = appViewModel.currentUser?.storeId,
                   let currentStore = viewModel.stores.first(where: { $0.id == currentStoreId }) {
                    selectedLocation = currentStore.name
                } else if let firstStore = viewModel.stores.first {
                    selectedLocation = firstStore.name
                }
            }
        }
    }
}

// MARK: - Reschedule Appointment Sheet

private struct RescheduleAppointmentSheet: View {
    let appointment: Appointment
    let viewModel: AppointmentViewModel
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @State private var date = Date.now
    @State private var rescheduleTime = Date.now
    @State private var reminderTimingHours = 24
    @State private var reminderChannel = "Email"

    // FaceTime Integration Fields
    @State private var facetimeContact = ""
    @State private var facetimeLink = ""
    @State private var facetimeNotes = ""
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    private func isValidFaceTimeContact(_ contact: String) -> Bool {
        let trimmed = contact.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        
        if trimmed.contains("@") {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: trimmed)
        } else {
            // Basic phone verification: only permit numbers and some common symbols, min 5 chars
            let allowedCharacters = CharacterSet(charactersIn: "0123456789+-() ")
            return trimmed.unicodeScalars.allSatisfy { allowedCharacters.contains($0) } && trimmed.count >= 5
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        LuxuryFormCard(title: "Select New Date", icon: "calendar") {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .tint(RSMSTheme.primary)
                                .font(.subheadline)
                        }
                        
                        LuxuryFormCard(title: "Choose Time", icon: "alarm") {
                            DatePicker(
                                "Time",
                                selection: $rescheduleTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // FaceTime Configuration Section (shows only if video type)
                        if appointment.type == .video {
                            LuxuryFormCard(title: "FaceTime Configuration", icon: "video.fill") {
                                // FaceTime Contact Input (Required)
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Text("FaceTime Contact (Email or Phone)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                        Text("*")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.danger)
                                    }

                                    TextField("e.g. client@email.com or +33 6 1234 5678", text: $facetimeContact)
                                        .font(.subheadline)
                                        .padding(12)
                                        .background(RSMSTheme.background)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(RSMSTheme.border, lineWidth: 1)
                                        )
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }

                                // FaceTime Meeting Link (Optional)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("FaceTime Meeting Link (Optional)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)

                                    HStack {
                                        TextField("https://facetime.apple.com/join/...", text: $facetimeLink)
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .keyboardType(.URL)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                        
                                        Spacer()
                                        
                                        Button {
                                            let uuidSuffix = String(UUID().uuidString.prefix(6)).lowercased()
                                            facetimeLink = "https://facetime.apple.com/join/lumiere-consult-\(uuidSuffix)"
                                        } label: {
                                            Text(facetimeLink.isEmpty ? "Generate" : "Regenerate")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(RSMSTheme.primary)
                                        }
                                    }
                                    .padding(12)
                                    .background(RSMSTheme.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(RSMSTheme.border, lineWidth: 1)
                                    )
                                }

                                // FaceTime Specific Notes/Instructions (Optional)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("FaceTime Notes / Instructions (Optional)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)

                                    TextField("e.g. Please join 5 mins before...", text: $facetimeNotes, axis: .vertical)
                                        .lineLimit(2...3)
                                        .font(.subheadline)
                                        .padding(12)
                                        .background(RSMSTheme.background)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(RSMSTheme.border, lineWidth: 1)
                                        )
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                }
                            }
                        }

                        LuxuryFormCard(title: "Appointment Reminders", icon: "bell.fill") {
                            if appViewModel.currentUser?.role == .salesAssociate || appViewModel.currentUser?.role == .boutiqueManager {
                                LuxuryPicker(
                                    title: "Reminder Timing",
                                    selection: Binding(
                                        get: { "\(reminderTimingHours) Hours Before" },
                                        set: { val in
                                            if let hr = Int(val.split(separator: " ").first ?? "") {
                                                reminderTimingHours = hr
                                            }
                                        }
                                    ),
                                    options: ["1 Hours Before", "24 Hours Before", "48 Hours Before"]
                                )

                                LuxuryPicker(
                                    title: "Preferred Channel",
                                    selection: $reminderChannel,
                                    options: ["Email", "SMS", "Both"]
                                )
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.shield")
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Text("Only authorized roles may manage reminder settings.")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                VStack {
                    Spacer()
                    
                    Button {
                        Task {
                            if appointment.type == .video {
                                let contactTrimmed = facetimeContact.trimmingCharacters(in: .whitespacesAndNewlines)
                                if contactTrimmed.isEmpty {
                                    errorMessage = "FaceTime Contact (Email or Phone) is required for video consultations."
                                    showErrorAlert = true
                                    return
                                }
                                if !isValidFaceTimeContact(contactTrimmed) {
                                    errorMessage = "Please enter a valid email address or phone number for the FaceTime Contact."
                                    showErrorAlert = true
                                    return
                                }
                            }

                            let calendar = Calendar.current
                            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                            let timeComponents = calendar.dateComponents([.hour, .minute], from: rescheduleTime)
                            
                            var mergedComponents = DateComponents()
                            mergedComponents.year = dateComponents.year
                            mergedComponents.month = dateComponents.month
                            mergedComponents.day = dateComponents.day
                            mergedComponents.hour = timeComponents.hour
                            mergedComponents.minute = timeComponents.minute

                            let finalDate = calendar.date(from: mergedComponents) ?? date

                            var videoLinkPayload = appointment.videoLink
                            if appointment.type == .video {
                                let config = FaceTimeConfig(
                                    contact: facetimeContact.trimmingCharacters(in: .whitespacesAndNewlines),
                                    meetingLink: facetimeLink.isEmpty ? nil : facetimeLink.trimmingCharacters(in: .whitespacesAndNewlines),
                                    notes: facetimeNotes.isEmpty ? nil : facetimeNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                                if let encodedData = try? JSONEncoder().encode(config),
                                   let jsonString = String(data: encodedData, encoding: .utf8) {
                                    videoLinkPayload = jsonString
                                }
                            }

                            let updated = Appointment(
                                id: appointment.id,
                                clientId: appointment.clientId,
                                associateId: appointment.associateId,
                                storeId: appointment.storeId,
                                dateTime: finalDate,
                                durationMinutes: appointment.durationMinutes,
                                type: appointment.type,
                                status: .confirmed,
                                reminderSentAt: nil,
                                videoLink: videoLinkPayload,
                                notes: appointment.notes,
                                createdAt: appointment.createdAt,
                                reminderTimingHours: reminderTimingHours,
                                reminderChannel: reminderChannel,
                                reminderStatus: "Pending",
                                reminderError: nil
                            )

                            try? await viewModel.updateAppointment(updated)
                            dismiss()
                            onDismiss()
                        }
                    } label: {
                        Text("Confirm Reschedule")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reschedule Error", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { msg in
                Text(msg)
            }
            .onAppear {
                date = appointment.dateTime
                rescheduleTime = appointment.dateTime
                reminderTimingHours = appointment.reminderTimingHours
                reminderChannel = appointment.reminderChannel
                
                if let config = appointment.decodedFaceTimeConfig {
                    facetimeContact = config.contact
                    facetimeLink = config.meetingLink ?? ""
                    facetimeNotes = config.notes ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Notes Appointment Sheet

private struct AddNotesAppointmentSheet: View {
    let appointment: Appointment
    let viewModel: AppointmentViewModel
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newNotes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    LuxuryFormCard(title: "Add Consultation Note", icon: "square.and.pencil") {
                        TextEditor(text: $newNotes)
                            .frame(minHeight: 140)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(RSMSTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer()

                    Button {
                        Task {
                            let oldNotes = appointment.notes ?? ""
                            let prefix = oldNotes.isEmpty ? "" : "\(oldNotes)\n— Update (\(Date().formatted(date: .abbreviated, time: .shortened))): "
                            let updatedNotes = prefix + newNotes

                            let updated = Appointment(
                                id: appointment.id,
                                clientId: appointment.clientId,
                                associateId: appointment.associateId,
                                storeId: appointment.storeId,
                                dateTime: appointment.dateTime,
                                durationMinutes: appointment.durationMinutes,
                                type: appointment.type,
                                status: appointment.status,
                                reminderSentAt: appointment.reminderSentAt,
                                videoLink: appointment.videoLink,
                                notes: updatedNotes,
                                createdAt: appointment.createdAt,
                                reminderTimingHours: appointment.reminderTimingHours,
                                reminderChannel: appointment.reminderChannel,
                                reminderStatus: appointment.reminderStatus,
                                reminderError: appointment.reminderError
                            )

                            try? await viewModel.updateAppointment(updated)
                            dismiss()
                            onDismiss()
                        }
                    } label: {
                        Text("Save Note")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }
}
