//
//  LowStockNotificationView.swift
//  RSMS
//
//  Created by Nitin Singh on 21/05/26.
//

import SwiftUI

struct LowStockNotificationView: View {
    // Now tracking the live ViewModel
    var dashboardVM: BoutiqueDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Toast state
    @State private var toastMessage: String? = nil
    
    private let columns = [GridItem(.adaptive(minimum: 320), spacing: 24)]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // MARK: The Background Fix
                // Placing the background color on the ZStack ensures the entire screen gets filled
                RSMSTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if dashboardVM.lowStockAlerts.isEmpty {
                            emptyState
                        } else {
                            warningBanner
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(dashboardVM.lowStockAlerts) { alert in
                                    alertCard(alert)
                                }
                            }
                        }
                    }
                    .padding(32)
                    // CRITICAL: Forces the content to stretch to the edges so it doesn't shrink-wrap!
                    .frame(maxWidth: .infinity)
                }
                
                // MARK: Floating Toast Notification
                if let message = toastMessage {
                    toastBanner(message: message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("Inventory Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
    }
    
    private var warningBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill").font(.title2).foregroundStyle(RSMSTheme.warning)
            Text("\(dashboardVM.lowStockAlerts.count) High-Value SKUs require immediate attention.")
                .font(.subheadline.weight(.medium)).foregroundStyle(RSMSTheme.textPrimary)
            Spacer()
        }
        .padding(20)
        .background(RSMSTheme.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.warning.opacity(0.3), lineWidth: 1))
    }
    
    private func alertCard(_ alert: LowStockAlert) -> some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                RoundedRectangle(cornerRadius: 12).fill(RSMSTheme.surfaceSecondary)
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "bag.fill").font(.title).foregroundStyle(RSMSTheme.textSecondary))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(alert.product.name).font(.title3.weight(.medium)).foregroundStyle(RSMSTheme.textPrimary).lineLimit(2)
                    Text("SKU: \(alert.product.sku)").font(.caption.weight(.bold)).foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Stock").font(.caption).foregroundStyle(RSMSTheme.textSecondary)
                    Text(String(format: "%02d", alert.stockItem.quantity))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.danger)
                }
            }
            
            Button {
                dashboardVM.reorderItem(for: alert.product.id)
                withAnimation(.spring(response: 0.3)) {
                    toastMessage = "\(alert.product.name) reorder initiated"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { toastMessage = nil }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Reorder")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RSMSTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .rsmsCard(padding: 24)
    }
    

    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill").font(.system(size: 64)).foregroundStyle(RSMSTheme.success)
            Text("Inventory Optimal").font(.title2.weight(.semibold)).foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.top, 100)
    }
    
    // Custom Toast UI
    private func toastBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(RSMSTheme.success)
                .font(.title3)
            
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(RSMSTheme.surfaceSecondary)
        .clipShape(Capsule())
        .shadow(color: RSMSTheme.textPrimary.opacity(0.15), radius: 15, y: 8)
        .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
        .padding(.bottom, 24)
    }
}

#Preview {
    LowStockNotificationView(dashboardVM: BoutiqueDashboardViewModel())
}
