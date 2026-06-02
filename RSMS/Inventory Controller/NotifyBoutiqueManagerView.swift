//
//  NotifyBoutiqueManagerView.swift
//  RSMS
//
//  Premium iOS-style mobile dashboard for Inventory Controllers
//  to notify Boutique Managers about low stock items.
//

import SwiftUI

struct NotifyBoutiqueManagerView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel = NotifyBoutiqueManagerViewModel()
    @State private var appeared = false
    
    // Modal state
    @State private var showSuccessModal = false
    @State private var selectedAlert: LowStockAlertItem? = nil
    
    private let summaryColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // Background
            RSMSTheme.background
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    summarySection
                    lowStockAlertSection
                }
                .padding(24)
                
                if viewModel.isLoading {
                    ProgressView("Loading inventory data...")
                        .tint(RSMSTheme.gold)
                        .padding(.top, 40)
                } else if viewModel.lowStockItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(RSMSTheme.success)
                        Text("All stock levels are optimal.")
                            .font(.headline)
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                    .padding(.top, 40)
                }
            }
            .navigationTitle("Notify Manager")
            .navigationBarTitleDisplayMode(.inline)
            
            // Success Modal Overlay
            if showSuccessModal {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation {
                            showSuccessModal = false
                        }
                    }
                
                if let alert = selectedAlert {
                    successModal(for: alert)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
        }
        }
        .task {
            await viewModel.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .refreshable {
            await viewModel.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notify Boutique Manager")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(RSMSTheme.textPrimary)
            Text("Monitor low-stock products & request replenishment")
                .font(.subheadline)
                .foregroundColor(RSMSTheme.textPrimary.opacity(0.6))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }
    
    // MARK: - Summary Cards
    
    private var summarySection: some View {
        LazyVGrid(columns: summaryColumns, spacing: 14) {
            summaryCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(viewModel.lowStockCount)",
                label: "Low Stock Products",
                description: "Products requiring replenishment",
                iconColor: RSMSTheme.textPrimary,
                valueColor: RSMSTheme.textPrimary
            )
            summaryCard(
                icon: "exclamationmark.octagon.fill",
                value: "\(viewModel.criticalCount)",
                label: "Critical Inventory",
                description: "Immediate manager attention needed",
                iconColor: RSMSTheme.primary,
                valueColor: RSMSTheme.primary
            )
            summaryCard(
                icon: "paperplane.fill",
                value: "\(viewModel.notifiedCount)",
                label: "Notifications Sent",
                description: "Low-stock alerts delivered",
                iconColor: RSMSTheme.gold,
                valueColor: RSMSTheme.textPrimary
            )
            summaryCard(
                icon: "shippingbox.fill",
                value: "\(viewModel.activeRequestsCount)",
                label: "Restock Requests",
                description: "Awaiting inventory refill",
                iconColor: RSMSTheme.gold,
                valueColor: RSMSTheme.textPrimary
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }
    
    private func summaryCard(icon: String, value: String, label: String, description: String, iconColor: Color, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(valueColor)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundColor(RSMSTheme.textPrimary)
            Text(description)
                .font(.system(size: 10))
                .foregroundColor(RSMSTheme.textPrimary.opacity(0.55))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: RSMSTheme.textPrimary.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Low Stock Alert Section
    
    private var lowStockAlertSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Low Stock Alerts")
                .font(.title3.weight(.semibold))
                .foregroundColor(RSMSTheme.textPrimary)
                .padding(.top, 10)
            
            ForEach(Array(viewModel.lowStockItems.enumerated()), id: \.element.id) { index, item in
                productAlertCard(item)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: appeared)
            }
        }
    }
    
    private func productAlertCard(_ item: LowStockAlertItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Row: Image, Name, SKU, Badge
            HStack(alignment: .top, spacing: 12) {
                // Product Image Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RSMSTheme.surfaceSecondary.opacity(0.3))
                        .frame(width: 56, height: 56)
                    Image(systemName: iconForCategory(item.product.category))
                        .font(.title2)
                        .foregroundColor(RSMSTheme.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(RSMSTheme.textPrimary)
                        .lineLimit(1)
                    Text("SKU: \(item.product.sku)")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.textPrimary.opacity(0.5))
                }
                Spacer(minLength: 0)
                
                // Status Badge
                StatusBadge(text: item.statusText, color: item.statusColor)
            }
            
            // Stock Progress Indicator
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Stock Level")
                        .font(.caption.weight(.medium))
                        .foregroundColor(RSMSTheme.textPrimary.opacity(0.7))
                    Spacer()
                    Text("\(item.currentQty) / \(item.thresholdQty)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(item.statusColor)
                }
                
                // Linear Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(RSMSTheme.surfaceSecondary.opacity(0.4))
                            .frame(height: 8)
                        Capsule()
                            .fill(item.statusColor)
                            .frame(width: max(0, geo.size.width * item.progress), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Bottom Row: Time and CTA
            HStack {
                Text("Last updated: \(timeAgo(item.lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(RSMSTheme.textPrimary.opacity(0.4))
                
                Spacer()
                
                // CTA Button
                Button {
                    if !item.isManagerNotified {
                        handleNotifyAction(for: item)
                    }
                } label: {
                    HStack(spacing: 6) {
                        if item.isManagerNotified {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Manager Notified")
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Notify Manager")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(item.isManagerNotified ? RSMSTheme.textPrimary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(item.isManagerNotified ? RSMSTheme.surfaceSecondary.opacity(0.5) : RSMSTheme.primary)
                    )
                }
                .disabled(item.isManagerNotified)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(RSMSTheme.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(item.isManagerNotified ? RSMSTheme.success.opacity(0.3) : RSMSTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: RSMSTheme.textPrimary.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    

    // MARK: - Confirmation Modal
    
    private func successModal(for item: LowStockAlertItem) -> some View {
        VStack(spacing: 20) {
            // Checkmark Animation
            ZStack {
                Circle()
                    .fill(RSMSTheme.success.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(RSMSTheme.success)
            }
            
            // Text Content
            VStack(spacing: 8) {
                Text("Notification Sent Successfully")
                    .font(.title3.weight(.bold))
                    .foregroundColor(RSMSTheme.textPrimary)
                Text("Boutique Manager has been informed about the low stock item.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(RSMSTheme.textPrimary.opacity(0.7))
            }
            
            // Product Details Card inside Modal
            VStack(alignment: .leading, spacing: 12) {
                Text(item.product.name)
                    .font(.headline)
                    .foregroundColor(RSMSTheme.textPrimary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Stock")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.textPrimary.opacity(0.5))
                        Text("\(item.currentQty)")
                            .font(.title3.weight(.bold))
                            .foregroundColor(item.statusColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Threshold Breached")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.textPrimary.opacity(0.5))
                        Text("\(item.thresholdQty)")
                            .font(.title3.weight(.bold))
                            .foregroundColor(RSMSTheme.primary)
                    }
                }
                
                Divider()
                    .background(RSMSTheme.surfaceSecondary)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Sent at: \(Date().formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                    Spacer()
                }
                .foregroundColor(RSMSTheme.textPrimary.opacity(0.5))
            }
            .padding(16)
            .background(RSMSTheme.surfaceSecondary.opacity(0.3))
            .cornerRadius(12)
            
            // Duplicate prevention notice
            HStack(spacing: 6) {
                Image(systemName: "shield.fill")
                    .foregroundColor(RSMSTheme.gold)
                Text("Duplicate notifications prevented automatically")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(RSMSTheme.textPrimary.opacity(0.6))
            }
            
            // Close Button
            Button {
                withAnimation {
                    showSuccessModal = false
                }
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(RSMSTheme.textPrimary))
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                // Fallback background if material is too transparent
                .background(RSMSTheme.background.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Actions
    
    private func handleNotifyAction(for item: LowStockAlertItem) {
        // Trigger logic to notify
        viewModel.notifyManager(for: item.id)
        
        // Show modal
        selectedAlert = item
        withAnimation(.spring()) {
            showSuccessModal = true
        }
    }
    
    // MARK: - Helpers
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Handbags": return "handbag.fill"
        case "Watches": return "watch.analog"
        case "Heels": return "shoe.fill" // SF Symbol closest to heels is shoe
        case "Dresses": return "figure.dress.line.vertical.figure"
        default: return "shippingbox.fill"
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let mins = Int(-date.timeIntervalSinceNow / 60)
        if mins < 1 { return "Just now" }
        if mins < 60 { return "\(mins)m ago" }
        let hours = mins / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

#Preview {
    NotifyBoutiqueManagerView()
        .environment(AppViewModel())
}
