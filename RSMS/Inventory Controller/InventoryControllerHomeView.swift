//
//  InventoryControllerHomeView.swift
//  RSMS
//
//  iPad-optimized dashboard for Inventory Controller role.
//  Extension-based sections live in InventoryDashboardSections.swift.
//

import SwiftUI

// MARK: - Navigation Destinations

enum InventoryDestination: String, CaseIterable, Hashable, Identifiable {
    case dashboard = "Dashboard"
    case scan      = "Scan Item"
    case rfid      = "RFID Management"
    case notify    = "Notify Manager"
    case reconcile = "Stock Reconciliation"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .scan:      return "barcode.viewfinder"
        case .rfid:      return "sensor.tag.radiowaves.forward"
        case .notify:    return "paperplane.fill"
        case .reconcile: return "arrow.triangle.2.circlepath"
        }
    }
}

struct InventoryControllerHomeView: View {
    @Environment(AppViewModel.self) var viewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var dashVM = InventoryDashboardViewModel()
    @State var selectedDestination: InventoryDestination? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detailView
        }
        .tint(RSMSTheme.gold)
    }
    
    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedDestination) {
            ForEach(InventoryDestination.allCases) { dest in
                Label(dest.rawValue, systemImage: dest.icon)
                    .tag(dest)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    viewModel.logout()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(RSMSTheme.danger)
                }
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedDestination {
        case .dashboard, .none:
            dashboardView
        case .scan:
            InventoryBarcodeScannerView()
        case .rfid:
            RFIDStockManagementView()
        case .notify:
            NotifyBoutiqueManagerView()
        case .reconcile:
            StockReconciliationView()
        }
    }

    // MARK: - Dashboard View

    private var dashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                greetingSection
                heroKPICard
                alertTasksRow
                systemControlSection
                activityFeedSection
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    InventoryControllerHomeView()
        .environment(AppViewModel())
}
