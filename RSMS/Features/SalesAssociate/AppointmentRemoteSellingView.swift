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
    @Environment(DataStore.self) private var dataStore

    // Search and Filters
    @State private var searchText = ""
    @State private var selectedStatusFilter: AppointmentStatus? = nil

    // Sheets Presentation
    @State private var showClientSelection = false
    @State private var showBookingForm = false
    @State private var appointmentToReschedule: Appointment? = nil
    @State private var appointmentToAddNotes: Appointment? = nil
    @State private var showVideoCall = false

    // State for scheduling / quick actions
    @State private var selectedClientForBooking: ClientProfile? = nil
    @State private var selectedAppointmentForAction: Appointment? = nil

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Dashboard Header
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Search & Filter Row
                searchAndFilterBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // Appointments List
                ScrollView {
                    let filtered = viewModel.appointments.filter { appointment in
                        let nameMatch = viewModel.clientName(for: appointment.clientId).localizedCaseInsensitiveContains(searchText) || searchText.isEmpty
                        let statusMatch = selectedStatusFilter == nil || appointment.status == selectedStatusFilter
                        return nameMatch && statusMatch
                    }

                    if filtered.isEmpty {
                        emptyStateView
                            .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340, maximum: 500), spacing: 20)], spacing: 20) {
                            ForEach(filtered) { appointment in
                                glassmorphicAppointmentCard(appointment)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.background, for: .navigationBar)
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
        .fullScreenCover(isPresented: $showVideoCall) {
            if let appointment = selectedAppointmentForAction {
                videoCallSheet(appointment: appointment)
            }
        }
    }

    // MARK: - Dashboard Header

    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Appointments")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Schedule and manage client consultations")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            Spacer()

            Button {
                showClientSelection = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                    Text("New Appointment")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(RSMSTheme.cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RSMSTheme.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: RSMSTheme.primary.opacity(0.25), radius: 10, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Search & Filters

    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(RSMSTheme.textTertiary)
                TextField("Search appointments by client...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding(10)
            .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))

            // Filter menu
            Menu {
                Button("All Statuses") { selectedStatusFilter = nil }
                ForEach(AppointmentStatus.allCases, id: \.self) { status in
                    Button(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) {
                        selectedStatusFilter = status
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(selectedStatusFilter == nil ? "Filter" : selectedStatusFilter!.rawValue.capitalized)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
            }
        }
    }

    // MARK: - Glassmorphic Card

    private func glassmorphicAppointmentCard(_ appointment: Appointment) -> some View {
        let statusColor = viewModel.statusColor(appointment.status)
        let client = dataStore.clients.first(where: { $0.id == appointment.clientId })

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                // Client initials & info
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(RSMSTheme.primary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Text(clientInitials(for: client))
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundStyle(RSMSTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(client?.fullName ?? "Unknown Client")
                            .font(.system(size: 17, weight: .semibold, design: .serif))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text(appointment.type == .video ? "Video Consultation" : "In-Store Consultation")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
                Spacer()

                // Status Badge
                StatusBadge(
                    text: appointment.status.rawValue.replacingOccurrences(of: "_", with: " ").uppercased(),
                    color: statusColor
                )
            }

            Divider().overlay(RSMSTheme.divider)

            // Date, Time, Duration
            HStack(spacing: 16) {
                Label {
                    Text(appointment.dateTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(RSMSTheme.primary)
                }

                Label {
                    Text("\(appointment.durationMinutes) min")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } icon: {
                    Image(systemName: "clock")
                        .foregroundStyle(RSMSTheme.primary)
                }
            }

            if let notes = appointment.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }

            // Quick Actions Footer
            HStack(spacing: 12) {
                if appointment.type == .video && (appointment.status == .scheduled || appointment.status == .confirmed) {
                    Button {
                        selectedAppointmentForAction = appointment
                        showVideoCall = true
                    } label: {
                        Label("Start Call", systemImage: "video.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.cream)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RSMSTheme.primaryGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                Button {
                    appointmentToReschedule = appointment
                } label: {
                    Text("Reschedule")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.surfacePrimary, in: Capsule())
                        .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                }

                Button {
                    if let c = client {
                        navigationPath.append(c)
                    }
                } label: {
                    Text("Profile")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.surfacePrimary, in: Capsule())
                        .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                }

                Spacer()

                Button {
                    appointmentToAddNotes = appointment
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
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

    // MARK: - Video Call Simulation Sheet

    private func videoCallSheet(appointment: Appointment) -> some View {
        SimulatedVideoConsultationSheet(
            appointment: appointment,
            viewModel: viewModel,
            onDismiss: {
                showVideoCall = false
                selectedAppointmentForAction = nil
            }
        )
    }

    // MARK: - Helpers

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 54))
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("No appointments found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Text("Try clearing your filters or create a new consultation appointment.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
                                .font(.system(size: 44))
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
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(RSMSTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Name (No loyalty tiers!)
                Text(client.fullName)
                    .font(.system(size: 16, weight: .bold, design: .serif))
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
    @State private var reminderEnabled = true
    @State private var calendarSyncEnabled = true
    @State private var cameraChecking = false
    @State private var cameraOk = true
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

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
                                    .font(.system(size: 16, weight: .bold, design: .serif))
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.fullName)
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
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

                            LuxuryPicker(title: "Boutique Location", selection: $selectedLocation, options: locations)

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

                        // Video Consultation Flow Card (shows only if video is selected)
                        if appointmentType == .video {
                            LuxuryFormCard(title: "Video Consultation Setup", icon: "video.fill") {
                                // Camera preview
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Camera Readiness Indicator")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)

                                    HStack {
                                        // Simulated Camera Preview
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(LinearGradient(colors: [Color.black.opacity(0.85), Color.black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                                                .frame(width: 100, height: 60)
                                            Image(systemName: "camera.fill")
                                                .foregroundStyle(Color.white.opacity(0.3))
                                                .font(.title2)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(cameraOk ? RSMSTheme.success : RSMSTheme.warning)
                                                    .frame(width: 8, height: 8)
                                                Text("FaceTime HD Camera")
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(RSMSTheme.textPrimary)
                                            }
                                            Text(cameraOk ? "Ready & Optimized" : "Checking camera...")
                                                .font(.caption2)
                                                .foregroundStyle(RSMSTheme.textSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(RSMSTheme.background, in: RoundedRectangle(cornerRadius: 12))
                                }

                                // Link generator
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Meeting Link")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)

                                    HStack {
                                        TextField("No link generated", text: $videoLink)
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .disabled(true)
                                        Spacer()
                                        Button {
                                            let uuidSuffix = String(UUID().uuidString.prefix(6)).lowercased()
                                            videoLink = "https://meet.lumiere.com/consult-\(uuidSuffix)"
                                        } label: {
                                            Text(videoLink.isEmpty ? "Generate" : "Regenerate")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(RSMSTheme.primary)
                                        }
                                    }
                                    .padding(10)
                                    .background(RSMSTheme.background, in: RoundedRectangle(cornerRadius: 8))
                                }

                                Toggle("Send Calendar Reminder Sync", isOn: $reminderEnabled)
                                    .tint(RSMSTheme.primary)
                                    .font(.subheadline)
                                Toggle("Add to Apple Calendar", isOn: $calendarSyncEnabled)
                                    .tint(RSMSTheme.primary)
                                    .font(.subheadline)
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

                                let newApp = Appointment(
                                    id: UUID(),
                                    clientId: client.id,
                                    associateId: associateId,
                                    storeId: finalStoreId,
                                    dateTime: finalDate,
                                    durationMinutes: durationMinutes,
                                    type: appointmentType,
                                    status: .scheduled,
                                    reminderSentAt: reminderEnabled ? Date() : nil,
                                    videoLink: appointmentType == .video ? videoLink : nil,
                                    notes: combinedNotes,
                                    createdAt: Date()
                                )

                                print("[RSMS Debug]   - Appointment payload to insert: \(newApp)")

                                do {
                                    let result = try await viewModel.createAppointment(newApp)
                                    print("[RSMS Debug] Supabase insert response: \(result)")
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
    @State private var date = Date.now
    @State private var rescheduleTime = Date.now

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
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                VStack {
                    Spacer()
                    
                    Button {
                        Task {
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

                            let updated = Appointment(
                                id: appointment.id,
                                clientId: appointment.clientId,
                                associateId: appointment.associateId,
                                storeId: appointment.storeId,
                                dateTime: finalDate,
                                durationMinutes: appointment.durationMinutes,
                                type: appointment.type,
                                status: .confirmed,
                                reminderSentAt: Date(),
                                videoLink: appointment.videoLink,
                                notes: appointment.notes,
                                createdAt: appointment.createdAt
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
            .onAppear {
                self.date = appointment.dateTime
                self.rescheduleTime = appointment.dateTime
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
                            .frame(height: 140)
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
                                createdAt: appointment.createdAt
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

// MARK: - Simulated Video Consultation Sheet

private struct SimulatedVideoConsultationSheet: View {
    let appointment: Appointment
    let viewModel: AppointmentViewModel
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isMuted = false
    @State private var cameraOff = false
    @State private var callDurationSeconds = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var formattedDuration: String {
        let mins = callDurationSeconds / 60
        let secs = callDurationSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        ZStack {
            // Live Simulated Luxury Video Feed (Warm Boutique Atmosphere)
            LinearGradient(
                colors: [Color(red: 28/255, green: 22/255, blue: 18/255), Color(red: 54/255, green: 40/255, blue: 34/255)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle Background Details representing a boutique setup
            VStack {
                Spacer()
                Circle()
                    .fill(Color(red: 201/255, green: 168/255, blue: 110/255).opacity(0.12))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
            }

            VStack(spacing: 24) {
                // Header (Consultation Details)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.clientName(for: appointment.clientId))
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                        Text("Live Luxury Styling Consultation")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()

                    // Call Timer
                    Text(formattedDuration)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15), in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Client Video Feed & Product Spotlight (Split View)
                HStack(spacing: 20) {
                    // Left Column: Client feed or simulated camera state
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1.5))

                        if cameraOff {
                            VStack(spacing: 12) {
                                Image(systemName: "video.slash.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white.opacity(0.4))
                                Text("Camera Off")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        } else {
                            VStack {
                                Spacer()
                                Text("Your Video (Boutique Camera)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .padding(.bottom, 12)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)

                    // Right Column: Simulated client camera feed
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1.5))

                        VStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(16)
                                .background(Color.white.opacity(0.05), in: Circle())
                            Text(viewModel.clientName(for: appointment.clientId))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Connected")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.success)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Call Controls
                HStack(spacing: 24) {
                    // Mute Button
                    Button {
                        isMuted.toggle()
                    } label: {
                        Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundStyle(isMuted ? .white : RSMSTheme.textPrimary)
                            .frame(width: 60, height: 60)
                            .background(isMuted ? Color.red : Color.white, in: Circle())
                    }

                    // End Call
                    Button {
                        dismiss()
                        onDismiss()
                    } label: {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 74, height: 74)
                            .background(Color.red, in: Circle())
                            .shadow(color: Color.red.opacity(0.3), radius: 10, y: 5)
                    }

                    // Camera Toggle
                    Button {
                        cameraOff.toggle()
                    } label: {
                        Image(systemName: cameraOff ? "video.slash.fill" : "video.fill")
                            .font(.title2)
                            .foregroundStyle(cameraOff ? .white : RSMSTheme.textPrimary)
                            .frame(width: 60, height: 60)
                            .background(cameraOff ? Color.red : Color.white, in: Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onReceive(timer) { _ in
            callDurationSeconds += 1
        }
    }
}

