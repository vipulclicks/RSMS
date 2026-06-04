//
//  ManagerNotificationSheet.swift
//  RSMS
//

import SwiftUI

struct ManagerNotificationSheet: View {
    var dashboardVM: BoutiqueDashboardViewModel
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [GridItem(.adaptive(minimum: 320), spacing: 24)]
    
    private var pendingApprovals: [DiscountApprovalRequest] {
        appVM.dataStore.discountApprovalRequests.filter { $0.status == .pending }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    
                    // MARK: Discount Approvals Section
                    if !pendingApprovals.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(.orange)
                                Text("Pending Approvals")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(pendingApprovals) { request in
                                    NavigationLink(destination: ApprovalDetailScreen(request: request)) {
                                        ApprovalRequestCard(request: request)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // MARK: Inventory Alerts Section
                    if !dashboardVM.lowStockAlerts.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(RSMSTheme.warning)
                                Text("Low Stock Alerts")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(dashboardVM.lowStockAlerts) { alert in
                                    LowStockAlertCard(alert: alert)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if pendingApprovals.isEmpty && dashboardVM.lowStockAlerts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(RSMSTheme.success)
                            Text("All Caught Up")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("You have no pending notifications.")
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        .padding(.top, 100)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}

// Extracted card for low stock to simplify the main view
struct LowStockAlertCard: View {
    let alert: LowStockAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(alert.product.name)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(2)
                    Text("SKU: \(alert.product.sku)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Stock")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("\(alert.stockItem.quantity)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.danger)
                }
            }
        }
        .padding(24)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
