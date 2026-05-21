//
//  InventoryControllerHomeView.swift
//  RSMS
//
//  Inventory Controller dashboard — hamburger drawer navigation for iPad and iPhone.
//  Colors sourced from RSMSTheme. Cards use RSMSTheme.cream (white) so they sit
//  lighter than the RSMSTheme.background (ivory beige) beneath them.
//

import SwiftUI

// MARK: - Navigation Destination

enum NavDestination: String, CaseIterable {
    case dashboard = "Dashboard"
    case scan      = "Scan Item"

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .scan:      return "barcode.viewfinder"
        }
    }
}

// MARK: - Main View

struct InventoryControllerHomeView: View {

    @Environment(AppViewModel.self) var viewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var dashVM             = InventoryDashboardViewModel()
    @State var selectedDestination: NavDestination = .dashboard
    @State private var isSidebarOpen: Bool = false

    private var sidebarWidth: CGFloat { horizontalSizeClass == .regular ? 300 : 270 }

    var body: some View {
        ZStack(alignment: .leading) {

            // ── Main content ─────────────────────────────────────────────────
            NavigationStack {
                destinationContent
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                    isSidebarOpen.toggle()
                                }
                            } label: {
                                Image(systemName: isSidebarOpen ? "xmark" : "line.3.horizontal")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(RSMSTheme.gold)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        ToolbarItem(placement: .principal) {
                            Text(selectedDestination.rawValue.uppercased())
                                .font(.system(.headline, design: .serif, weight: .light))
                                .tracking(6)
                                .foregroundStyle(RSMSTheme.gold)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 14) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Button {
                                    viewModel.logout()
                                } label: {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundStyle(RSMSTheme.gold.opacity(0.7))
                                }
                            }
                        }
                    }
                    .task {
                        if selectedDestination == .dashboard,
                           let sid = viewModel.currentStoreId {
                            await dashVM.load(dataStore: viewModel.dataStore, storeId: sid)
                        }
                    }
            }
            .disabled(isSidebarOpen)

            // ── Dim overlay ──────────────────────────────────────────────────
            if isSidebarOpen {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            isSidebarOpen = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }

            // ── Sidebar drawer ───────────────────────────────────────────────
            if isSidebarOpen {
                sidebarView
                    .frame(width: sidebarWidth)
                    .transition(.move(edge: .leading))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isSidebarOpen)
    }

    // MARK: - Destination Router

    @ViewBuilder
    private var destinationContent: some View {
        switch selectedDestination {
        case .dashboard:
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        greetingSection
                        heroKPICard
                        alertTasksRow
                        systemControlSection
                        activityFeedSection
                    }
                    .padding(horizontalSizeClass == .regular ? 24 : 16)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    if let sid = viewModel.currentStoreId {
                        await dashVM.load(dataStore: viewModel.dataStore, storeId: sid)
                    }
                }
                .background(RSMSTheme.background.ignoresSafeArea())

                // Loading banner
                if dashVM.isLoading {
                    HStack(spacing: 10) {
                        ProgressView().tint(RSMSTheme.gold)
                        Text("Updating dashboard…")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.cream)
                            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: dashVM.isLoading)

        case .scan:
            InventoryBarcodeScannerView()
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ───────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("RSMS")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(RSMSTheme.gold)
                Text("Inventory Controller")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.gold.opacity(0.55))
            }
            .padding(.horizontal, 22)
            .padding(.top, 56)
            .padding(.bottom, 24)

            Rectangle()
                .fill(RSMSTheme.gold.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 22)
                .padding(.bottom, 16)

            // ── Nav Items ────────────────────────────────────────────────────
            VStack(spacing: 4) {
                ForEach(NavDestination.allCases, id: \.self) { dest in
                    sidebarNavItem(dest)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            Rectangle()
                .fill(RSMSTheme.gold.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 22)
                .padding(.bottom, 16)

            // ── User info + Logout ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                if let name = viewModel.currentUser?.fullName {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(RSMSTheme.gold.opacity(0.18))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(name.prefix(1))
                                    .font(.caption.bold())
                                    .foregroundStyle(RSMSTheme.gold)
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text(name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RSMSTheme.cream)
                                .lineLimit(1)
                            Text("Inventory Controller")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.gold.opacity(0.5))
                        }
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isSidebarOpen = false
                    }
                    viewModel.logout()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline)
                        Text("Logout")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(RSMSTheme.danger.opacity(0.85))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 36)
        }
        .frame(maxHeight: .infinity)
        .background(RSMSTheme.textPrimary.ignoresSafeArea())
    }

    private func sidebarNavItem(_ dest: NavDestination) -> some View {
        let isSelected = selectedDestination == dest
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedDestination = dest
                isSidebarOpen = false
            }
            if dest == .dashboard, let sid = viewModel.currentStoreId {
                Task { await dashVM.load(dataStore: viewModel.dataStore, storeId: sid) }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: dest.icon)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 20)
                Text(dest.rawValue)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                Spacer()
                if isSelected {
                    Circle()
                        .fill(RSMSTheme.textPrimary)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(isSelected ? RSMSTheme.textPrimary : RSMSTheme.cream.opacity(0.65))
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? RSMSTheme.gold : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    InventoryControllerHomeView()
        .environment(AppViewModel())
}
