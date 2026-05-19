//
//  InventoryControllerHomeView.swift
//  RSMS
//
//  iPad sidebar navigation for Inventory Controller role.
//

import SwiftUI

enum InventorySection: String, CaseIterable, Identifiable {
    case rfidStock = "RFID Stock Management"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .rfidStock: return "sensor.tag.radiowaves.forward.fill"
        }
    }
}

struct InventoryControllerHomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedSection: InventorySection? = .rfidStock

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
            ForEach(InventorySection.allCases) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
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

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .rfidStock:
            RFIDStockManagementView()
        case .none:
            RFIDStockManagementView()
        }
    }
}

#Preview {
    InventoryControllerHomeView()
        .environment(AppViewModel())
}
