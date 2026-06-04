//
//  OmnichannelView.swift
//  RSMS
//
//  Omnichannel fulfilment — BOPIS, Endless Aisle, and Ship From Store.
//  Segmented picker for three fulfilment modes.
//

import SwiftUI

struct OmnichannelView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel = OmnichannelScreenViewModel()
    private enum ActiveSheet: Identifiable {
        case newEndlessAisle
        case packingSlip(CheckoutSession, ShipFromStoreSlip)
        
        var id: String {
            switch self {
            case .newEndlessAisle:
                return "newEndlessAisle"
            case .packingSlip(let session, let slip):
                return "packingSlip-\(session.id)-\(slip.id)"
            }
        }
    }
    
    @State private var activeSheet: ActiveSheet? = nil

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("Fulfilment", selection: $viewModel.selectedTab) {
                    Text("Online Orders").tag(0)
                    Text("Endless Aisle").tag(1)
                    Text("Ship From Store").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                ScrollView {
                    switch viewModel.selectedTab {

                    case 0:
                        OnlineOrdersView()

                    case 1:
                        InventorySourcingRequestListView(isScrollable: false)

                    case 2:
                        shipFromStoreSection
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)

                    default:
                        OnlineOrdersView()
                    }
                }
            }
        }
        .navigationTitle("Omnichannel")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .newEndlessAisle:
                OCNewEndlessAisleSheet()
            case .packingSlip(let session, let slip):
                PackingSlipView(session: session, slip: slip)
            }
        }
        .task {
            viewModel.dataStore = appVM.dataStore
            try? await appVM.dataStore.fetchOmnichannelOrders()
            try? await appVM.dataStore.fetchShipFromStoreSlips(storeId: appVM.currentStoreId)
            try? await appVM.dataStore.fetchCheckoutSessions()
            try? await appVM.dataStore.fetchInventoryReservations()
            try? await appVM.dataStore.fetchCheckoutShippingAddresses()
        }
    }
    // MARK: - Endless Aisle Section

    private var endlessAisleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(
                    title: "Endless Aisle",
                    subtitle: "Order products not in stock locally"
                )
                Spacer()
                Button {
                    activeSheet = .newEndlessAisle
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RSMSTheme.primary)
                }
                .accessibilityLabel("New Endless Aisle Order")
            }

            let eaOrders = viewModel.endlessAisleOrders
            if eaOrders.isEmpty {
                OCEmptyState(icon: "globe", message: "No endless aisle orders")
            } else {
                ForEach(eaOrders) { order in
                    OCEndlessAisleCard(order: order, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Ship From Store Section

    private var shipFromStoreSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Ship From Store",
                subtitle: "Packing slips and shipment tracking"
            )

            let slips = viewModel.shipSlips
            if slips.isEmpty {
                OCEmptyState(icon: "shippingbox.and.arrow.backward", message: "No shipments")
            } else {
                ForEach(slips) { slip in
                    // slip.orderId references omnichannel_orders.id, not checkout_sessions.id
                    let omnichannelOrder = appVM.dataStore.omnichannelOrders.first(where: { $0.id == slip.orderId })
                    let session = omnichannelOrder.flatMap { oo in
                        appVM.dataStore.checkoutSessions.first(where: { $0.token == oo.onlineOrderId })
                        ?? appVM.dataStore.checkoutSessions.first(where: { $0.clientId == oo.clientId })
                        ?? CheckoutSession(
                            id: oo.id,
                            cartId: UUID(),
                            token: oo.onlineOrderId ?? "FALLBACK-TOKEN",
                            clientId: oo.clientId,
                            associateId: oo.associateId ?? UUID(),
                            status: oo.status == .delivered || oo.status == .shipped ? .completed : .readyForShipping,
                            fulfillmentMethod: .shipping,
                            paymentMethod: .online,
                            expiresAt: oo.createdAt,
                            createdAt: oo.createdAt,
                            updatedAt: oo.createdAt
                        )
                    }
                    OCShipSlipCard(slip: slip, viewModel: viewModel) {
                        if let s = session {
                            activeSheet = .packingSlip(s, slip)
                        } else {
                            print("[OmnichannelView] Session lookup failed for slip: \(slip.id), client: \(omnichannelOrder?.clientId.uuidString ?? "nil")")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Screen ViewModel

@Observable
private final class OmnichannelScreenViewModel {
    var selectedTab = 0
    var bopisFilter = "All"
    var dataStore: DataStore?

    var bopisOrders: [OmnichannelOrder] {
        dataStore?.omnichannelOrders.filter { $0.type == .bopis } ?? []
    }
    var endlessAisleOrders: [OmnichannelOrder] {
        dataStore?.omnichannelOrders.filter { $0.type == .endlessAisle } ?? []
    }
    var shipSlips: [ShipFromStoreSlip] {
        dataStore?.shipFromStoreSlips ?? []
    }
    var clients: [ClientProfile] {
        dataStore?.clients ?? []
    }
    var products: [Product] {
        dataStore?.products ?? []
    }

    var filteredBOPIS: [OmnichannelOrder] {
        guard bopisFilter != "All" else { return bopisOrders }
        return bopisOrders.filter { $0.status.rawValue.lowercased() == bopisFilter.lowercased() }
    }

    func clientName(for id: UUID) -> String {
        clients.first { $0.id == id }?.fullName ?? "Unknown Client"
    }

    func productName(for id: UUID?) -> String {
        guard let id else { return "Multiple Items" }
        return products.first { $0.id == id }?.name ?? "Unknown Product"
    }

    func orderStatusColor(_ status: OmnichannelOrderStatus) -> Color {
        switch status {
        case .reserved:   return RSMSTheme.info
        case .pending:    return RSMSTheme.textSecondary
        case .preparing:  return RSMSTheme.warning
        case .ready:      return RSMSTheme.info
        case .pickedUp:   return RSMSTheme.success
        case .placed:     return RSMSTheme.textSecondary
        case .confirmed:  return RSMSTheme.info
        case .shipped:    return RSMSTheme.primary
        case .delivered:  return RSMSTheme.success
        case .cancelled:  return RSMSTheme.danger
        }
    }

    func nextActionLabel(for order: OmnichannelOrder) -> String? {
        switch order.status {
        case .pending:   return "Start Preparing"
        case .preparing: return "Mark Ready"
        case .ready:     return "Mark Picked Up"
        default:         return nil
        }
    }

    func nextActionIcon(for order: OmnichannelOrder) -> String {
        switch order.status {
        case .pending:   return "hand.raised.fill"
        case .preparing: return "checkmark.circle.fill"
        case .ready:     return "bag.fill"
        default:         return "arrow.right.circle.fill"
        }
    }
}

// MARK: - BOPIS Card

private struct OCBOPISCard: View {
    let order: OmnichannelOrder
    let viewModel: OmnichannelScreenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let onlineId = order.onlineOrderId {
                    Text(onlineId)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                Spacer()
                StatusBadge(
                    text: order.status.rawValue.replacingOccurrences(of: "_", with: " "),
                    color: viewModel.orderStatusColor(order.status)
                )
            }

            Text(viewModel.clientName(for: order.clientId))
                .font(.headline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)

            Text(viewModel.productName(for: order.productId))
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)

            if let notes = order.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(2)
            }

            if let actionLabel = viewModel.nextActionLabel(for: order) {
                Button {
                    // Perform status transition
                } label: {
                    Label(actionLabel, systemImage: viewModel.nextActionIcon(for: order))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.cream)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.primaryGradient, in: Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(actionLabel)
            }
        }
        .rsmsCard()
    }
}

// MARK: - Endless Aisle Card

private struct OCEndlessAisleCard: View {
    let order: OmnichannelOrder
    let viewModel: OmnichannelScreenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.clientName(for: order.clientId))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                StatusBadge(
                    text: order.status.rawValue.replacingOccurrences(of: "_", with: " "),
                    color: viewModel.orderStatusColor(order.status)
                )
            }

            Text(viewModel.productName(for: order.productId))
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)

            Divider().overlay(RSMSTheme.divider)

            if let address = order.shippingAddress {
                Label {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } icon: {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(RSMSTheme.primary)
                }
            }

            if let delivery = order.estimatedDelivery {
                Label {
                    Text("Est. delivery: \(delivery.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } icon: {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundStyle(RSMSTheme.info)
                }
            }

            if let notes = order.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(2)
            }
        }
        .rsmsCard()
    }
}

// MARK: - Ship From Store Card

private struct OCShipSlipCard: View {
    let slip: ShipFromStoreSlip
    let viewModel: OmnichannelScreenViewModel
    var onViewSlip: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Order #\(slip.orderId.uuidString.prefix(8).uppercased())")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                Spacer()
                StatusBadge(
                    text: slip.shippedAt != nil ? "Shipped" : "Packing",
                    color: slip.shippedAt != nil ? RSMSTheme.success : RSMSTheme.warning
                )
            }

            if let tracking = slip.trackingNumber {
                Label {
                    Text(tracking)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textPrimary)
                } icon: {
                    Image(systemName: "barcode")
                        .foregroundStyle(RSMSTheme.primary)
                }
            }

            if let carrier = slip.carrier {
                Label {
                    Text(carrier)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } icon: {
                    Image(systemName: "truck.box.fill")
                        .foregroundStyle(RSMSTheme.info)
                }
            }

            HStack(spacing: 12) {
                Text(slip.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)

                Spacer()

                Button {
                    onViewSlip?()
                } label: {
                    Label("View Packing Slip", systemImage: "doc.text.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .rsmsCard()
    }
}

// MARK: - Filter Chip

private struct OCFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? AnyShapeStyle(RSMSTheme.primaryGradient) : AnyShapeStyle(RSMSTheme.surfacePrimary),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Filter: \(label)")
    }
}

// MARK: - Empty State

private struct OCEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .rsmsCard()
    }
}

// MARK: - New Endless Aisle Sheet

private struct OCNewEndlessAisleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var clientName = ""
    @State private var productName = ""
    @State private var shippingAddress = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        LuxuryFormCard(title: "Endless Aisle Order", icon: "globe") {
                            LuxuryTextField(title: "Client Name", text: $clientName)
                            LuxuryTextField(title: "Product", text: $productName)
                            LuxuryTextField(title: "Shipping Address", text: $shippingAddress)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                TextEditor(text: $notes)
                                    .frame(minHeight: 60)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(RSMSTheme.border, lineWidth: 1))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Place Order")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.cream)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RSMSTheme.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Endless Aisle Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OmnichannelView()
    }
}
