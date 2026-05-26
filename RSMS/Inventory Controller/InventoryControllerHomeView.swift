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
    case dashboard      = "Dashboard"
    case productLookup  = "Lookup & Stock In"
    case cycleCounts    = "Cycle Counts & Verify"
    case auditReconcile = "Audit & Reconcile"
    case notify         = "Notify Manager"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:       return "chart.bar.fill"
        case .productLookup:   return "magnifyingglass.circle.fill"
        case .cycleCounts:     return "arrow.triangle.2.circlepath"
        case .auditReconcile:  return "doc.text.magnifyingglass"
        case .notify:          return "paperplane.fill"
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
            Section {
                Label(InventoryDestination.dashboard.rawValue,
                      systemImage: InventoryDestination.dashboard.icon)
                    .tag(InventoryDestination.dashboard)

                Label(InventoryDestination.productLookup.rawValue,
                      systemImage: InventoryDestination.productLookup.icon)
                    .tag(InventoryDestination.productLookup)
            }

            Section {
                Label(InventoryDestination.cycleCounts.rawValue,
                      systemImage: InventoryDestination.cycleCounts.icon)
                    .tag(InventoryDestination.cycleCounts)

                Label(InventoryDestination.auditReconcile.rawValue,
                      systemImage: InventoryDestination.auditReconcile.icon)
                    .tag(InventoryDestination.auditReconcile)

                Label(InventoryDestination.notify.rawValue,
                      systemImage: InventoryDestination.notify.icon)
                    .tag(InventoryDestination.notify)
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
        case .productLookup:
            ProductLookupView()
        case .cycleCounts:
            CycleCountView()
        case .auditReconcile:
            StockReconciliationView()
        case .notify:
            NotifyBoutiqueManagerView()
        }
    }

    // MARK: - Dashboard View

    private var dashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                greetingSection
                heroKPICard
                actionGrid
                activityFeedSection
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if dashVM.snapshot == nil {
                await dashVM.load(dataStore: viewModel.dataStore, storeId: viewModel.currentStoreId ?? UUID())
            }
        }
    }
}

#Preview {
    InventoryControllerHomeView()
        .environment(AppViewModel())
}
