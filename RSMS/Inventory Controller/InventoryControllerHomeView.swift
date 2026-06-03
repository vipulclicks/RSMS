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
    case transfer       = "Transfer Inventory"
    case dcReplenishment = "DC Replenishments"
    case vendorReturns  = "Vendor Returns"
    case cycleCounts    = "Cycle Counts & Verify"
    case auditReconcile = "Audit & Reconcile"
    case auditTrail     = "Audit Trail"
    case authCertificates = "Auth Certificates"
    case notify         = "Notify Manager"
    case profile        = "My Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:       return "chart.bar.fill"
        case .productLookup:   return "magnifyingglass.circle.fill"
        case .transfer:        return "arrow.left.arrow.right"
        case .dcReplenishment: return "truck.box.fill"
        case .vendorReturns:   return "arrow.uturn.backward.circle.fill"
        case .cycleCounts:     return "arrow.triangle.2.circlepath"
        case .auditReconcile:  return "doc.text.magnifyingglass"
        case .auditTrail:      return "list.bullet.rectangle.portrait.fill"
        case .authCertificates:return "seal.fill"
        case .notify:          return "paperplane.fill"
        case .profile:         return "person.crop.circle.fill"
        }
    }
}

struct InventoryControllerHomeView: View {
    @Environment(AppViewModel.self) var viewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var dashVM = InventoryDashboardViewModel()
    @State var selectedDestination: InventoryDestination? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        if horizontalSizeClass == .compact {
            TabView(selection: $selectedDestination) {
                ForEach(InventoryDestination.allCases) { destination in
                    NavigationStack {
                        detailViewFor(destination)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        selectedDestination = .profile
                                    } label: {
                                        SidebarAvatarButton(user: viewModel.currentUser)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                    }
                    .tabItem {
                        Label(destination.rawValue, systemImage: destination.icon)
                    }
                    .tag(destination as InventoryDestination?)
                }
            }
            .tint(RSMSTheme.gold)
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebar
            } detail: {
                NavigationStack {
                    detailView
                }
            }
            .tint(RSMSTheme.gold)
            .navigationSplitViewStyle(.prominentDetail)
        }
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
                Label(InventoryDestination.transfer.rawValue,
                      systemImage: InventoryDestination.transfer.icon)
                    .tag(InventoryDestination.transfer)
                
                Label(InventoryDestination.dcReplenishment.rawValue,
                      systemImage: InventoryDestination.dcReplenishment.icon)
                    .tag(InventoryDestination.dcReplenishment)

                Label(InventoryDestination.vendorReturns.rawValue,
                      systemImage: InventoryDestination.vendorReturns.icon)
                    .tag(InventoryDestination.vendorReturns)
            }

            Section {
                Label(InventoryDestination.cycleCounts.rawValue,
                      systemImage: InventoryDestination.cycleCounts.icon)
                    .tag(InventoryDestination.cycleCounts)

                Label(InventoryDestination.auditReconcile.rawValue,
                      systemImage: InventoryDestination.auditReconcile.icon)
                    .tag(InventoryDestination.auditReconcile)
                
                Label(InventoryDestination.authCertificates.rawValue,
                      systemImage: InventoryDestination.authCertificates.icon)
                    .tag(InventoryDestination.authCertificates)

                Label(InventoryDestination.notify.rawValue,
                      systemImage: InventoryDestination.notify.icon)
                    .tag(InventoryDestination.notify)
            }

            Section {
                Label(InventoryDestination.profile.rawValue,
                      systemImage: InventoryDestination.profile.icon)
                    .tag(InventoryDestination.profile)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Inventory")
    }

    // MARK: - Detail

    /// Wraps detailContent and injects the avatar toolbar button
    /// into the top-right corner of the main screen.
    private var detailView: some View {
        detailContent
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedDestination = .profile
                    } label: {
                        SidebarAvatarButton(user: viewModel.currentUser)
                    }
                    .buttonStyle(.plain)
                }
            }
    }

    @ViewBuilder
    private var detailContent: some View {
        if let destination = selectedDestination {
            detailViewFor(destination)
        } else {
            detailViewFor(.dashboard)
        }
    }

    @ViewBuilder
    private func detailViewFor(_ destination: InventoryDestination) -> some View {
        switch destination {
        case .dashboard:
            dashboardView
        case .productLookup:
            ProductLookupView()
        case .transfer:
            InventoryTransferView()
        case .dcReplenishment:
            DCReplenishmentView()
        case .vendorReturns:
            VendorReturnView()
        case .cycleCounts:
            CycleCountView()
        case .auditReconcile:
            StockReconciliationView()
        case .auditTrail:
            AuditTrailView()
        case .authCertificates:
            AuthCertificateGeneratorView()
        case .notify:
            NotifyBoutiqueManagerView()
        case .profile:
            InventoryControllerProfileView()
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
        .onChange(of: viewModel.dataStore.auditTrails.count) { _, _ in
            dashVM.refreshSnapshot(dataStore: viewModel.dataStore, storeId: viewModel.currentStoreId ?? UUID())
        }
        .onChange(of: viewModel.dataStore.inventoryVariances.count) { _, _ in
            dashVM.refreshSnapshot(dataStore: viewModel.dataStore, storeId: viewModel.currentStoreId ?? UUID())
        }
        .onChange(of: viewModel.dataStore.stockItems.count) { _, _ in
            dashVM.refreshSnapshot(dataStore: viewModel.dataStore, storeId: viewModel.currentStoreId ?? UUID())
        }
    }
}

// MARK: - Sidebar Avatar Button

/// A compact 36 pt circular avatar for the sidebar toolbar.
/// Loads the user photo from `avatarURL` (Supabase Storage) via AsyncImage
/// and falls back to a gradient initials circle when no URL is available.
struct SidebarAvatarButton: View {
    let user: UserProfile?

    private var initials: String {
        guard let name = user?.fullName else { return "?" }
        let parts = name.components(separatedBy: " ")
        let f = parts.first?.prefix(1) ?? ""
        let l = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }

    private var avatarURL: URL? {
        guard let raw = user?.avatarURL, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    var body: some View {
        Group {
            if let url = avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                    default:
                        fallbackCircle
                    }
                }
            } else {
                fallbackCircle
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(RSMSTheme.gold.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: RSMSTheme.primary.opacity(0.25), radius: 6, x: 0, y: 2)
    }

    private var fallbackCircle: some View {
        ZStack {
            Circle().fill(RSMSTheme.primaryGradient)
            Text(initials)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.cream)
        }
    }
}

#Preview {
    InventoryControllerHomeView()
        .environment(AppViewModel())
}
