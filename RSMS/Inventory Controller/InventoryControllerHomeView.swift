//
//  InventoryControllerHomeView.swift
//  RSMS
//
//  iPad-optimized dashboard for Inventory Controller role.
//  Extension-based sections live in InventoryDashboardSections.swift.
//

import SwiftUI

// MARK: - Navigation Destinations

enum InventoryDestination: String, Hashable, Identifiable {
    case dashboard   = "Dashboard"
    case movements   = "Movements"
    case audits      = "Audits & Counts"
    case operations  = "Operations"
    case catalog     = "Catalog"
    case profile     = "My Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:  return "chart.bar.fill"
        case .movements:  return "shippingbox.fill"
        case .audits:     return "checkmark.shield.fill"
        case .operations: return "wrench.and.screwdriver.fill"
        case .catalog:    return "book.fill"
        case .profile:    return "person.crop.circle.fill"
        }
    }

    static var tabs: [InventoryDestination] {
        [.dashboard, .movements, .audits, .operations, .catalog]
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
                ForEach(InventoryDestination.tabs) { destination in
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
            .sheet(item: Binding(
                get: { selectedDestination == .profile ? InventoryDestination.profile : nil },
                set: { if $0 == nil { selectedDestination = .dashboard } }
            )) { _ in
                NavigationStack {
                    InventoryControllerProfileView()
                }
            }
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
            ForEach(InventoryDestination.tabs) { dest in
                NavigationLink(value: dest) {
                    Label(dest.rawValue, systemImage: dest.icon)
                }
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
        case .movements:
            MovementsContainerView()
        case .audits:
            AuditsContainerView()
        case .operations:
            OperationsContainerView()
        case .catalog:
            ProductLookupView()
        case .profile:
            InventoryControllerProfileView()
        }
    }

    // MARK: - Dashboard View

    @State var showNotifyManager = false
    @State var showProductLookup = false

    private var dashboardView: some View {
        DashboardView(
            dashVM: dashVM,
            selectedDestination: $selectedDestination,
            showNotifyManager: $showNotifyManager,
            showProductLookup: $showProductLookup
        )
        .background(RSMSTheme.background)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNotifyManager) {
            NavigationStack {
                NotifyBoutiqueManagerView()
            }
        }
        .sheet(isPresented: $showProductLookup) {
            NavigationStack {
                ProductLookupView()
            }
        }
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
