//
//  LowStockNotificationView.swift
//  RSMS
//
//  Created by Nitin Singh on 21/05/26.
//

import SwiftUI

struct LowStockNotificationView: View {
    var alerts: [LowStockAlert]
    @Environment(\.dismiss) private var dismiss
    
    // Adaptive grid columns so cards sit side-by-side on iPad
    private let columns = [
        GridItem(.adaptive(minimum: 320), spacing: 24)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if alerts.isEmpty {
                        emptyState
                    } else {
                        warningBanner
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(alerts) { alert in
                                alertCard(alert)
                            }
                        }
                    }
                }
                .padding(32)
            }
            .background(RSMSTheme.background)
            .navigationTitle("Inventory Alerts")
            .navigationBarTitleDisplayMode(.large) // Gives it that big serif header look
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var warningBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(RSMSTheme.warning)
            
            Text("\(alerts.count) High-Value SKUs require immediate attention.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            Spacer()
        }
        .padding(20)
        .background(RSMSTheme.warning.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.warning.opacity(0.3), lineWidth: 1))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(RSMSTheme.success)
            Text("Inventory Optimal")
                .font(.title2.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("All products are currently above the defined low-stock threshold.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
    
    private func alertCard(_ alert: LowStockAlert) -> some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                // Product Image Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.surfaceTertiary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "bag.fill") // Generic placeholder icon
                            .font(.title)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    )
                
                // Product Details
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
                
                // Stock Level (Red)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Stock")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    // Formats numbers less than 10 with a leading zero (e.g., "02")
                    Text(String(format: "%02d", alert.stockItem.quantity))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.danger)
                }
            }
            
            // MARK: Action Buttons
            HStack(spacing: 16) {
                Button {
                    // Action: Request Transfer
                } label: {
                    Text("Request Transfer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                }
                
                Button {
                    // Action: Reorder
                } label: {
                    Text("Reorder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RSMSTheme.gold)
                        .clipShape(Capsule())
                }
            }
        }
        .rsmsCard(padding: 24)
    }
}

#Preview {
    LowStockNotificationView(alerts: [
        LowStockAlert(product: Product.previewWatch, stockItem: StockItem.preview),
        LowStockAlert(product: Product.previewRing, stockItem: StockItem(id: UUID(), productId: UUID(), storeId: UUID(), quantity: 0, rfidTag: nil, location: nil, status: .available, lastScannedAt: .now, updatedAt: .now))
    ])
}
