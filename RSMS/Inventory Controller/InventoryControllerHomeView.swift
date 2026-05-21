//
//  InventoryControllerHomeView.swift
//  RSMS
//
//  iPad-optimized dashboard for Inventory Controller role.
//  Extension-based sections live in InventoryDashboardSections.swift.
//

import SwiftUI

// MARK: - Navigation Destinations

enum InventoryDestination: Hashable {
    case scan
    case rfid
    case notify
}

struct InventoryControllerHomeView: View {
    @Environment(AppViewModel.self) var viewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var dashVM = InventoryDashboardViewModel()
    @State var selectedDestination: InventoryDestination?

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(RSMSTheme.danger)
                    }
                }
            }
            .navigationDestination(item: $selectedDestination) { dest in
                switch dest {
                case .scan:
                    InventoryBarcodeScannerView()
                case .rfid:
                    RFIDStockManagementView()
                case .notify:
                    NotifyBoutiqueManagerView()
                }
            }
        }
    }
}

#Preview {
    InventoryControllerHomeView()
        .environment(AppViewModel())
}
