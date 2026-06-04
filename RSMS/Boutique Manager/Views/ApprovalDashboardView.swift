//
//  ApprovalDashboardView.swift
//  RSMS
//

import SwiftUI

struct ApprovalDashboardView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var selectedTab: Int = 0 // 0: Pending, 1: Processed (Approved/Rejected)
    
    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Tab Bar
                HStack {
                    tabButton(title: "Pending", icon: "clock.fill", tab: 0)
                    tabButton(title: "Processed", icon: "checkmark.seal.fill", tab: 1)
                }
                .padding()
                .background(RSMSTheme.surfacePrimary)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == 0 {
                            let pending = appVM.dataStore.discountApprovalRequests.filter { $0.status == .pending }
                            if pending.isEmpty {
                                emptyState(title: "All Caught Up", subtitle: "No pending discount approvals.", icon: "checkmark.circle.fill")
                            } else {
                                ForEach(pending) { request in
                                    NavigationLink(destination: ApprovalDetailScreen(request: request)) {
                                        ApprovalRequestCard(request: request)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            let processed = appVM.dataStore.discountApprovalRequests.filter { $0.status != .pending }
                            if processed.isEmpty {
                                emptyState(title: "No History", subtitle: "No processed discount approvals.", icon: "doc.text.magnifyingglass")
                            } else {
                                ForEach(processed.sorted(by: { ($0.decisionDate ?? Date.distantPast) > ($1.decisionDate ?? Date.distantPast) })) { request in
                                    NavigationLink(destination: ApprovalDetailScreen(request: request)) {
                                        ApprovalRequestCard(request: request)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle("Discount Approvals")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Always fetch fresh approval requests from the DB
            try? await appVM.dataStore.fetchDiscountApprovalRequests()
            // Ensure clients and users are loaded so names resolve in cards
            try? await appVM.dataStore.fetchClients()
            if let storeId = appVM.currentStoreId {
                try? await appVM.dataStore.fetchUsers(storeId: storeId)
            }
        }
    }
    
    private func tabButton(title: String, icon: String, tab: Int) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .default) { selectedTab = tab }
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selectedTab == tab ? RSMSTheme.cream : RSMSTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedTab == tab ? AnyShapeStyle(RSMSTheme.primaryGradient) : AnyShapeStyle(Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func emptyState(title: String, subtitle: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(title)
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .padding(.top, 60)
    }
}

struct ApprovalRequestCard: View {
    let request: DiscountApprovalRequest
    @Environment(AppViewModel.self) private var appVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                let clientName = appVM.dataStore.clientName(for: request.clientId)
                Text(clientName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Spacer()
                
                StatusBadge(
                    text: request.status.rawValue.capitalized,
                    color: statusColor
                )
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cart Total")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("₹\(Int(request.cartTotal))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Requested Discount")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text(request.discountType == .percentage ? "\(Int(request.discountValue))%" : "₹\(Int(request.discountValue))")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RSMSTheme.danger)
                }
            }
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(RSMSTheme.textSecondary)
                let associateName = appVM.dataStore.userName(for: request.associateId)
                Text("Requested by \(associateName)")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Discount Request for \(appVM.dataStore.clientName(for: request.clientId)). Requested by \(appVM.dataStore.userName(for: request.associateId)).")
        .accessibilityValue("Status: \(request.status.rawValue). Discount: \(request.discountType == .percentage ? "\(Int(request.discountValue))%" : "₹\(Int(request.discountValue))")")
    }
    
    private var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .approved: return RSMSTheme.success
        case .rejected: return RSMSTheme.danger
        }
    }
}
