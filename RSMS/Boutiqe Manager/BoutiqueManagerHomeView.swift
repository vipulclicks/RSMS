//
//  BoutiqueManagerHomeView.swift
//  RSMS
//
//  iPad sidebar navigation for Boutique Manager role.
//

import SwiftUI

enum BoutiqueSection: String, CaseIterable, Identifiable {
    case dashboard             = "Store Dashboard"
    case staff                 = "Staff"
    case performance           = "Performance"
    case todaysShift           = "Today's Shift"
    case appointmentsInventory = "Appointments & Inventory"
    case commissionManagement  = "Commission Management"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:             return "chart.bar.fill"
        case .staff:                 return "person.2.fill"
        case .performance:           return "chart.line.uptrend.xyaxis"
        case .todaysShift:           return "calendar.badge.clock"
        case .appointmentsInventory: return "shippingbox.fill"
        case .commissionManagement:  return "dollarsign.circle.fill"
        }
    }
}

struct BoutiqueManagerHomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedSection: BoutiqueSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .tint(RSMSTheme.primaryDark)
        .navigationSplitViewStyle(.prominentDetail)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedSection) {
            ForEach(BoutiqueSection.allCases) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Boutique Manager")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                logoutButton
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .dashboard:
            StoreDashboardView()
        case .staff:
            StaffView()
        case .performance:
            PerformanceView()
        case .todaysShift:
            ShiftMonitorView()
        case .appointmentsInventory:
            AppointmentsInventoryView()
        case .commissionManagement:
            CommissionManagementView()
        case .none:
            StoreDashboardView()
        }
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button {
            viewModel.logout()
        } label: {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                .foregroundStyle(RSMSTheme.danger)
        }
    }
}

#Preview {
    BoutiqueManagerHomeView()
        .environment(AppViewModel())
}
