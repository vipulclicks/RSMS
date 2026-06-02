//
//  DCReplenishmentView.swift
//  RSMS
//
//  Dashboard for tracking DC-to-Store replenishment shipments.
//  Sections: Header, Hero KPI, Mini Cards, Pending Shipments, Recent Receipts.
//  Follows the luxury beige-maroon RSMSTheme design language.
//

import SwiftUI

struct DCReplenishmentView: View {

    @Environment(AppViewModel.self) private var appVM
    @State private var vm = DCReplenishmentViewModel()
    @State private var appeared = false
    @State private var navigateToDetail = false
    @State private var navigateToASN = false

    private let kpiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                if vm.isLoading && vm.movements.isEmpty {
                    loadingView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            headerSection
                            heroKPICard
                            miniCardsSection
                            pendingShipmentsSection
                            recentReceiptsSection
                        }
                        .padding(24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("DC Replenishment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToDetail) {
                if let shipment = vm.selectedShipment {
                    DCShipmentDetailView(vm: vm, movement: shipment)
                }
            }
            .navigationDestination(isPresented: $navigateToASN) {
                ASNMatchingView()
                    .environment(appVM)
            }
            .task {
                await vm.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            }
            .refreshable {
                await vm.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
            }
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
        VStack(alignment: .leading, spacing: 6) {
            Text("DC Replenishment")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Track and receive shipments from Distribution Centers")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    // MARK: - Hero KPI Card

    private var heroKPICard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INCOMING SHIPMENTS")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(RSMSTheme.gold)

                    Text("\(vm.totalIncoming)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.gold)
                }

                Spacer()

                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.title)
                    .foregroundStyle(RSMSTheme.gold.opacity(0.4))
                    .padding(12)
                    .background(RSMSTheme.gold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Rectangle()
                .fill(RSMSTheme.divider)
                .frame(height: 1)

            // Progress + stats
            HStack(spacing: 12) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(RSMSTheme.gold.opacity(0.15), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: vm.receiptCompletionPercent)
                        .stroke(
                            RSMSTheme.gold,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: vm.receiptCompletionPercent)

                    Text("\(Int(vm.receiptCompletionPercent * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(RSMSTheme.gold)
                }
                .frame(width: 44, height: 44)

                // Stat columns
                HStack(spacing: 0) {
                    heroStatColumn(value: "\(vm.inTransitCount)", label: "IN TRANSIT", color: RSMSTheme.warning)
                    Spacer()
                    heroStatColumn(value: "\(vm.receivedCount)", label: "RECEIVED", color: RSMSTheme.success)
                    Spacer()
                    heroStatColumn(value: "\(vm.exceptionCount + vm.partialCount)", label: "EXCEPTIONS", color: RSMSTheme.danger)
                }
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

    // MARK: - Mini KPI Cards

    private var miniCardsSection: some View {
        LazyVGrid(columns: kpiColumns, spacing: 12) {
            miniCard(
                icon: "cube.box.fill",
                title: "Items Expected",
                value: "\(vm.itemsExpectedToday)",
                color: RSMSTheme.info
            )
            miniCard(
                icon: "clock.badge.exclamationmark.fill",
                title: "Pending Receipt",
                value: "\(vm.inTransitCount)",
                color: RSMSTheme.warning
            )
            miniCard(
                icon: "exclamationmark.triangle.fill",
                title: "Partial Deliveries",
                value: "\(vm.partialCount)",
                color: RSMSTheme.danger
            )
            miniCard(
                icon: "checkmark.seal.fill",
                title: "Completed (7d)",
                value: "\(vm.completedThisWeek)",
                color: RSMSTheme.success
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

    // MARK: - Pending Shipments

    private var pendingShipmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PENDING SHIPMENTS")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(vm.pendingShipments.count) awaiting")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            if vm.pendingShipments.isEmpty {
                emptyPendingView
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.pendingShipments) { shipment in
                        pendingShipmentCard(shipment)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }

    private func pendingShipmentCard(_ shipment: InventoryMovement) -> some View {
        Button {
            Task {
                await vm.loadShipmentDetail(movement: shipment, dataStore: appVM.dataStore)
                navigateToDetail = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                // Top row: ASN + Status badge
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(shipment.asnNumber ?? "No ASN")
                            .font(.subheadline.weight(.bold).monospaced())
                            .foregroundStyle(RSMSTheme.gold)

                        Text("From: \(shipment.sourceId)")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    Spacer()

                    shipmentStatusBadge(shipment.status)
                }

                Rectangle()
                    .fill(RSMSTheme.divider)
                    .frame(height: 0.5)

                // Bottom row: details
                HStack(spacing: 20) {
                    if let shipped = shipment.shippedAt {
                        infoChip(
                            label: "SHIPPED",
                            value: shipped.formatted(date: .abbreviated, time: .omitted)
                        )
                    }

                    infoChip(
                        label: "ITEMS",
                        value: "\(shipment.itemsExpected ?? 0) expected"
                    )

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            .padding(18)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.warning.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func infoChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .lineLimit(1)
        }
    }

    private func shipmentStatusBadge(_ status: MovementStatus) -> some View {
        let (text, color) = statusDisplay(status)
        return Text(text)
            .font(.caption2.weight(.bold))
            .tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func statusDisplay(_ status: MovementStatus) -> (String, Color) {
        switch status {
        case .requested:  return ("REQUESTED", RSMSTheme.textTertiary)
        case .approved:   return ("APPROVED", RSMSTheme.info)
        case .inTransit:  return ("IN TRANSIT", RSMSTheme.warning)
        case .received:   return ("RECEIVED", RSMSTheme.success)
        case .completed:  return ("COMPLETED", RSMSTheme.success)
        case .cancelled:  return ("CANCELLED", RSMSTheme.textTertiary)
        case .partial:    return ("PARTIAL", RSMSTheme.danger)
        case .exception:  return ("EXCEPTION", RSMSTheme.danger)
        }
    }

    private var emptyPendingView: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.success.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(RSMSTheme.success)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("All caught up!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("No pending DC shipments to receive")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.success.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Recent Receipts Feed

    private var recentReceiptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT RECEIPTS")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(vm.recentReceipts.count) total")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            if vm.recentReceipts.isEmpty {
                emptyReceiptsView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.recentReceipts.prefix(6).enumerated()), id: \.element.id) { index, receipt in
                        receiptFeedRow(receipt)

                        if index < min(vm.recentReceipts.count, 6) - 1 {
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
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func receiptFeedRow(_ receipt: InventoryMovement) -> some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusDisplay(receipt.status).1.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: receiptIcon(receipt.status))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(statusDisplay(receipt.status).1)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(receipt.asnNumber ?? "No ASN")
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundStyle(RSMSTheme.textPrimary)

                    Text("from \(receipt.sourceId)")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }

                HStack(spacing: 8) {
                    if let expected = receipt.itemsExpected, let received = receipt.itemsReceived {
                        Text("\(received)/\(expected) items")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(received == expected ? RSMSTheme.success : RSMSTheme.warning)
                    } else if let expected = receipt.itemsExpected {
                        Text("\(expected) items expected")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    if let date = receipt.receivedAt {
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }

            Spacer(minLength: 0)

            shipmentStatusBadge(receipt.status)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func receiptIcon(_ status: MovementStatus) -> String {
        switch status {
        case .received, .completed: return "checkmark.circle.fill"
        case .partial:              return "exclamationmark.circle.fill"
        case .exception:            return "xmark.circle.fill"
        default:                    return "shippingbox.fill"
        }
    }

    private var emptyReceiptsView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.title2)
                    .foregroundStyle(RSMSTheme.gold)
            }
            Text("No receipts yet")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Received DC shipments will appear here.")
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
}

// MARK: - Previews

#Preview {
    DCReplenishmentView()
        .environment(AppViewModel())
}
