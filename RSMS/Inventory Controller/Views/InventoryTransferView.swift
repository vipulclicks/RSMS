//
//  InventoryTransferView.swift
//  RSMS
//
//  Premium Inventory Transfer screen for the Inventory Controller module.
//  Manages store-to-store transfers with hero KPIs, mini cards,
//  availability table, create form, and activity feed.
//  Follows the luxury beige-maroon RSMSTheme design language.
//

import SwiftUI

struct InventoryTransferView: View {

    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var vm = InventoryTransferViewModel()
    @State private var appeared = false
    @State private var showAvailability = true

    private var columns: [GridItem] {
        if sizeClass == .compact {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if vm.isLoading && vm.movements.isEmpty {
                    loadingView
                } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 24) {
                                headerSection
                                heroOverviewCard
                                miniCardsSection
                                createTransferButton
                                availabilitySection
                                recentTransfersSection
                            }
                            .padding(24)
                            .padding(.bottom, 24)
                    }
                }
            }

            // Success overlay
            if vm.showSuccess {
                successOverlay
            }
        }
        .navigationTitle("Transfer Inventory")
        .navigationBarTitleDisplayMode(.inline)

        .sheet(isPresented: $vm.showCreateSheet) {
            createTransferSheet
        }
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
            Text("Loading transfers…")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Transfer Inventory")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Manage store-to-store inventory transfers")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 1. Hero Overview Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var heroOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRANSFERS TODAY")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(RSMSTheme.gold)

                    Text("\(vm.todayTransfers)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.gold)
                }

                Spacer()

                Image(systemName: "arrow.left.arrow.right")
                    .font(.title)
                    .foregroundStyle(RSMSTheme.gold.opacity(0.4))
                    .padding(12)
                    .background(RSMSTheme.gold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Rectangle()
                .fill(RSMSTheme.divider)
                .frame(height: 1)

            // Stats row
            HStack(spacing: 0) {
                heroStatColumn(value: "\(vm.pendingCount)", label: "PENDING", color: RSMSTheme.warning)
                Spacer()
                heroStatColumn(value: "\(vm.inTransitCount)", label: "IN TRANSIT", color: RSMSTheme.info)
                Spacer()
                heroStatColumn(value: "\(vm.completedCount)", label: "COMPLETED", color: RSMSTheme.success)
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.gold.opacity(0.2), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(0.05), value: appeared)
    }

    private func heroStatColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 2. Mini Cards
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var miniCardsSection: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            miniCard(
                icon: "exclamationmark.triangle.fill",
                title: "Urgent Transfers",
                value: "\(vm.urgentCount)",
                color: RSMSTheme.danger
            )
            miniCard(
                icon: "arrow.triangle.swap",
                title: "Stock Balancing",
                value: "\(vm.availabilityRows.filter { $0.recommendedQty > 0 }.count)",
                color: RSMSTheme.info
            )
            miniCard(
                icon: "clock.badge.checkmark.fill",
                title: "Approval Pending",
                value: "\(vm.approvalPendingCount)",
                color: RSMSTheme.warning
            )
            miniCard(
                icon: "hourglass.bottomhalf.filled",
                title: "Transfer Delays",
                value: "\(vm.delayedCount)",
                color: RSMSTheme.gold
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    private func miniCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Create Transfer Button
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var createTransferButton: some View {
        Button {
            vm.resetForm()
            vm.showCreateSheet = true
        } label: {
            HStack(spacing: 10) {
                Text("Create New Transfer")
                    .font(.headline.weight(.bold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.background.opacity(0.6))
            }
            .foregroundStyle(RSMSTheme.background)
            .padding(18)
            .background(RSMSTheme.gold)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 4. Inventory Availability
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showAvailability.toggle()
                }
            } label: {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inventory Availability")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        if let src = vm.sourceStore, let dst = vm.destinationStore {
                            Text("Comparing stock between \(shortStoreName(for: src)) and \(shortStoreName(for: dst))")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        } else {
                            Text("Select source and destination stores to compare stock")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                    Spacer()
                    Image(systemName: showAvailability ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if showAvailability {
                VStack(spacing: 0) {
                    // Store Pickers in main view
                    HStack(spacing: 16) {
                        Menu {
                            ForEach(vm.stores) { store in
                                Button(store.name) {
                                    vm.sourceStore = store
                                }
                            }
                        } label: {
                            HStack {
                                Text(vm.sourceStore != nil ? shortStoreName(for: vm.sourceStore) : "Select Source")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(vm.sourceStore != nil ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                            .padding(12)
                            .background(RSMSTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.caption.bold())
                            .foregroundStyle(RSMSTheme.textTertiary)
                        
                        Menu {
                            ForEach(vm.stores.filter { $0.id != vm.sourceStore?.id }) { store in
                                Button(store.name) {
                                    vm.destinationStore = store
                                }
                            }
                        } label: {
                            HStack {
                                Text(vm.destinationStore != nil ? shortStoreName(for: vm.destinationStore) : "Select Destination")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(vm.destinationStore != nil ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                            .padding(12)
                            .background(RSMSTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(16)
                    .background(RSMSTheme.surfacePrimary)

                    if vm.availabilityRows.isEmpty {
                        emptyAvailabilityView
                    } else {
                        VStack(spacing: 0) {
                            if sizeClass != .compact {
                                // Column header
                                HStack(spacing: 0) {
                                    Text("PRODUCT")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(vm.sourceStore != nil ? shortStoreName(for: vm.sourceStore).uppercased() : "AT SOURCE")
                                        .frame(width: 160, alignment: .leading)
                                        .lineLimit(1)
                                    Text(vm.destinationStore != nil ? shortStoreName(for: vm.destinationStore).uppercased() : "AT DEST")
                                        .frame(width: 160, alignment: .leading)
                                        .lineLimit(1)
                                    Text("RECOMMENDED")
                                        .frame(width: 140, alignment: .leading)
                                    Text("STATUS")
                                        .frame(width: 80, alignment: .leading)
                                }
                                .font(.caption.weight(.semibold))
                                .tracking(1.5)
                                .foregroundStyle(RSMSTheme.gold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(RSMSTheme.surfaceSecondary)
                            }

                            ForEach(Array(vm.availabilityRows.enumerated()), id: \.element.id) { index, row in
                                if sizeClass == .compact {
                                    availabilityRowCompact(row)
                                } else {
                                    availabilityRow(row)
                                }

                                if index < vm.availabilityRows.count - 1 {
                                    Rectangle()
                                        .fill(RSMSTheme.divider)
                                        .frame(height: 0.5)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func availabilityRowCompact(_ row: InventoryTransferViewModel.AvailabilityRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Product Name and Status
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.product.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                    Text(row.product.sku)
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                Spacer(minLength: 8)
                statusBadge(for: row)
            }
            
            // Stock details
            HStack(spacing: 0) {
                // Source
                VStack(alignment: .leading, spacing: 2) {
                    Text("SOURCE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("\(row.sourceStock)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(row.isLowStock ? RSMSTheme.danger : RSMSTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Destination
                VStack(alignment: .leading, spacing: 2) {
                    Text("DEST")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("\(row.destStock)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Recommended
                VStack(alignment: .trailing, spacing: 2) {
                    Text("RECOM.")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(row.recommendedQty > 0 ? "\(row.recommendedQty)" : "—")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(row.recommendedQty > 0 ? RSMSTheme.info : RSMSTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func availabilityRow(_ row: InventoryTransferViewModel.AvailabilityRow) -> some View {
        HStack(spacing: 0) {
            // Product
            VStack(alignment: .leading, spacing: 2) {
                Text(row.product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                Text(row.product.sku)
                    .font(.caption.monospaced())
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Source stock
            Text("\(row.sourceStock)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(row.isLowStock ? RSMSTheme.danger : RSMSTheme.textPrimary)
                .frame(width: 160, alignment: .leading)

            // Dest stock
            Text("\(row.destStock)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RSMSTheme.textSecondary)
                .frame(width: 160, alignment: .leading)

            // Recommended
            Text(row.recommendedQty > 0 ? "\(row.recommendedQty)" : "—")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(row.recommendedQty > 0 ? RSMSTheme.info : RSMSTheme.textTertiary)
                .frame(width: 140, alignment: .leading)

            // Status badge
            statusBadge(for: row)
                .frame(width: 80, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func statusBadge(for row: InventoryTransferViewModel.AvailabilityRow) -> some View {
        let (text, color): (String, Color) = {
            if row.isLowStock {
                return ("Low", RSMSTheme.danger)
            } else if row.recommendedQty > 0 {
                return ("Restock", RSMSTheme.warning)
            } else {
                return ("OK", RSMSTheme.success)
            }
        }()

        return Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var emptyAvailabilityView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(RSMSTheme.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("All stock levels balanced")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("No transfers recommended at this time")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.success.opacity(0.25), lineWidth: 1)
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 5. Recent Transfers Feed
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var recentTransfersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT TRANSFERS")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(vm.recentTransfers.count) total")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            if vm.recentTransfers.isEmpty {
                emptyTransfersView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.recentTransfers.prefix(8).enumerated()), id: \.element.id) { index, transfer in
                        transferFeedRow(transfer)

                        if index < min(vm.recentTransfers.count, 8) - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
    }

    private func transferFeedRow(_ transfer: InventoryMovement) -> some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(transferStatusColor(transfer.status).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: transferStatusIcon(transfer.status))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(transferStatusColor(transfer.status))
            }

            VStack(alignment: .leading, spacing: 3) {
                // Source → Destination
                HStack(spacing: 4) {
                    Text(shortenStoreName(transfer.sourceId))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(RSMSTheme.gold)
                    Text(shortenStoreName(transfer.destinationId))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }

                // Product & Qty
                if let reason = transfer.reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if let qty = transfer.itemsExpected {
                        Text("\(qty) units")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    if let date = transfer.requestedAt {
                        Text(date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }

            Spacer(minLength: 0)

            // Status badge
            Text(transfer.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(transferStatusColor(transfer.status))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(transferStatusColor(transfer.status).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var emptyTransfersView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                    .foregroundStyle(RSMSTheme.gold)
            }
            Text("No transfers yet")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Create your first store-to-store transfer.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 3. Create Transfer Sheet
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var createTransferSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Transfer ID
                    formRow(label: "TRANSFER ID") {
                        HStack {
                            Text(vm.transferId)
                                .font(.subheadline.weight(.bold).monospaced())
                                .foregroundStyle(RSMSTheme.gold)
                            Spacer()
                            Image(systemName: "barcode.viewfinder")
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }

                    // Source Store
                    formRow(label: "SOURCE STORE") {
                        Menu {
                            ForEach(vm.stores) { store in
                                Button(store.name) {
                                    vm.sourceStore = store
                                }
                            }
                        } label: {
                            HStack {
                                Text(vm.sourceStore?.name ?? "Select store…")
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        vm.sourceStore != nil ? RSMSTheme.textPrimary : RSMSTheme.textTertiary
                                    )
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                    }

                    // Destination Store
                    formRow(label: "DESTINATION STORE") {
                        Menu {
                            ForEach(vm.stores.filter { $0.id != vm.sourceStore?.id }) { store in
                                Button(store.name) {
                                    vm.destinationStore = store
                                }
                            }
                        } label: {
                            HStack {
                                Text(vm.destinationStore?.name ?? "Select store…")
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        vm.destinationStore != nil ? RSMSTheme.textPrimary : RSMSTheme.textTertiary
                                    )
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                    }

                    // Add Product
                    formRow(label: "ADD PRODUCT") {
                        VStack(spacing: 16) {
                            // Search Bar
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                    TextField("Search by name or SKU…", text: $vm.productSearchText)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .font(.subheadline)
                                }

                                if let p = vm.selectedProduct {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(RSMSTheme.success)
                                        Text(p.name)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Text(p.sku)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(RSMSTheme.gold)
                                        Spacer()
                                        Button {
                                            vm.selectedProduct = nil
                                            vm.productSearchText = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(RSMSTheme.textTertiary)
                                        }
                                    }
                                    .padding(10)
                                    .background(RSMSTheme.success.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                if !vm.searchResults.isEmpty && vm.selectedProduct == nil {
                                    VStack(spacing: 0) {
                                        ForEach(vm.searchResults) { product in
                                            searchResultRow(for: product, stock: vm.stockForProduct(product))
                                        }
                                    }
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(RSMSTheme.border, lineWidth: 1)
                                    )
                                }
                            }

                            if vm.selectedProduct != nil {
                                Divider()

                                // Quantity Stepper & Add Button
                                VStack(spacing: 12) {
                                    HStack(spacing: 16) {
                                        Text("Quantity")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                        Spacer()
                                        
                                        Button {
                                            if vm.quantity > 1 { vm.quantity -= 1 }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(vm.availableStock == 0 ? RSMSTheme.textTertiary.opacity(0.5) : RSMSTheme.textSecondary)
                                        }
                                        .disabled(vm.availableStock == 0)

                                        Text("\(vm.quantity)")
                                            .font(.title2.bold())
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .frame(minWidth: 40, alignment: .center)

                                        Button {
                                            vm.quantity += 1
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(vm.availableStock == 0 ? RSMSTheme.textTertiary.opacity(0.5) : RSMSTheme.textSecondary)
                                        }
                                        .disabled(vm.availableStock == 0)
                                    }

                                    HStack(spacing: 4) {
                                        Image(systemName: "shippingbox.fill")
                                            .font(.caption2)
                                        Text("\(vm.availableStock) available at \(shortStoreName(for: vm.sourceStore))")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .foregroundStyle(vm.availableStock < vm.quantity ? RSMSTheme.danger : RSMSTheme.success)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                    if vm.availableStock > 0 && vm.availableStock < vm.quantity {
                                        HStack(spacing: 4) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.caption2)
                                            Text("Requested quantity exceeds available stock")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(RSMSTheme.danger)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(RSMSTheme.danger.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    Button {
                                        guard let safeProduct = vm.selectedProduct else { return }
                                        guard vm.availableStock >= vm.quantity else { return }
                                        
                                        withAnimation(.spring()) {
                                            // If already in cart, update quantity
                                            if let index = vm.transferCart.firstIndex(where: { $0.product.id == safeProduct.id }) {
                                                vm.transferCart[index].quantity += vm.quantity
                                            } else {
                                                vm.transferCart.append(TransferItem(product: safeProduct, quantity: vm.quantity))
                                            }
                                            vm.selectedProduct = nil
                                            vm.quantity = 1
                                        }
                                    } label: {
                                        Text("Add to Transfer")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.background)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(RSMSTheme.gold) 
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .disabled(vm.availableStock < vm.quantity || vm.availableStock == 0)
                                    .opacity(vm.availableStock < vm.quantity || vm.availableStock == 0 ? 0.5 : 1)
                                }
                            }
                        }
                    }

                    // Transfer Cart List
                    if !vm.transferCart.isEmpty {
                        formRow(label: "TRANSFER CART (\(vm.transferCart.count))") {
                            VStack(spacing: 8) {
                                ForEach(vm.transferCart) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.product.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(RSMSTheme.textPrimary)
                                            Text(item.product.sku)
                                                .font(.caption.monospaced())
                                                .foregroundStyle(RSMSTheme.textTertiary)
                                        }
                                        Spacer()
                                        Text("\(item.quantity)")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(RSMSTheme.surfaceSecondary)
                                            .clipShape(Capsule())
                                        
                                        Button {
                                            withAnimation(.spring()) {
                                                vm.transferCart.removeAll { $0.id == item.id }
                                            }
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.danger)
                                                .padding(8)
                                                .background(RSMSTheme.danger.opacity(0.1))
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    
                                    if item.id != vm.transferCart.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    // Transfer Preview Summary
                    if let src = vm.sourceStore, let dst = vm.destinationStore, !vm.transferCart.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(RSMSTheme.gold)
                                Text("Transfer Preview Summary")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(RSMSTheme.gold)
                            }
                            
                            VStack(spacing: 8) {
                                previewRow(label: "From", value: src.name)
                                previewRow(label: "To", value: dst.name)
                                let totalItems = vm.transferCart.reduce(0) { $0 + $1.quantity }
                                previewRow(label: "Unique Products", value: "\(vm.transferCart.count)")
                                previewRow(label: "Total Items", value: "\(totalItems)")
                                previewRow(label: "ETA", value: vm.expectedDate.formatted(.dateTime.day().month().year()))
                            }
                        }
                        .padding(16)
                        .background(RSMSTheme.gold.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSTheme.gold.opacity(0.2), lineWidth: 1)
                        )
                    }

                    // Priority chips
                    formRow(label: "PRIORITY") {
                        HStack(spacing: 8) {
                            ForEach(TransferPriority.allCases) { p in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        vm.priority = p
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: p.icon)
                                            .font(.system(size: 10, weight: .bold))
                                        Text(p.rawValue)
                                            .font(.caption.weight(.bold))
                                    }
                                    .foregroundStyle(vm.priority == p ? RSMSTheme.background : p.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(vm.priority == p ? p.color : p.color.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Expected Delivery Date
                    formRow(label: "EXPECTED DELIVERY") {
                        DatePicker(
                            "",
                            selection: $vm.expectedDate,
                            in: Date.now...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .tint(RSMSTheme.gold)
                    }

                    // Notes
                    formRow(label: "NOTES / REASON") {
                        TextEditor(text: $vm.transferNotes)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 70)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await vm.submitTransfer(
                                    dataStore: appVM.dataStore,
                                    requestedBy: appVM.currentUser?.id
                                )
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if vm.isSubmitting {
                                    ProgressView().tint(RSMSTheme.background)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Initiate Transfer")
                                        .font(.headline.weight(.bold))
                                }
                            }
                            .foregroundStyle(RSMSTheme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(
                            vm.isSubmitting ||
                            vm.sourceStore == nil ||
                            vm.destinationStore == nil ||
                            vm.sourceStore?.id == vm.destinationStore?.id ||
                            vm.transferCart.isEmpty
                        )
                        .opacity(
                            (vm.sourceStore == nil || vm.destinationStore == nil || vm.sourceStore?.id == vm.destinationStore?.id || vm.transferCart.isEmpty) ? 0.5 : 1
                        )
                    }
                }
                .padding(24)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CREATE TRANSFER")
                        .font(.system(.headline, design: .serif, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { vm.showCreateSheet = false }
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
        }
    }

    // Form row helper
    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.textTertiary)

            content()
                .padding(14)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Success Overlay
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.spring()) { vm.showSuccess = false }
                }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.success.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(RSMSTheme.success)
                        .symbolEffect(.bounce, value: vm.showSuccess)
                }

                VStack(spacing: 8) {
                    Text("Transfer Initiated")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Your inventory transfer request has been submitted successfully.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("TRANSFER ID")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text(vm.transferId)
                            .font(.subheadline.weight(.bold).monospaced())
                            .foregroundStyle(RSMSTheme.gold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RSMSTheme.surfaceSecondary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(spacing: 4) {
                        Text("STATUS")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text("Requested")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RSMSTheme.warning)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RSMSTheme.surfaceSecondary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    withAnimation(.spring()) { vm.showSuccess = false }
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(RSMSTheme.success))
                }
                .padding(.top, 4)
            }
            .padding(32)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .background(RSMSTheme.background.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func transferStatusColor(_ status: MovementStatus) -> Color {
        switch status {
        case .requested:  return RSMSTheme.warning
        case .approved:   return RSMSTheme.info
        case .inTransit:  return RSMSTheme.info
        case .received:   return RSMSTheme.success
        case .completed:  return RSMSTheme.success
        case .cancelled:  return RSMSTheme.textTertiary
        case .partial:    return RSMSTheme.warning
        case .exception:  return RSMSTheme.danger
        }
    }

    private func transferStatusIcon(_ status: MovementStatus) -> String {
        switch status {
        case .requested:  return "clock.fill"
        case .approved:   return "checkmark.circle"
        case .inTransit:  return "shippingbox.and.arrow.backward.fill"
        case .received:   return "checkmark.seal.fill"
        case .completed:  return "checkmark.seal.fill"
        case .cancelled:  return "xmark.circle"
        case .partial:    return "exclamationmark.circle"
        case .exception:  return "exclamationmark.triangle.fill"
        }
    }

    private func shortenStoreName(_ storeIdOrName: String) -> String {
        // Try to find store by UUID
        if let uuid = UUID(uuidString: storeIdOrName),
           let store = vm.stores.first(where: { $0.id == uuid }) {
            // Return city name or short version
            return store.city
        }
        // If it's a DC or vendor ID, return as-is
        if storeIdOrName.count > 12 {
            return String(storeIdOrName.prefix(10)) + "…"
        }
        return storeIdOrName
    }

    private func shortStoreName(for store: Store?) -> String {
        guard let name = store?.name else { return "—" }
        // If name has an em-dash, take the part before it
        if let dashIndex = name.firstIndex(of: "—") {
            return String(name[..<dashIndex]).trimmingCharacters(in: .whitespaces)
        }
        // Fallback to normal dash
        if let dashIndex = name.firstIndex(of: "-") {
            return String(name[..<dashIndex]).trimmingCharacters(in: .whitespaces)
        }
        return name
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption.weight(.bold))
                .foregroundStyle(RSMSTheme.textSecondary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func searchResultRow(for product: Product, stock: Int) -> some View {
        Button {
            if stock > 0 {
                withAnimation {
                    vm.selectedProduct = product
                    vm.productSearchText = ""
                }
            }
        } label: {
            HStack {
                Text(product.name)
                    .font(.caption.weight(.medium))
                    .strikethrough(stock == 0)
                    .foregroundStyle(stock > 0 ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                Spacer()
                if stock == 0 {
                    Text("Out of Stock")
                        .font(.caption2.bold())
                        .foregroundStyle(RSMSTheme.danger)
                } else {
                    Text(product.sku)
                        .font(.caption2.monospaced())
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .disabled(stock == 0)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InventoryTransferView()
    }
    .environment(AppViewModel())
}
