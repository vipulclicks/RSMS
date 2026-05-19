//
//  SalesAssociateHomeView.swift
//  RSMS
//
//  iPad sidebar navigation for Sales Associate role.
//

import SwiftUI

enum SalesSection: String, CaseIterable, Identifiable {
    case clienteling  = "Clienteling"
    case appointments = "Appointments & Remote Selling"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .clienteling:  return "person.text.rectangle.fill"
        case .appointments: return "calendar.badge.clock"
        }
    }
}

struct SalesAssociateHomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedSection: SalesSection? = .clienteling

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .tint(RSMSTheme.gold)
    }

    private var sidebar: some View {
        List(selection: $selectedSection) {
            ForEach(SalesSection.allCases) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Sales Associate")
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

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .clienteling:
            ClientelingView()
        case .appointments:
            AppointmentRemoteSellingView()
        case .none:
            ClientelingView()
        }
    }
}

#Preview {
    SalesAssociateHomeView()
        .environment(AppViewModel())
}
