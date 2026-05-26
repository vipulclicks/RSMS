//
//  BoutiqueManagerHomeView.swift
//  RSMS
//
//  iPad sidebar navigation for Boutique Manager role.
//

import SwiftUI

enum BoutiqueSection: String, CaseIterable, Identifiable {
    case dashboard             = "Dashboard"
    case staff                 = "Staff"
    case todaysShift           = "Today's Shift"
    case inventory = "Inventory"
    case transfers             = "Stock Transfers"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:             return "chart.bar.fill"
        case .staff:                 return "person.2.fill"
        case .todaysShift:           return "calendar.badge.clock"
        case .inventory:             return "shippingbox.fill"
        case .transfers:             return "arrow.left.arrow.right"
        }
    }
}

struct BoutiqueManagerHomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedSection: BoutiqueSection? = .dashboard

    var body: some View {
        if horizontalSizeClass == .compact {
            TabView(selection: $selectedSection) {
                ForEach(BoutiqueSection.allCases) { section in
                    detailViewFor(section)
                        .tabItem {
                            Label(section.rawValue, systemImage: section.icon)
                        }
                        .tag(section as BoutiqueSection?)
                }
            }
            .tint(RSMSTheme.primaryDark)
        } else {
            NavigationSplitView {
                sidebar
            } detail: {
                detailView
            }
            .tint(RSMSTheme.primaryDark)
            .navigationSplitViewStyle(.prominentDetail)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedSection) {
            ForEach(BoutiqueSection.allCases) { section in
                let isSelected = selectedSection == section
                HStack(spacing: 16) {
                    Image(systemName: section.icon)
                        .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? RSMSTheme.primary : Color.black.opacity(0.85))
                        .frame(width: 24)
                    
                    Text(section.rawValue)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? RSMSTheme.primary : Color.black.opacity(0.85))
                    
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .tag(section)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
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
        if let section = selectedSection {
            detailViewFor(section)
        } else {
            detailViewFor(.dashboard)
        }
    }

    @ViewBuilder
    private func detailViewFor(_ section: BoutiqueSection) -> some View {
        switch section {
        case .dashboard:
            StoreDashboardView()
        case .staff:
            StaffView()
        case .todaysShift:
            ShiftMonitorView()
        case .inventory:
            AppointmentsInventoryView()
        case .transfers:
            StockTransfersView()
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
