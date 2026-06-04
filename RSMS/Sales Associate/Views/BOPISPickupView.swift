import SwiftUI
import Foundation

// MARK: - BOPIS Pickup ViewModel

@Observable
final class BOPISPickupViewModel {

    // MARK: State
    var searchText: String = ""
    var selectedStatusFilter: BOPISStatusFilter = .readyForPickup
    var isLoading = false
    var errorMessage: String?

    // Sheet control
    var selectedOrder: OmnichannelOrder?
    var showDetailSheet = false
    var showCompletePickupSheet = false
    var orderToComplete: OmnichannelOrder?

    // Confirmation state inside complete-pickup sheet
    var isCompletingPickup = false
    var pickupCompleted = false

    // Data
    private(set) var allBOPISOrders: [OmnichannelOrder] = []
    private(set) var clients: [UUID: ClientProfile] = [:]
    private(set) var products: [UUID: String] = [:]  // productId → display name

    // MARK: Derived

    /// Orders filtered by status tab and search query.
    var displayedOrders: [OmnichannelOrder] {
        let statusFiltered: [OmnichannelOrder]
        switch selectedStatusFilter {
        case .readyForPickup:
            statusFiltered = allBOPISOrders.filter { $0.status == .ready }
        case .pickedUp:
            statusFiltered = allBOPISOrders.filter { $0.status == .pickedUp }
        case .cancelled:
            statusFiltered = allBOPISOrders.filter { $0.status == .cancelled }
        case .all:
            statusFiltered = allBOPISOrders
        }

        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return statusFiltered
        }

        let query = searchText.lowercased()
        return statusFiltered.filter { order in
            (order.onlineOrderId?.lowercased().contains(query) ?? false)
            || clientName(for: order.clientId).lowercased().contains(query)
            || (order.customerPhone?.contains(query) ?? false)
        }
    }

    var hasNoSearchResults: Bool {
        !searchText.isEmpty && displayedOrders.isEmpty
    }

    // MARK: Helpers

    func clientName(for id: UUID) -> String {
        clients[id]?.fullName ?? "Unknown Client"
    }

    func clientPhone(for id: UUID) -> String {
        clients[id]?.phone ?? "—"
    }

    func productName(for id: UUID?) -> String {
        guard let id else { return "—" }
        return products[id] ?? "Product"
    }

    func statusColor(_ status: OmnichannelOrderStatus) -> Color {
        switch status {
        case .reserved:   return RSMSTheme.info
        case .ready:      return RSMSTheme.warning
        case .pickedUp:   return RSMSTheme.success
        case .cancelled:  return RSMSTheme.danger
        default:          return RSMSTheme.textTertiary
        }
    }

    func statusLabel(_ status: OmnichannelOrderStatus) -> String {
        switch status {
        case .reserved:  return "Reserved"
        case .ready:     return "Ready for Pickup"
        case .pickedUp:  return "Picked Up"
        case .cancelled: return "Cancelled"
        default:         return status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    // MARK: Data Loading

    @MainActor
    func loadOrders(storeId: UUID?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let storeIdString = storeId?.uuidString ?? ""
            // Fetch BOPIS orders for the current store
            let orders: [OmnichannelOrder] = try await SupabaseClient.shared.fetch(
                "omnichannel_orders",
                query: [
                    "type": "eq.bopis",
                    "store_id": "eq.\(storeIdString)"
                ]
            )
            allBOPISOrders = orders

            // Fetch related clients
            let clientIds = Set(orders.map(\.clientId))
            for clientId in clientIds {
                if let client: ClientProfile = try? await SupabaseClient.shared.fetchById(
                    "client_profiles", id: clientId
                ) {
                    clients[clientId] = client
                }
            }

            // Fetch product names
            let productIds = Set(orders.compactMap(\.productId))
            for productId in productIds {
                if let product: Product = try? await SupabaseClient.shared.fetchById(
                    "products", id: productId
                ) {
                    products[productId] = product.name
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            // Fall back to mock data in development removed
            allBOPISOrders = []
        }
    }

    // MARK: Actions

    /// Marks a BOPIS order as Picked Up and writes the audit record.
    @MainActor
    func completePickup(
        order: OmnichannelOrder,
        associateName: String,
        associateId: UUID
    ) async {
        isCompletingPickup = true
        defer { isCompletingPickup = false }

        do {
            // 1. Update order status
            struct StatusPatch: Codable {
                let status: String
                let pickedUpAt: String
                enum CodingKeys: String, CodingKey {
                    case status
                    case pickedUpAt = "picked_up_at"
                }
            }
            let patch = StatusPatch(
                status: OmnichannelOrderStatus.pickedUp.rawValue,
                pickedUpAt: ISO8601DateFormatter().string(from: Date())
            )
            let _: StatusPatch = try await SupabaseClient.shared.update(
                "omnichannel_orders", id: order.id, record: patch
            )

            // 2. Write audit record
            struct AuditInsert: Codable {
                let orderId: UUID
                let associateId: UUID
                let associateName: String
                let customerName: String
                let pickupAt: String
                let statusFrom: String
                let statusTo: String
                enum CodingKeys: String, CodingKey {
                    case orderId       = "order_id"
                    case associateId   = "associate_id"
                    case associateName = "associate_name"
                    case customerName  = "customer_name"
                    case pickupAt      = "pickup_at"
                    case statusFrom    = "status_from"
                    case statusTo      = "status_to"
                }
            }
            let audit = AuditInsert(
                orderId: order.id,
                associateId: associateId,
                associateName: associateName,
                customerName: clientName(for: order.clientId),
                pickupAt: ISO8601DateFormatter().string(from: Date()),
                statusFrom: order.status.rawValue,
                statusTo: OmnichannelOrderStatus.pickedUp.rawValue
            )
            let _: AuditInsert = try await SupabaseClient.shared.insert(
                "bopis_pickup_audit", record: audit
            )

            // 3. Reflect locally
            if let idx = allBOPISOrders.firstIndex(where: { $0.id == order.id }) {
                // Re-fetch the updated order for consistency
                if let updated: OmnichannelOrder = try? await SupabaseClient.shared.fetchById(
                    "omnichannel_orders", id: order.id
                ) {
                    allBOPISOrders[idx] = updated
                }
            }

            pickupCompleted = true
        } catch {
            errorMessage = "Failed to complete pickup: \(error.localizedDescription)"
        }
    }
}

// MARK: - Status Filter Enum

enum BOPISStatusFilter: String, CaseIterable, Identifiable {
    case readyForPickup = "Ready for Pickup"
    case pickedUp       = "Picked Up"
    case cancelled      = "Cancelled"
    case all            = "All"

    var id: String { rawValue }
}

// MARK: - BOPIS Pickup View

struct BOPISPickupView: View {
    var isScrollable: Bool = true
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = BOPISPickupViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Search bar (AC2)
            searchBar

            // Status filter chips (AC6)
            statusFilterRow

            // Order list
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading BOPIS orders…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } else if viewModel.hasNoSearchResults {
                    // AC5 — No matching order message
                    noResultsState
                } else if viewModel.displayedOrders.isEmpty {
                    emptyState
                } else {
                    orderList
                }
            }
        }
        .task { await viewModel.loadOrders(storeId: appViewModel.currentStoreId) }
        .refreshable { await viewModel.loadOrders(storeId: appViewModel.currentStoreId) }
        .sheet(item: $viewModel.selectedOrder) { order in
            // AC4 — Order detail sheet
            BOPISOrderDetailSheet(order: order, viewModel: viewModel)
        }
        .sheet(item: $viewModel.orderToComplete) { order in
            // AC3 — Complete pickup sheet
            BOPISCompletePickupSheet(order: order, viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: Subviews

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(RSMSTheme.textTertiary)
            TextField("Order ID, customer name or phone…", text: $viewModel.searchText)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(RSMSTheme.surfacePrimary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var statusFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BOPISStatusFilter.allCases) { filter in
                    BOPISFilterChip(
                        label: filter.rawValue,
                        isSelected: viewModel.selectedStatusFilter == filter
                    ) {
                        viewModel.selectedStatusFilter = filter
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var orderList: some View {
        if isScrollable {
            ScrollView {
                orderListContent
            }
        } else {
            orderListContent
        }
    }

    private var orderListContent: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.displayedOrders) { order in
                BOPISOrderCard(order: order, viewModel: viewModel)
                    .onTapGesture {
                        viewModel.selectedOrder = order
                        viewModel.showDetailSheet = true
                    }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "shippingbox")
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("No BOPIS orders")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Text("Orders in \"\(viewModel.selectedStatusFilter.rawValue)\" will appear here.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }

    // AC5 — Explicit "No matching BOPIS order found" message
    private var noResultsState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("No matching BOPIS order found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Try a different Order ID, customer name, or phone number.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 32)
    }
}

// MARK: - BOPIS Order Card

private struct BOPISOrderCard: View {
    let order: OmnichannelOrder
    let viewModel: BOPISPickupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: Order ID + Status badge
            HStack {
                if let orderId = order.onlineOrderId {
                    Label(orderId, systemImage: "doc.text")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                Spacer()
                StatusBadge(
                    text: viewModel.statusLabel(order.status),
                    color: viewModel.statusColor(order.status)
                )
            }

            // Client name
            Text(viewModel.clientName(for: order.clientId))
                .font(.headline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)

            // Product name
            Text(viewModel.productName(for: order.productId))
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)

            Divider().overlay(RSMSTheme.divider)

            // Meta row: quantity, price, reservation date
            HStack(spacing: 16) {
                Label("Qty \(order.quantity)", systemImage: "number.circle")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)

                if let price = order.unitPrice {
                    Label(price.formatted(.currency(code: "INR")), systemImage: "indianrupeesign.circle")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }

                Spacer()

                if let reserved = order.reservationDate {
                    Label(reserved.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }

            // "Complete Pickup" CTA — only for Ready for Pickup orders (AC3)
            if order.status == .ready {
                Button {
                    viewModel.orderToComplete = order
                } label: {
                    Label("Complete Pickup", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Complete Pickup for order \(order.onlineOrderId ?? "")")
            }
        }
        .rsmsCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("BOPIS order \(order.onlineOrderId ?? ""), \(viewModel.clientName(for: order.clientId)), \(viewModel.statusLabel(order.status))")
    }
}

// MARK: - BOPIS Order Detail Sheet

struct BOPISOrderDetailSheet: View {
    let order: OmnichannelOrder
    let viewModel: BOPISPickupViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // Status banner
                        HStack {
                            Spacer()
                            StatusBadge(
                                text: viewModel.statusLabel(order.status),
                                color: viewModel.statusColor(order.status)
                            )
                            Spacer()
                        }
                        .padding(.top, 4)

                        // Order Info card
                        LuxuryFormCard(title: "Order Details", icon: "doc.text.fill") {
                            BOPISDetailRow(label: "Order ID", value: order.onlineOrderId ?? "—")
                            BOPISDetailRow(label: "Status", value: viewModel.statusLabel(order.status))
                            if let reserved = order.reservationDate {
                                BOPISDetailRow(
                                    label: "Reservation Date",
                                    value: reserved.formatted(date: .long, time: .shortened)
                                )
                            }
                            if let pickedUp = order.pickedUpAt {
                                BOPISDetailRow(
                                    label: "Picked Up At",
                                    value: pickedUp.formatted(date: .long, time: .shortened)
                                )
                            }
                        }

                        // Customer card
                        LuxuryFormCard(title: "Customer", icon: "person.fill") {
                            BOPISDetailRow(label: "Name", value: viewModel.clientName(for: order.clientId))
                            BOPISDetailRow(label: "Phone", value: viewModel.clientPhone(for: order.clientId))
                        }

                        // Product card
                        LuxuryFormCard(title: "Product", icon: "shippingbox.fill") {
                            BOPISDetailRow(label: "Product", value: viewModel.productName(for: order.productId))
                            BOPISDetailRow(label: "Quantity", value: "\(order.quantity)")
                            if let price = order.unitPrice {
                                BOPISDetailRow(
                                    label: "Unit Price",
                                    value: price.formatted(.currency(code: "INR"))
                                )
                                BOPISDetailRow(
                                    label: "Total",
                                    value: (price * Decimal(order.quantity)).formatted(.currency(code: "INR"))
                                )
                            }
                        }

                        if let notes = order.notes {
                            LuxuryFormCard(title: "Notes", icon: "note.text") {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Complete Pickup CTA inside detail sheet too
                        if order.status == .ready {
                            Button {
                                dismiss()
                                viewModel.orderToComplete = order
                            } label: {
                                Label("Complete Pickup", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RSMSTheme.primaryGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Detail Row helper

private struct BOPISDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - BOPIS Complete Pickup Sheet

struct BOPISCompletePickupSheet: View {
    let order: OmnichannelOrder
    let viewModel: BOPISPickupViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                if viewModel.pickupCompleted {
                    // Success confirmation state
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(RSMSTheme.success)
                        Text("Pickup Complete")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Order \(order.onlineOrderId ?? "") has been marked as Picked Up and the audit record has been saved.")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Done") {
                            viewModel.pickupCompleted = false
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 32)

                } else {
                    // Confirmation form
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary card
                            LuxuryFormCard(title: "Confirm Pickup", icon: "person.badge.clock.fill") {
                                BOPISDetailRow(label: "Order ID", value: order.onlineOrderId ?? "—")
                                BOPISDetailRow(label: "Customer", value: viewModel.clientName(for: order.clientId))
                                BOPISDetailRow(label: "Product", value: viewModel.productName(for: order.productId))
                                BOPISDetailRow(label: "Pickup Time", value: Date().formatted(date: .abbreviated, time: .shortened))
                            }

                            // Audit info card (AC8)
                            LuxuryFormCard(title: "Audit Record", icon: "lock.doc.fill") {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("The following will be recorded:")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                    AuditRow(icon: "doc.text", label: "Order ID")
                                    AuditRow(icon: "person.fill", label: "Associate Name")
                                    AuditRow(icon: "person.2.fill", label: "Customer Name")
                                    AuditRow(icon: "clock.fill", label: "Pickup Date & Time")
                                    AuditRow(icon: "arrow.triangle.2.circlepath", label: "Status Change: Ready → Picked Up")
                                }
                            }

                            // Confirm button
                            if viewModel.isCompletingPickup {
                                ProgressView("Recording pickup…")
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            } else {
                                Button {
                                    Task {
                                        await viewModel.completePickup(
                                            order: order,
                                            associateName: appViewModel.currentUser?.fullName ?? "Associate",
                                            associateId: appViewModel.currentUser?.id ?? UUID()
                                        )
                                    }
                                } label: {
                                    Label("Mark as Picked Up", systemImage: "checkmark.circle.fill")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.cream)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(RSMSTheme.primaryGradient)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .accessibilityLabel("Confirm pickup for order \(order.onlineOrderId ?? "")")
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Complete Pickup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isCompletingPickup)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isCompletingPickup)
    }
}

private struct AuditRow: View {
    let icon: String
    let label: String

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption)
            .foregroundStyle(RSMSTheme.textSecondary)
    }
}

// MARK: - BOPIS Filter Chip

private struct BOPISFilterChip: View {
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
                    isSelected
                        ? AnyShapeStyle(RSMSTheme.primaryGradient)
                        : AnyShapeStyle(RSMSTheme.surfacePrimary),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Filter: \(label)\(isSelected ? ", selected" : "")")
    }
}
