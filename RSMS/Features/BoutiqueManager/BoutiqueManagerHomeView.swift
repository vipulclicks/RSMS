//
//  BoutiqueManagerHomeView.swift
//  RSMS
//
//  iPad sidebar navigation for Boutique Manager role.
//

import SwiftUI

enum BoutiqueSection: String, CaseIterable, Identifiable {
    case dashboard     = "Store Dashboard"
    case staffPlanning = "Staff & Shift Planning"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:     return "chart.bar.fill"
        case .staffPlanning: return "person.3.fill"
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
        .tint(RSMSTheme.primary)
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
        case .staffPlanning:
            StaffShiftPlanningView()
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
