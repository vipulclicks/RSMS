//
//  DCShipmentDetailView.swift
//  RSMS
//
//  Detail screen for a single DC replenishment shipment.
//  Shows shipment header, line items, action buttons (Receive / Exception),
//  and a visual timeline of the shipment lifecycle.
//

import SwiftUI

struct DCShipmentDetailView: View {

    @Environment(AppViewModel.self) private var appVM
    @Bindable var vm: DCReplenishmentViewModel
    let movement: InventoryMovement

    @State private var navigateToASN = false
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
                        shipmentHeaderCard
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
        .navigationTitle(movement.asnNumber ?? "Shipment Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToASN) {
            ASNMatchingView()
                .environment(appVM)
        }
        .sheet(isPresented: $vm.showExceptionSheet) {
            exceptionSheet
        }
        .task {
            if vm.selectedLineItems.isEmpty {
                await vm.loadShipmentDetail(movement: movement, dataStore: appVM.dataStore)
            }
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Shipment Header Card

    private var shipmentHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top: ASN + Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(movement.asnNumber ?? "—")
                        .font(.title3.bold().monospaced())
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("DC Replenishment")
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }

                Spacer()

                statusBadge(movement.status)
            }

            Rectangle().fill(RSMSTheme.divider).frame(height: 0.5)

            // Info chips
            HStack(spacing: 20) {
                detailChip(label: "SOURCE", value: movement.sourceId, icon: "building.2.fill")
                if let shipped = movement.shippedAt {
                    detailChip(
                        label: "SHIPPED",
                        value: shipped.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar"
                    )
                }
                detailChip(
                    label: "EXPECTED",
                    value: "\(movement.itemsExpected ?? vm.selectedLineItems.count) items",
                    icon: "shippingbox.fill"
                )
                if let received = movement.itemsReceived {
                    detailChip(
                        label: "RECEIVED",
                        value: "\(received) items",
                        icon: "checkmark.circle.fill"
                    )
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
        let (text, color) = statusInfo(status)
        return Text(text)
            .font(.caption2.weight(.bold))
            .tracking(1.5)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func statusInfo(_ status: MovementStatus) -> (String, Color) {
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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Receive Shipment — only if in transit
            if movement.status == .inTransit || movement.status == .approved {
                Button {
                    navigateToASN = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Receive Shipment")
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

                // Report Exception
                Button {
                    vm.showExceptionSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                        Text("Report Exception")
                            .font(.headline.weight(.bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.danger.opacity(0.6))
                    }
                    .foregroundStyle(RSMSTheme.danger)
                    .padding(18)
                    .background(RSMSTheme.danger.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(RSMSTheme.danger.opacity(0.25), lineWidth: 1)
                    )
                }
            }

            // Already received message
            if movement.status == .received || movement.status == .completed {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(RSMSTheme.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shipment Received")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        if let date = movement.receivedAt {
                            Text("Received on \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                    Spacer()
                }
                .padding(16)
                .background(RSMSTheme.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(RSMSTheme.success.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
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
                    ForEach(Array(vm.selectedLineItems.enumerated()), id: \.element.id) { index, lineItem in
                        lineItemRow(lineItem)

                        if index < vm.selectedLineItems.count - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
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
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }

    private func lineItemRow(_ item: DCLineItem) -> some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: categoryIcon(item.product.category))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(RSMSTheme.gold)
            }

            // Product info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                Text(item.product.sku)
                    .font(.caption.monospaced())
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            Spacer()

            // Quantity
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.expectedQty)")
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("units")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyLineItemsView: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundStyle(RSMSTheme.textTertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text("No line items found")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Line item details are not yet available for this shipment.")
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
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SHIPMENT TIMELINE")
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
                    title: "Shipped from DC",
                    date: movement.shippedAt,
                    icon: "shippingbox.fill",
                    isCompleted: movement.shippedAt != nil,
                    isLast: false
                )
                timelineStep(
                    title: "In Transit",
                    date: movement.shippedAt,
                    icon: "truck.box.fill",
                    isCompleted: movement.status == .inTransit || movement.status == .received || movement.status == .completed || movement.status == .partial,
                    isLast: false
                )
                timelineStep(
                    title: "Received at Store",
                    date: movement.receivedAt,
                    icon: "checkmark.circle.fill",
                    isCompleted: movement.receivedAt != nil,
                    isLast: true
                )
            }
            .padding(16)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func timelineStep(title: String, date: Date?, icon: String, isCompleted: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Vertical line + dot
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? RSMSTheme.gold : RSMSTheme.border)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isCompleted ? RSMSTheme.background : RSMSTheme.textTertiary)
                }

                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? RSMSTheme.gold.opacity(0.4) : RSMSTheme.border)
                        .frame(width: 2, height: 28)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isCompleted ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)

                if let date {
                    Text(date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                } else {
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary.opacity(0.6))
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
        }
    }

    // MARK: - Exception Sheet

    private var exceptionSheet: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Report Exception")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("Describe the issue with this shipment")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }

                        // Shipment info
                        HStack(spacing: 12) {
                            Image(systemName: "shippingbox.fill")
                                .foregroundStyle(RSMSTheme.warning)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(movement.asnNumber ?? "—")
                                    .font(.subheadline.weight(.bold).monospaced())
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text("From: \(movement.sourceId)")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSTheme.border, lineWidth: 1)
                        )

                        // Notes field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EXCEPTION DETAILS")
                                .font(.caption.weight(.semibold))
                                .tracking(1.5)
                                .foregroundStyle(RSMSTheme.textTertiary)

                            TextEditor(text: $vm.exceptionNotes)
                                .frame(minHeight: 120)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(14)
                                .background(RSMSTheme.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(RSMSTheme.border, lineWidth: 1)
                                )
                        }

                        // Submit button
                        Button {
                            Task {
                                if let storeId = appVM.currentStoreId, let user = appVM.currentUser {
                                    await vm.reportException(
                                        dataStore: appVM.dataStore,
                                        user: user,
                                        storeId: storeId
                                    )
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if vm.isSubmittingException {
                                    ProgressView()
                                        .tint(RSMSTheme.background)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Submit Exception")
                                        .font(.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                vm.exceptionNotes.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? RSMSTheme.danger.opacity(0.4)
                                    : RSMSTheme.danger
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(vm.exceptionNotes.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSubmittingException)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        vm.showExceptionSheet = false
                        vm.exceptionNotes = ""
                    }
                    .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
    }

    // MARK: - Helpers

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

// MARK: - Previews

#Preview("Shipment Detail") {
    NavigationStack {
        DCShipmentDetailView(
            vm: DCReplenishmentViewModel(),
            movement: InventoryMovement(
                id: UUID(),
                type: .dcReplenishment,
                sourceId: "DC-EUROPE-01",
                destinationId: UUID().uuidString,
                status: .inTransit,
                requestedBy: nil,
                approvedBy: nil,
                requestedAt: .now.addingTimeInterval(-86400 * 3),
                shippedAt: .now.addingTimeInterval(-86400),
                receivedAt: nil,
                asnNumber: "ASN-2026-05-987654",
                itemsExpected: 15,
                itemsReceived: nil,
                reason: nil,
                notes: "Weekly replenishment — fragrances and small leather goods."
            )
        )
        .environment(AppViewModel())
    }
}
