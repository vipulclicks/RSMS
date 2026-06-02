//
//  DCReplenishmentView.swift
//  RSMS
//

import SwiftUI

struct DCReplenishmentView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var vm = DCReplenishmentViewModel()
    @State private var appeared = false
    
    private let kpiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            if vm.isLoading && vm.movements.isEmpty {
                loadingView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        kpiSection
                        recentReplenishmentsSection
                    }
                    .padding(24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("DC Replenishments")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
        .refreshable {
            await vm.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
        }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(RSMSTheme.gold)
                .scaleEffect(1.3)
            Text("Loading shipments…")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DC Replenishments")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Track incoming shipments from the Distribution Center")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }
    
    // MARK: - KPIs
    
    private var kpiSection: some View {
        LazyVGrid(columns: kpiColumns, spacing: 16) {
            kpiCard(title: "In Transit", value: "\(vm.inTransitCount)", icon: "truck.box.fill", color: Color(red: 43/255, green: 115/255, blue: 138/255))
            kpiCard(title: "Pending", value: "\(vm.pendingCount)", icon: "clock.fill", color: RSMSTheme.warning)
            kpiCard(title: "Received", value: "\(vm.completedCount)", icon: "checkmark.seal.fill", color: RSMSTheme.success)
            kpiCard(title: "Partial", value: "\(vm.partialCount)", icon: "exclamationmark.triangle.fill", color: RSMSTheme.danger)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }
    
    private func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 20))
            }
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
    
    // MARK: - Feed
    
    private var recentReplenishmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Shipments")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            
            if vm.recentReplenishments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "box.truck.badge.clock")
                        .font(.system(size: 32))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("No DC shipments found.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(RSMSTheme.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.recentReplenishments) { movement in
                        movementCard(movement)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }
    
    private func movementCard(_ movement: InventoryMovement) -> some View {
        let isReceived = movement.status == .received || movement.status == .completed
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.sourceName(for: movement))
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    Text(movement.asnNumber ?? "Unknown ASN")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                statusBadge(for: movement)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Items Expected")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("\(movement.itemsExpected ?? 0)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shipped At")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(movement.shippedAt?.formatted(date: .abbreviated, time: .shortened) ?? "N/A")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            
            if !isReceived && movement.status == .inTransit {
                Button {
                    Task {
                        await vm.markAsReceived(movement: movement, dataStore: appVM.dataStore, currentUser: appVM.currentUser)
                    }
                } label: {
                    HStack {
                        Image(systemName: "shippingbox.and.arrow.backward")
                        Text("Receive Shipment")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RSMSTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
    
    @ViewBuilder
    private func statusBadge(for movement: InventoryMovement) -> some View {
        let (label, color, icon) = statusInfo(for: movement.status)
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(label)
        }
        .font(.caption2.weight(.bold))
        .textCase(.uppercase)
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private func statusInfo(for status: MovementStatus) -> (String, Color, String) {
        switch status {
        case .requested: return ("Requested", RSMSTheme.warning, "clock.fill")
        case .approved: return ("Approved", RSMSTheme.info, "checkmark.circle")
        case .inTransit: return ("In Transit", Color(red: 43/255, green: 115/255, blue: 138/255), "truck.box.fill")
        case .received, .completed: return ("Received", RSMSTheme.success, "checkmark.seal.fill")
        case .cancelled, .exception: return ("Exception", RSMSTheme.danger, "xmark.octagon.fill")
        case .partial: return ("Partial", RSMSTheme.danger, "exclamationmark.triangle.fill")
        }
    }
}
