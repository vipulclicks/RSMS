//
//  SalesAssociateDashboardViewModel.swift
//  RSMS
//
//  ViewModel for the Sales Associate Dashboard.
//  Provides KPI computations and greeting text.
//

import SwiftUI

@Observable
final class SalesAssociateDashboardViewModel {

    // MARK: - Data
    // TODO: Replace mock data with Supabase fetch
    private(set) var transactions: [Transaction] = Transaction.all
    private(set) var appointments: [Appointment] = Appointment.all
    private(set) var clients: [ClientProfile] = ClientProfile.allClients
    private(set) var curatedCarts: [UniversalCart] = [UniversalCart.previewCurated]
    private(set) var products: [Product] = Product.all

    // MARK: - Formatting

    var todayDate: String {
        RSMSDateFormatter.fullDate.string(from: .now)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default:      return "Good Evening"
        }
    }

    // MARK: - KPIs

    var todaySalesTotal: Double {
        transactions
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.totalAmount }
    }

    var todaySalesFormatted: String {
        "₹\(Int(todaySalesTotal).formatted())"
    }

    var activeClientCount: Int { clients.count }

    var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.status == .scheduled || $0.status == .confirmed }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var upcomingAppointmentCount: Int { upcomingAppointments.count }

    var activeCuratedCartCount: Int {
        curatedCarts.filter {
            $0.status == .active || $0.status == .shared || $0.status == .draft
        }.count
    }

    var totalProductCount: Int { products.count }

    // MARK: - Helpers

    func clientName(for id: UUID) -> String {
        clients.first { $0.id == id }?.fullName ?? "Walk-in Client"
    }

    func appointmentStatusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled:  return RSMSTheme.info
        case .confirmed:  return RSMSTheme.success
        case .inProgress: return RSMSTheme.warning
        case .completed:  return RSMSTheme.textSecondary
        case .cancelled, .noShow: return RSMSTheme.danger
        }
    }

    func appointmentTypeIcon(_ type: AppointmentType) -> String {
        switch type {
        case .inStore: return "building.2.fill"
        case .video:   return "video.fill"
        case .phone:   return "phone.fill"
        }
    }
}
