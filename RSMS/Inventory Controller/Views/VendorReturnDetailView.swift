//
//  VendorReturnDetailView.swift
//  RSMS
//
//  Detail view for a single Vendor Return.
//  Shows line items, timeline, and actions to ship or complete the return.
//

import SwiftUI

struct VendorReturnDetailView: View {

    @Environment(AppViewModel.self) private var appVM
    @Bindable var vm: VendorReturnViewModel
    let movement: InventoryMovement

    @State private var appeared = false

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            if vm.isLoadingDetail {
                ProgressView()
                    .tint(RSMSTheme.gold)
                    .scaleEffect(1.3)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerCard
                        actionButtons
                        lineItemsSection
                        timelineSection
                        notesSection
                    }
                    .padding(24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle(movement.reason ?? "Return Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if vm.selectedLineItems.isEmpty {
                await vm.loadReturnDetail(movement: movement, dataStore: appVM.dataStore)
            }
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(movement.reason ?? "Return")
                        .font(.title3.bold())
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Vendor Return")
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                Spacer()
                statusBadge(movement.status)
            }

            Rectangle().fill(RSMSTheme.divider).frame(height: 0.5)

            HStack(spacing: 20) {
                detailChip(label: "VENDOR", value: movement.destinationId, icon: "building.2.fill")
                if let requested = movement.requestedAt {
                    detailChip(
                        label: "REQUESTED",
                        value: requested.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar"
                    )
                }
                detailChip(
                    label: "ITEMS",
                    value: "\(movement.itemsExpected ?? vm.selectedLineItems.count)",
                    icon: "shippingbox.fill"
                )
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(0.05), value: appeared)
    }

    private func detailChip(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.gold)
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .lineLimit(1)
        }
    }

    private func statusBadge(_ status: MovementStatus) -> some View {
        let (text, color) = statusDisplay(status)
        return Text(text)
            .font(.caption2.weight(.bold))
            .tracking(1.5)
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
        case .inTransit:  return ("SHIPPED", RSMSTheme.warning)
        case .received, .completed: return ("COMPLETED", RSMSTheme.success)
        case .cancelled:  return ("CANCELLED", RSMSTheme.textTertiary)
        case .partial:    return ("PARTIAL", RSMSTheme.danger)
        case .exception:  return ("EXCEPTION", RSMSTheme.danger)
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionButtons: some View {
        if movement.status == .requested || movement.status == .approved {
            Button {
                Task {
                    if let user = appVM.currentUser, let storeId = appVM.currentStoreId {
                        await vm.updateStatus(for: movement.id, to: .inTransit, dataStore: appVM.dataStore, user: user, storeId: storeId)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if vm.isUpdatingStatus {
                        ProgressView().tint(RSMSTheme.background)
                    } else {
                        Image(systemName: "box.truck.fill").font(.title3)
                    }
                    Text("Ship Return")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.background.opacity(0.6))
                }
                .foregroundStyle(RSMSTheme.background)
                .padding(18)
                .background(RSMSTheme.info)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(vm.isUpdatingStatus)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
            
        } else if movement.status == .inTransit {
            Button {
                Task {
                    if let user = appVM.currentUser, let storeId = appVM.currentStoreId {
                        await vm.updateStatus(for: movement.id, to: .completed, dataStore: appVM.dataStore, user: user, storeId: storeId)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if vm.isUpdatingStatus {
                        ProgressView().tint(RSMSTheme.background)
                    } else {
                        Image(systemName: "checkmark.seal.fill").font(.title3)
                    }
                    Text("Mark as Completed (Acknowledged by Vendor)")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.background.opacity(0.6))
                }
                .foregroundStyle(RSMSTheme.background)
                .padding(18)
                .background(RSMSTheme.success)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(vm.isUpdatingStatus)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
        }
    }

    // MARK: - Line Items

    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LINE ITEMS")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(vm.selectedLineItems.count) products")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            if vm.selectedLineItems.isEmpty {
                emptyLineItemsView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.selectedLineItems.enumerated()), id: \.element.id) { index, item in
                        lineItemRow(item)
                        if index < vm.selectedLineItems.count - 1 {
                            Rectangle().fill(RSMSTheme.divider).frame(height: 0.5).padding(.horizontal, 16)
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }

    private func lineItemRow(_ item: ReturnItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(RSMSTheme.gold.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: categoryIcon(item.product.category)).font(.system(size: 18, weight: .medium)).foregroundStyle(RSMSTheme.gold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.product.name).font(.subheadline.weight(.semibold)).foregroundStyle(RSMSTheme.textPrimary).lineLimit(1)
                Text("Reason: \(item.reason.rawValue)")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Text(item.product.sku).font(.caption2.monospaced()).foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.quantity)").font(.title3.bold()).foregroundStyle(RSMSTheme.textPrimary)
                Text("units").font(.caption2).foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyLineItemsView: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text").font(.title2).foregroundStyle(RSMSTheme.textTertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text("No line items found").font(.subheadline.weight(.semibold)).foregroundStyle(RSMSTheme.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.border, lineWidth: 1))
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RETURN TIMELINE")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.gold)

            VStack(spacing: 0) {
                timelineStep(
                    title: "Requested",
                    date: movement.requestedAt,
                    icon: "doc.badge.plus",
                    isCompleted: movement.requestedAt != nil,
                    isLast: false
                )
                timelineStep(
                    title: "Shipped to Vendor",
                    date: movement.shippedAt,
                    icon: "box.truck.fill",
                    isCompleted: movement.status == .inTransit || movement.status == .completed || movement.status == .received,
                    isLast: false
                )
                timelineStep(
                    title: "Completed (Vendor Acknowledged)",
                    date: movement.receivedAt,
                    icon: "checkmark.seal.fill",
                    isCompleted: movement.status == .completed || movement.status == .received,
                    isLast: true
                )
            }
            .padding(16)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func timelineStep(title: String, date: Date?, icon: String, isCompleted: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(isCompleted ? RSMSTheme.gold : RSMSTheme.border).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(isCompleted ? RSMSTheme.background : RSMSTheme.textTertiary)
                }
                if !isLast {
                    Rectangle().fill(isCompleted ? RSMSTheme.gold.opacity(0.4) : RSMSTheme.border).frame(width: 2, height: 28)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(isCompleted ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                if let date {
                    Text(date.formatted(.dateTime.month(.abbreviated).day().hour().minute())).font(.caption).foregroundStyle(RSMSTheme.textTertiary)
                } else {
                    Text("Pending").font(.caption).foregroundStyle(RSMSTheme.textTertiary.opacity(0.6))
                }
            }
            .padding(.top, 4)
            Spacer()
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        if let notes = movement.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("NOTES")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)

                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.border, lineWidth: 1))
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "handbags", "leather goods": return "handbag.fill"
        case "watches":                    return "watch.analog"
        case "shoes", "heels":             return "shoe.fill"
        case "jewelry", "jewellery":       return "sparkles"
        case "accessories":                return "eyeglasses"
        case "fragrances":                 return "bubbles.and.sparkles"
        default:                           return "shippingbox.fill"
        }
    }
}
