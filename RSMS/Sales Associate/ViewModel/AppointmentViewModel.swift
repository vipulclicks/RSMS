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
            try await dataStore.fetchSalesGoals(storeId: storeId)
            try await dataStore.fetchStaffShifts(storeId: storeId)
            try await dataStore.fetchTransactions(storeId: storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var todaySalesFormatted: String {
        let todaySales = dataStore.transactions
            .filter {
                $0.associateId == associateId &&
                $0.status == .completed &&
                Calendar.current.isDateInToday($0.createdAt)
            }
            .reduce(0) { $0 + $1.totalAmount }
        
        return "₹\(Int(todaySales).formatted())"
    }

    var todaysAppointmentsCount: String {
        let count = appointments
            .filter { Calendar.current.isDateInToday($0.dateTime) }
            .count
        return String(count)
    }

    var clientsServedTodayCount: String {
        let completedTodayAppointments = appointments
            .filter { Calendar.current.isDateInToday($0.dateTime) && $0.status == .completed }
        
        let completedTodaySales = dataStore.transactions
            .filter {
                $0.associateId == associateId &&
                $0.status == .completed &&
                Calendar.current.isDateInToday($0.createdAt)
            }
        
        // Use a set of client IDs to get unique clients served, then count
        var servedClientIds = Set<UUID>()
        completedTodayAppointments.forEach { servedClientIds.insert($0.clientId) }
        completedTodaySales.compactMap { $0.clientId }.forEach { servedClientIds.insert($0) }
        
        return String(servedClientIds.count)
    }

    var nextAppointmentDisplay: String {
        let now = Date()
        let nextAppt = appointments
            .filter {
                $0.dateTime > now &&
                ($0.status == .scheduled || $0.status == .confirmed)
            }
            .sorted { $0.dateTime < $1.dateTime }
            .first
        
        if let appt = nextAppt {
            let name = clientName(for: appt.clientId).components(separatedBy: " ").first ?? "Client"
            if Calendar.current.isDateInToday(appt.dateTime) {
                let timeStr = RSMSDateFormatter.timeOnly.string(from: appt.dateTime)
                return "\(timeStr) • \(name)"
            } else {
                let df = DateFormatter()
                df.dateFormat = "MMM d"
                return "\(df.string(from: appt.dateTime)) • \(name)"
            }
        }
        return "None Scheduled"
    }

    // MARK: - Stores
    var stores: [Store] { dataStore.stores }

    // MARK: - Appointments
    var appointments: [Appointment] { dataStore.appointments.filter { $0.associateId == associateId } }

    var upcomingAppointments: [Appointment] {
        appointments
            .filter {
                Calendar.current.isDateInToday($0.dateTime) &&
                ($0.status == .scheduled || $0.status == .confirmed || $0.status == .inProgress)
            }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var todaysInStoreAppointments: [Appointment] {
        appointments
            .filter {
                Calendar.current.isDateInToday($0.dateTime) &&
                $0.type == .inStore
            }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var todaysVideoAppointments: [Appointment] {
        appointments
            .filter {
                Calendar.current.isDateInToday($0.dateTime) &&
                $0.type == .video
            }
            .sorted { $0.dateTime < $1.dateTime }
    }

    func filteredOtherAppointments(statusFilter: AppointmentStatus?, searchText: String) -> [Appointment] {
        let others = appointments.filter { !Calendar.current.isDateInToday($0.dateTime) }
        
        let filtered = others.filter { appt in
            let nameMatch = searchText.isEmpty || clientName(for: appt.clientId).localizedCaseInsensitiveContains(searchText)
            let statusMatch = statusFilter == nil || appt.status == statusFilter
            return nameMatch && statusMatch
        }
        
        // Sort: upcoming (future) nearest first, past most recent first
        return filtered.sorted { a, b in
            let aIsFuture = a.dateTime > Date()
            let bIsFuture = b.dateTime > Date()
            
            if aIsFuture && bIsFuture {
                return a.dateTime < b.dateTime // Nearest upcoming first
            } else if !aIsFuture && !bIsFuture {
                return a.dateTime > b.dateTime // Most recent past first
            } else {
                return aIsFuture // Future appointments before past
            }
        }
    }

    var statusCounts: [(status: AppointmentStatus, count: Int)] {
        Dictionary(grouping: appointments, by: \.status).map { ($0.key, $0.value.count) }
    }

    func createAppointment(_ a: Appointment) async throws {
        try await dataStore.createAppointment(a)
        simulateNotificationDelivery(for: a, action: "APPOINTMENT CONFIRMATION")
    }

    func updateAppointment(_ a: Appointment) async throws {
        try await dataStore.updateAppointment(a)
        simulateNotificationDelivery(for: a, action: "APPOINTMENT RESCHEDULED / UPDATED")
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

    // MARK: - Reminder Helpers

    func reminderStatusColor(_ status: String) -> Color {
        switch status {
        case "Sent":    return RSMSTheme.success
        case "Failed":  return RSMSTheme.danger
        default:        return RSMSTheme.textSecondary   // Pending
        }
    }

    func reminderStatusIcon(_ status: String) -> String {
        switch status {
        case "Sent":    return "bell.badge.fill"
        case "Failed":  return "exclamationmark.triangle.fill"
        default:        return "bell"
        }
    }

    /// Manually send (or re-send) a reminder for a specific appointment.
    /// Simulates a network call and updates the appointment record.
    @MainActor
    func sendReminder(for appointment: Appointment) async throws {
        // Simulate a short network delay
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6s

        // Simulate ~90% success rate for demo purposes
        let success = Int.random(in: 0..<10) < 9

        let updated = Appointment(
            id: appointment.id,
            clientId: appointment.clientId,
            associateId: appointment.associateId,
            storeId: appointment.storeId,
            dateTime: appointment.dateTime,
            durationMinutes: appointment.durationMinutes,
            type: appointment.type,
            status: appointment.status,
            reminderSentAt: success ? Date() : appointment.reminderSentAt,
            videoLink: appointment.videoLink,
            notes: appointment.notes,
            createdAt: appointment.createdAt,
            reminderTimingHours: appointment.reminderTimingHours,
            reminderChannel: appointment.reminderChannel,
            reminderStatus: success ? "Sent" : "Failed",
            reminderError: success ? nil : "Delivery service temporarily unavailable"
        )

        try await dataStore.updateAppointment(updated)
        
        if success {
            simulateNotificationDelivery(for: updated, action: "MANUAL REMINDER SENT")
        }
    }

    /// Automatic sweep: process all pending reminders whose window has arrived.
    @MainActor
    func processAutomaticReminders() async {
        let now = Date()
        let pendingAppointments = upcomingAppointments.filter { $0.reminderStatus == "Pending" }

        for appointment in pendingAppointments {
            let triggerDate = appointment.dateTime.addingTimeInterval(-Double(appointment.reminderTimingHours) * 3600)
            if now >= triggerDate {
                try? await sendReminder(for: appointment)
            }
        }
    }
    
    // MARK: - Simulated Notification Engine
    private func simulateNotificationDelivery(for a: Appointment, action: String) {
        let clientName = clientName(for: a.clientId)
        let formattedDate = a.dateTime.formatted(date: .long, time: .shortened)
        let channel = a.reminderChannel
        
        print("\n✨ [MAISON LUMIÈRE NOTIFICATION ENGINE] SIMULATING: \(action) ✨")
        print("--------------------------------------------------------------------------------")
        print("Recipient: \(clientName)")
        print("Channel: \(channel)")
        print("Time: \(Date().formatted())")
        print("--------------------------------------------------------------------------------")
        
        // Render FaceTime Details if present
        if a.type == .video, let config = a.decodedFaceTimeConfig {
            print("📩 --- SIMULATED CONFIRMATION EMAIL ---")
            print("Subject: Your Private FaceTime Consultation - Maison Lumière")
            print("Dear \(clientName),")
            print("Your exclusive luxury styling session is confirmed for \(formattedDate).")
            print("A personal advisor will connect with you via FaceTime.")
            print("")
            print("FaceTime Contact Details:")
            print("  • FaceTime Account: \(config.contact)")
            if let link = config.meetingLink, !link.isEmpty {
                print("  • Direct Meeting Link: \(link)")
            }
            if let notes = config.notes, !notes.isEmpty {
                print("  • Advisor Instructions: \(notes)")
            }
            print("")
            print("To begin your consultation, simply tap the connection link in your portal or open the direct meeting link above.")
            print("Warmest regards,")
            print("Maison Lumière Concierge")
            print("--------------------------------------------------------------------------------")
            
            print("📅 --- SIMULATED CALENDAR INVITE (.ICS) ---")
            print("Title: Private FaceTime Styling Consult | Maison Lumière")
            print("Start: \(a.dateTime)")
            print("Duration: \(a.durationMinutes) minutes")
            print("URL: \(config.meetingLink ?? "facetime://\(config.contact)")")
            print("Description:")
            print("  FaceTime Consultation with your personal advisor.")
            print("  Contact: \(config.contact)")
            if let notes = config.notes, !notes.isEmpty {
                print("  Instructions: \(notes)")
            }
            print("--------------------------------------------------------------------------------")
            
            print("📱 --- SIMULATED CLIENT PUSH / SMS REMINDER ---")
            var body = "Maison Lumière Reminder: Your FaceTime Styling Consult is scheduled for \(formattedDate)."
            if let link = config.meetingLink, !link.isEmpty {
                body += " Join here: \(link)"
            } else {
                body += " We will reach you via FaceTime at \(config.contact)."
            }
            print(body)
            print("--------------------------------------------------------------------------------\n")
        } else {
            print("📩 --- SIMULATED CONFIRMATION EMAIL ---")
            print("Subject: Your Consultation Confirmation - Maison Lumière")
            print("Dear \(clientName),")
            print("Your Private \(a.type == .inStore ? "In-Store" : "Phone") Consultation is confirmed for \(formattedDate).")
            print("Location/Details: Maison Lumière Vendôme, Paris")
            print("--------------------------------------------------------------------------------")
            
            print("📅 --- SIMULATED CALENDAR INVITE ---")
            print("Title: Maison Lumière Consultation")
            print("Start: \(a.dateTime)")
            print("--------------------------------------------------------------------------------\n")
        }
    }
}
