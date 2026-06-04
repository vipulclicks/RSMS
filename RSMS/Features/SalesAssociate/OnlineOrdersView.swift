//
//  OnlineOrdersView.swift
//  RSMS
//

import SwiftUI

enum OnlineOrderStatusFilter: String, CaseIterable, Identifiable {
    case awaitingPayment = "Awaiting Payment"
    case awaitingPickup = "Awaiting Pickup"
    case readyForPickup = "Ready for Pickup"
    case readyToShip = "Ready to Ship"
    case completed = "Completed"
    
    var id: String { rawValue }
}

@Observable
final class OnlineOrdersViewModel {
    var selectedFilter: OnlineOrderStatusFilter = .awaitingPayment
    var searchText: String = ""
    var isRefreshing = false          // silent background refresh indicator
    var isProcessingPayment = false   // only used for the payment-sheet confirm button
    var errorMessage: String?

    // For pickup verification
    var sessionToVerify: CheckoutSession?
    var showVerificationAlert = false
    var verificationCode = ""
    var verificationErrorMessage: String?

    // For in-store payment sheet
    var sessionToPay: CheckoutSession?
    var showPaymentSheet = false
    var selectedTenderMethod: TenderMethod = .card
    
    func displaySessions(in dataStore: DataStore) -> [CheckoutSession] {
        let sessions = dataStore.checkoutSessions.filter { session in
            switch selectedFilter {
            case .awaitingPayment:
                return session.status == .linkGenerated || session.status == .viewed || session.status == .pendingPayment
            case .awaitingPickup:
                return session.status == .pendingStorePayment
            case .readyForPickup:
                // Include: paid online with pickup, readyForPickup, AND pay-in-store pickup orders
                return (session.status == .paid && session.fulfillmentMethod == .pickup)
                    || session.status == .readyForPickup
                    || (session.status == .pendingStorePayment && session.fulfillmentMethod == .pickup)
            case .readyToShip:
                return session.status == .paid && session.fulfillmentMethod == .shipping || session.status == .readyForShipping
            case .completed:
                return session.status == .completed
            }
        }
        
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return sessions
        }
        
        let query = searchText.lowercased()
        return sessions.filter { session in
            let clientName = dataStore.client(by: session.clientId)?.fullName.lowercased() ?? ""
            let token = session.token.lowercased()
            return clientName.contains(query) || token.contains(query)
        }
    }
    
    func clientName(for id: UUID, in dataStore: DataStore) -> String {
        dataStore.client(by: id)?.fullName ?? "Unknown Client"
    }
    
    func clientPhone(for id: UUID, in dataStore: DataStore) -> String {
        dataStore.client(by: id)?.phone ?? "—"
    }
    
    func cartTotal(for cartId: UUID, in dataStore: DataStore) -> Double {
        let items = dataStore.universalCartItems.filter { $0.cartId == cartId }
        if !items.isEmpty {
            let subtotal = items.reduce(0.0) { total, item in
                let price = dataStore.resolvedPrice(for: item)
                return total + (price * Double(item.quantity))
            }
            return subtotal * 1.20 // Subtotal + 20% Tax
        }
        
        // Fallback to inventory reservations if cart was cleared
        if let session = dataStore.checkoutSessions.first(where: { $0.cartId == cartId }) {
            let reservations = dataStore.inventoryReservations.filter { $0.checkoutSessionId == session.id }
            let subtotal = reservations.reduce(0.0) { total, res in
                let price = dataStore.product(by: res.productId)?.price ?? 0.0
                return total + (price * Double(res.quantity))
            }
            return subtotal * 1.20
        }
        return 0.0
    }
    
    @MainActor
    func processInStorePayment(session: CheckoutSession, tender: TenderMethod, dataStore: DataStore, associateId: UUID, storeId: UUID) async {
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        let total = cartTotal(for: session.cartId, in: dataStore)
        
        // 1. Create Transaction
        let txn = Transaction(
            id: UUID(),
            cartId: session.cartId,
            storeId: storeId,
            associateId: associateId,
            clientId: session.clientId,
            totalAmount: total,
            taxAmount: total * 0.2 / 1.2,
            currency: "INR",
            status: .completed,
            isTaxFree: false,
            createdAt: Date()
        )
        try? await dataStore.createTransaction(txn)
        
        // 2. Create Tender
        let tenderRecord = Tender(
            id: UUID(),
            transactionId: txn.id,
            method: tender,
            amount: total,
            reference: "In-Store Pay Link"
        )
        try? await dataStore.createTender(tenderRecord)
        
        // 3. Update CheckoutSession status to readyForPickup (Paid in Store)
        let updatedSession = CheckoutSession(
            id: session.id,
            cartId: session.cartId,
            token: session.token,
            clientId: session.clientId,
            associateId: session.associateId,
            status: .readyForPickup,
            fulfillmentMethod: session.fulfillmentMethod,
            paymentMethod: .instore,
            expiresAt: session.expiresAt,
            createdAt: session.createdAt,
            updatedAt: Date()
        )
        try? await dataStore.updateCheckoutSession(updatedSession)
        
        // 4. Update Cart status to completed
        if let cartIndex = dataStore.universalCarts.firstIndex(where: { $0.id == session.cartId }) {
            let cart = dataStore.universalCarts[cartIndex]
            let completedCart = UniversalCart(
                id: cart.id,
                type: cart.type,
                associateId: cart.associateId,
                clientId: cart.clientId,
                storeId: cart.storeId,
                status: .completed,
                note: cart.note,
                createdAt: cart.createdAt,
                updatedAt: Date()
            )
            try? await dataStore.updateUniversalCart(completedCart)
        }
        
        dataStore.logAudit(storeId: storeId, action: "In-Store BOPIS Payment Received", entityType: "CheckoutSession", entityId: session.id, performedBy: associateId)
        showPaymentSheet = false
    }
    
    @MainActor
    func completeHandover(session: CheckoutSession, dataStore: DataStore, associateId: UUID, storeId: UUID) async {
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // 1. Update CheckoutSession status to completed
        let updatedSession = CheckoutSession(
            id: session.id,
            cartId: session.cartId,
            token: session.token,
            clientId: session.clientId,
            associateId: session.associateId,
            status: .completed,
            fulfillmentMethod: session.fulfillmentMethod,
            paymentMethod: session.paymentMethod,
            expiresAt: session.expiresAt,
            createdAt: session.createdAt,
            updatedAt: Date()
        )
        try? await dataStore.updateCheckoutSession(updatedSession)
        
        // 2. Fulfill Inventory reservations
        let reservations = dataStore.inventoryReservations.filter { $0.checkoutSessionId == session.id && $0.status == .reserved }
        for res in reservations {
            let updatedRes = InventoryReservation(
                id: res.id,
                checkoutSessionId: res.checkoutSessionId,
                productId: res.productId,
                quantity: res.quantity,
                storeId: res.storeId,
                status: .fulfilled,
                createdAt: res.createdAt,
                expiresAt: res.expiresAt
            )
            try? await dataStore.updateInventoryReservation(updatedRes)
        }
        
        // 3. Write Order record
        let total = cartTotal(for: session.cartId, in: dataStore)
        let order = Order(
            id: UUID(),
            clientId: session.clientId,
            transactionId: UUID(), // Mock transaction id if in-store payment wasn't created, or link existing
            cartId: session.cartId,
            status: .delivered,
            totalAmount: total / 1.2,
            discountAmount: 0,
            finalAmount: total,
            createdAt: Date(),
            fulfillmentMethod: session.fulfillmentMethod?.rawValue,
            pickupStoreId: storeId,
            shippingAddress: nil,
            checkoutSessionId: session.id
        )
        try? await dataStore.createOrder(order)
        
        dataStore.logAudit(storeId: storeId, action: "BOPIS Handover Completed", entityType: "CheckoutSession", entityId: session.id, performedBy: associateId)
    }
    
    func completeShipping(session: CheckoutSession, address: String?, dataStore: DataStore, associateId: UUID, storeId: UUID) async {
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // 1. Update CheckoutSession status to completed
        let updatedSession = CheckoutSession(
            id: session.id,
            cartId: session.cartId,
            token: session.token,
            clientId: session.clientId,
            associateId: session.associateId,
            status: .completed,
            fulfillmentMethod: session.fulfillmentMethod,
            paymentMethod: session.paymentMethod,
            expiresAt: session.expiresAt,
            createdAt: session.createdAt,
            updatedAt: Date()
        )
        try? await dataStore.updateCheckoutSession(updatedSession)
        
        // 2. Fulfill Reservations
        let reservations = dataStore.inventoryReservations.filter { $0.checkoutSessionId == session.id && $0.status == .reserved }
        for res in reservations {
            let updatedRes = InventoryReservation(
                id: res.id,
                checkoutSessionId: res.checkoutSessionId,
                productId: res.productId,
                quantity: res.quantity,
                storeId: res.storeId,
                status: .fulfilled,
                createdAt: res.createdAt,
                expiresAt: res.expiresAt
            )
            try? await dataStore.updateInventoryReservation(updatedRes)
        }
        
        // 3. Write Order record
        let total = cartTotal(for: session.cartId, in: dataStore)
        let order = Order(
            id: UUID(),
            clientId: session.clientId,
            transactionId: UUID(),
            cartId: session.cartId,
            status: .shipped,
            totalAmount: total / 1.2,
            discountAmount: 0,
            finalAmount: total,
            createdAt: Date(),
            fulfillmentMethod: session.fulfillmentMethod?.rawValue,
            pickupStoreId: nil,
            shippingAddress: address,
            checkoutSessionId: session.id
        )
        try? await dataStore.createOrder(order)
        
        // 4. Update the packing slip shippedAt date if it exists
        let omnichannelOrderId = dataStore.omnichannelOrders.first(where: { $0.clientId == session.clientId })?.id
        if let oId = omnichannelOrderId,
           let existingSlip = dataStore.shipFromStoreSlips.first(where: { $0.orderId == oId }) {
            let updatedSlip = ShipFromStoreSlip(
                id: existingSlip.id,
                orderId: existingSlip.orderId,
                storeId: existingSlip.storeId,
                trackingNumber: existingSlip.trackingNumber,
                carrier: existingSlip.carrier,
                packingSlipURL: existingSlip.packingSlipURL,
                packedBy: existingSlip.packedBy,
                shippedAt: Date(),
                createdAt: existingSlip.createdAt
            )
            try? await dataStore.updateShipFromStoreSlip(updatedSlip)
        }
        
        dataStore.logAudit(storeId: storeId, action: "Home Delivery Shipped", entityType: "CheckoutSession", entityId: session.id, performedBy: associateId)
    }
    
    /// Soft-cancel an expired/stale checkout session so it disappears from the
    /// Awaiting Payment tab. The record stays in Supabase for the audit trail.
    func dismissExpiredSession(_ session: CheckoutSession, dataStore: DataStore) async {
        let cancelled = CheckoutSession(
            id: session.id,
            cartId: session.cartId,
            token: session.token,
            clientId: session.clientId,
            associateId: session.associateId,
            status: .cancelled,
            fulfillmentMethod: session.fulfillmentMethod,
            paymentMethod: session.paymentMethod,
            expiresAt: session.expiresAt,
            createdAt: session.createdAt,
            updatedAt: Date()
        )
        try? await dataStore.updateCheckoutSession(cancelled)
    }
}

struct OnlineOrdersView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = OnlineOrdersViewModel()
    
    // Single sheet coordinator — avoids iPad SwiftUI bug where only the first
    // of multiple chained .sheet() modifiers fires reliably.
    private enum ActiveSheet: Identifiable {
        case payment(CheckoutSession)
        case orderDetail(CheckoutSession)
        case packingSlip(CheckoutSession, ShipFromStoreSlip)
        
        var id: String {
            switch self {
            case .payment(let s):          return "payment-\(s.id)"
            case .orderDetail(let s):      return "detail-\(s.id)"
            case .packingSlip(_, let slip): return "slip-\(slip.id)"
            }
        }
    }
    @State private var activeSheet: ActiveSheet? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            filterPills
            
            ScrollView {
                let sessions = viewModel.displaySessions(in: appViewModel.dataStore)
                if sessions.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sessions) { session in
                            sessionCard(session: session)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .overlay(alignment: .top) {
                // Subtle refresh indicator — cards stay fully visible underneath
                if viewModel.isRefreshing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                        .padding(.top, 6)
                        .transition(.opacity)
                }
            }
            .refreshable {
                await loadData()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .payment(let session):
                receiveInStorePaymentSheet(session: session)
                    .onDisappear { viewModel.sessionToPay = nil }
            case .orderDetail(let session):
                OnlineOrderDetailSheet(session: session)
            case .packingSlip(let session, let slip):
                PackingSlipView(session: session, slip: slip)
            }
        }
        .alert("Verify Pickup Code", isPresented: $viewModel.showVerificationAlert) {
            TextField("6-Digit Code", text: $viewModel.verificationCode)
                .keyboardType(.numberPad)
            
            Button("Verify & Complete", role: .none) {
                if let session = viewModel.sessionToVerify {
                    let correctCode = session.pickupCode ?? ""
                    if correctCode.isEmpty || viewModel.verificationCode == correctCode {
                        Task {
                            await viewModel.completeHandover(
                                session: session,
                                dataStore: appViewModel.dataStore,
                                associateId: appViewModel.currentUser?.id ?? UUID(),
                                storeId: appViewModel.currentStoreId ?? UUID()
                            )
                        }
                    } else {
                        viewModel.verificationErrorMessage = "Incorrect pickup code. Please try again."
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.verificationErrorMessage ?? "Please enter the 6-digit pickup code that was emailed to the client.")
        }
        .task {
            // Load immediately on open
            await loadData()

            // Poll for updates every 8 seconds — smart merge in DataStore ensures
            // only changed cards trigger a SwiftUI re-render (no more full-list flicker).
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                await loadData()
            }
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by client name or token...")
    }
    
    // MARK: - Helper Load
    private func loadData() async {
        withAnimation(.easeInOut(duration: 0.2)) { viewModel.isRefreshing = true }
        defer {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.isRefreshing = false }
        }
        try? await appViewModel.dataStore.fetchCheckoutSessions()
        try? await appViewModel.dataStore.fetchInventoryReservations()
        try? await appViewModel.dataStore.fetchCheckoutShippingAddresses()
        try? await appViewModel.dataStore.fetchShipFromStoreSlips(storeId: appViewModel.currentStoreId)
        try? await appViewModel.dataStore.fetchOmnichannelOrders()
        try? await appViewModel.dataStore.fetchUniversalCarts(associateId: appViewModel.currentUser?.id ?? UUID())
        try? await appViewModel.dataStore.fetchTransactions(storeId: appViewModel.currentStoreId)
    }
    
    // MARK: - Subviews
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OnlineOrderStatusFilter.allCases) { filter in
                    Button {
                        withAnimation(reduceMotion ? nil : .default) {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(viewModel.selectedFilter == filter ? RSMSTheme.cream : RSMSTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                viewModel.selectedFilter == filter
                                    ? AnyShapeStyle(RSMSTheme.primaryGradient)
                                    : AnyShapeStyle(RSMSTheme.surfacePrimary),
                                in: Capsule()
                            )
                            .overlay(Capsule().stroke(viewModel.selectedFilter == filter ? Color.clear : RSMSTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("No checkout links found")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .rsmsCard()
        .padding(.horizontal, 24)
    }
    
    private func sessionCard(session: CheckoutSession) -> some View {
        let clientName = viewModel.clientName(for: session.clientId, in: appViewModel.dataStore)
        let total = viewModel.cartTotal(for: session.cartId, in: appViewModel.dataStore)
        let isExpired = session.status == .expired || session.expiresAt < Date() || session.status == .cancelled
        
        let displayStatusText: String
        let displayStatusColor: Color
        if isExpired {
            displayStatusText = session.status == .cancelled ? "Cancelled" : "Expired"
            displayStatusColor = session.status == .cancelled ? RSMSTheme.danger : RSMSTheme.textTertiary
        } else {
            displayStatusText = session.status.rawValue.replacingOccurrences(of: "linkGenerated", with: "Link Generated").capitalized
            displayStatusColor = checkoutSessionStatusColor(session.status)
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            // Tappable Header Area to open Details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(session.token, systemImage: "link")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Spacer()
                    StatusBadge(
                        text: displayStatusText,
                        color: displayStatusColor
                    )
                }
                
                Text(clientName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                HStack {
                    Text("Payable:")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("₹\(Int(total).formatted())")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RSMSTheme.primary)
                    
                    Spacer()
                    
                    if let method = session.fulfillmentMethod {
                        Label(method.rawValue.capitalized, systemImage: method == .pickup ? "bag.fill" : "truck.box.fill")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                activeSheet = .orderDetail(session)
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            // Action CTAs
            if isExpired {
                Button(role: .destructive) {
                    Task {
                        await viewModel.dismissExpiredSession(session, dataStore: appViewModel.dataStore)
                    }
                } label: {
                    Label("Remove Expired Link", systemImage: "link.badge.minus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.danger.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            } else if viewModel.selectedFilter == .awaitingPayment {
                // Non-expired but stale awaiting-payment — allow manual cancel
                Button(role: .destructive) {
                    Task {
                        await viewModel.dismissExpiredSession(session, dataStore: appViewModel.dataStore)
                    }
                } label: {
                    Label("Cancel Link", systemImage: "link.badge.minus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.danger.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.surfaceSecondary.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.danger.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            } else if session.status == .pendingStorePayment {
                Button {
                    viewModel.sessionToPay = session
                    activeSheet = .payment(session)
                } label: {
                    Label("Receive Payment In Store", systemImage: "indianrupeesign.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
            } else if session.status == .readyForPickup || (session.status == .paid && session.fulfillmentMethod == .pickup) {
                Button {
                    viewModel.sessionToVerify = session
                    viewModel.verificationCode = ""
                    viewModel.verificationErrorMessage = nil
                    viewModel.showVerificationAlert = true
                } label: {
                    Label("Complete Pickup", systemImage: "shippingbox.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
            } else if session.status == .readyForShipping || (session.status == .paid && session.fulfillmentMethod == .shipping) {
                let address = appViewModel.dataStore.checkoutShippingAddresses.first { $0.checkoutSessionId == session.id }
                let addressStr = address.map { "\($0.address), \($0.city), \($0.state) - \($0.pincode)" }
                
                VStack(alignment: .leading, spacing: 8) {
                    if let ad = address {
                        Text("Ship to: \(ad.name) (\(ad.phone))")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text(addressStr ?? "")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    
                    let omnichannelOrderId = appViewModel.dataStore.omnichannelOrders.first(where: { $0.clientId == session.clientId })?.id
                    let existingSlip = omnichannelOrderId.flatMap { oId in
                        appViewModel.dataStore.shipFromStoreSlips.first(where: { $0.orderId == oId })
                    }
                    
                    if let slip = existingSlip {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Packing Slip:")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Spacer()
                                Text("Generated")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.success)
                            }
                            
                            HStack(spacing: 8) {
                                Button {
                                    activeSheet = .packingSlip(session, slip)
                                } label: {
                                    Label("View Packing Slip", systemImage: "doc.text.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(RSMSTheme.surfaceSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
                                }
                                .buttonStyle(ScaleButtonStyle())
                                                    Button {
                                    Task {
                                        appViewModel.dataStore.logAudit(
                                            storeId: appViewModel.currentStoreId ?? appViewModel.dataStore.stores.first?.id ?? UUID(),
                                            action: "Packing Slip Regenerated",
                                            entityType: "ShipFromStoreSlip",
                                            entityId: slip.id,
                                            performedBy: appViewModel.currentUser?.id ?? UUID()
                                        )
                                        await MainActor.run {
                                            activeSheet = .packingSlip(session, slip)
                                        }
                                    }
                                } label: {
                                    Label("Regenerate", systemImage: "arrow.clockwise")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(RSMSTheme.surfaceSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border, lineWidth: 1))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.bottom, 4)
                    } else {
                        Button {
                            Task {
                                let resolvedStoreId = appViewModel.currentStoreId
                                    ?? appViewModel.dataStore.users.first(where: { $0.id == session.associateId })?.storeId
                                    ?? appViewModel.dataStore.stores.first?.id
                                    ?? UUID()
                                
                                do {
                                    // Step 1: Ensure an omnichannel_orders row exists (satisfies FK)
                                    let omnichannelOrder = try await appViewModel.dataStore
                                        .findOrCreateOmnichannelOrder(for: session, storeId: resolvedStoreId)
                                    
                                    // Step 2: Create the slip using omnichannelOrder.id, NOT session.id
                                    let newSlip = ShipFromStoreSlip(
                                        id: UUID(),
                                        orderId: omnichannelOrder.id,
                                        storeId: resolvedStoreId,
                                        trackingNumber: nil,
                                        carrier: nil,
                                        packingSlipURL: nil,
                                        packedBy: appViewModel.currentUser?.id,
                                        shippedAt: nil,
                                        createdAt: Date()
                                    )
                                    let created = try await appViewModel.dataStore.createShipFromStoreSlip(newSlip)
                                    appViewModel.dataStore.logAudit(
                                        storeId: resolvedStoreId,
                                        action: "Packing Slip Generated",
                                        entityType: "ShipFromStoreSlip",
                                        entityId: created.id,
                                        performedBy: appViewModel.currentUser?.id ?? UUID()
                                    )
                                    await MainActor.run {
                                        activeSheet = .packingSlip(session, created)
                                    }
                                } catch {
                                    print("[OnlineOrdersView] Failed to create packing slip: \(error.localizedDescription)")
                                }
                            }
                        } label: {
                            Label("Generate Packing Slip", systemImage: "doc.badge.plus")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.cream)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(RSMSTheme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.bottom, 4)
                    }
                    
                    Button {
                        Task {
                            await viewModel.completeShipping(
                                session: session,
                                address: addressStr,
                                dataStore: appViewModel.dataStore,
                                associateId: appViewModel.currentUser?.id ?? UUID(),
                                storeId: appViewModel.currentStoreId ?? UUID()
                            )
                        }
                    } label: {
                        Label("Mark as Shipped", systemImage: "paperplane.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RSMSTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            } else if session.status == .completed && session.fulfillmentMethod == .shipping {
                // Completed ship-from-store — show "View Shipping Slip" if one exists
                let omnichannelOrderId = appViewModel.dataStore.omnichannelOrders.first(where: { $0.clientId == session.clientId })?.id
                let completedSlip = omnichannelOrderId.flatMap { oId in
                    appViewModel.dataStore.shipFromStoreSlips.first(where: { $0.orderId == oId })
                }
                
                if let slip = completedSlip {
                    Button {
                        activeSheet = .packingSlip(session, slip)
                    } label: {
                        Label("View Shipping Slip", systemImage: "doc.text.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RSMSTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .rsmsCard()
    }
    
    private func receiveInStorePaymentSheet(session: CheckoutSession) -> some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    LuxuryFormCard(title: "Payment Summary", icon: "indianrupeesign.circle.fill") {
                        let total = viewModel.cartTotal(for: session.cartId, in: appViewModel.dataStore)
                        HStack {
                            Text("Total Payable:")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            Spacer()
                            Text("₹\(Int(total).formatted())")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(RSMSTheme.primary)
                        }
                    }
                    
                    LuxuryFormCard(title: "Select Tender Method", icon: "creditcard") {
                        Picker("Tender Method", selection: $viewModel.selectedTenderMethod) {
                            Text("Card").tag(TenderMethod.card)
                            Text("Cash").tag(TenderMethod.cash)
                            Text("Bank Transfer").tag(TenderMethod.bankTransfer)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await viewModel.processInStorePayment(
                                session: session,
                                tender: viewModel.selectedTenderMethod,
                                dataStore: appViewModel.dataStore,
                                associateId: appViewModel.currentUser?.id ?? UUID(),
                                storeId: appViewModel.currentStoreId ?? UUID()
                            )
                        }
                    } label: {
                        Text("Record Payment & Confirm")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(24)
            }
            .navigationTitle("In-store Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.showPaymentSheet = false
                    }
                }
            }
        }
    }
    
    private func checkoutSessionStatusColor(_ status: CheckoutStatus) -> Color {
        switch status {
        case .draft: return RSMSTheme.textSecondary
        case .linkGenerated: return RSMSTheme.info
        case .viewed: return RSMSTheme.warning
        case .pendingPayment, .pendingStorePayment: return RSMSTheme.warning
        case .paid, .readyForPickup, .readyForShipping: return RSMSTheme.success
        case .completed: return RSMSTheme.success
        case .expired: return RSMSTheme.textTertiary
        case .cancelled: return RSMSTheme.danger
        }
    }
}

// MARK: - Online Order Detail Sheet

struct OnlineOrderDetailSheet: View {
    let session: CheckoutSession
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSchedulePickup = false
    @State private var scheduledDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var isSavingPickup = false
    @State private var localPickupDate: Date? = nil
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.createdAt)
    }
    
    private var client: ClientProfile? {
        appViewModel.dataStore.client(by: session.clientId)
    }
    
    private var cartItems: [UniversalCartItem] {
        let activeItems = appViewModel.dataStore.universalCartItems.filter { $0.cartId == session.cartId }
        if !activeItems.isEmpty {
            return activeItems
        }
        // Fallback to inventory reservations if cart items were cleared after payment
        let reservations = appViewModel.dataStore.inventoryReservations.filter { $0.checkoutSessionId == session.id }
        print("[OnlineOrderDetailSheet] ℹ️ Cart items empty. Falling back to \(reservations.count) inventory reservations for session \(session.id).")
        return reservations.map { res in
            UniversalCartItem(
                id: res.id,
                cartId: session.cartId,
                productId: res.productId,
                quantity: res.quantity,
                unitPrice: appViewModel.dataStore.product(by: res.productId)?.price,
                discountApplied: nil,
                note: nil
            )
        }
    }
    
    private var subtotalAmount: Double {
        cartItems.reduce(0.0) { total, item in
            let price = appViewModel.dataStore.resolvedPrice(for: item)
            return total + (price * Double(item.quantity))
        }
    }
    
    private var cart: UniversalCart? {
        appViewModel.dataStore.universalCarts.first { $0.id == session.cartId }
    }
    
    private var discountAmount: Double {
        guard let cart = cart, let discount = cart.appliedDiscount else { return 0.0 }
        switch discount.type {
        case .percentage, .vip:
            return subtotalAmount * (discount.value / 100.0)
        case .promotional:
            return discount.value
        }
    }
    
    private var taxAmount: Double {
        let postDiscount = max(0, subtotalAmount - discountAmount)
        return postDiscount * 0.20
    }
    
    private var totalAmount: Double {
        let postDiscount = max(0, subtotalAmount - discountAmount)
        return postDiscount + taxAmount
    }
    
    private var shippingAddress: CheckoutShippingAddress? {
        appViewModel.dataStore.checkoutShippingAddresses.first { $0.checkoutSessionId == session.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        statusHeaderCard
                        
                        clientDetailsCard
                        
                        fulfillmentCard
                        
                        itemsCard
                        
                        costSummaryCard
                        
                        paymentDetailsCard
                        
                        timelineCard
                        
                        Spacer(minLength: 30)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Online Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }
            }
            .sheet(isPresented: $showSchedulePickup) {
                SchedulePickupSheet(
                    session: session,
                    scheduledDate: $scheduledDate,
                    onSave: { date in
                        localPickupDate = date
                        showSchedulePickup = false
                    }
                )
            }
        }
    }
    
    private var statusHeaderCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ORDER TOKEN")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .tracking(1.0)
                Spacer()
                Text("DATE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .tracking(1.0)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(session.token)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RSMSTheme.primary)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            HStack {
                Text("Current Status")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                StatusBadge(
                    text: session.status.rawValue.replacingOccurrences(of: "linkGenerated", with: "Link Generated").capitalized,
                    color: checkoutSessionStatusColor(session.status)
                )
            }
        }
        .padding()
        .rsmsCard()
    }
    
    private var clientDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Client Details", systemImage: "person.circle.fill")
                .font(.headline)
                .foregroundStyle(RSMSTheme.primary)
            
            Divider().overlay(RSMSTheme.divider)
            
            if let client {
                VStack(alignment: .leading, spacing: 8) {
                    Text(client.fullName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text(client.phone ?? "—")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text(client.email ?? "—")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            } else {
                Text("No client information available")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding()
        .rsmsCard()
    }
    
    private var fulfillmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            let isShipping = session.fulfillmentMethod == .shipping
            let isPickup = session.fulfillmentMethod == .pickup
            // Show scheduling for paid-online AND pay-in-store pickup orders
            let isPaid = session.status == .readyForPickup
                || session.status == .paid
                || session.status == .pendingStorePayment

            Label(isShipping ? "Shipping Address" : "Fulfillment Method", systemImage: isShipping ? "shippingbox.fill" : "storefront.fill")
                .font(.headline)
                .foregroundStyle(RSMSTheme.primary)

            Divider().overlay(RSMSTheme.divider)

            if let method = session.fulfillmentMethod {
                if method == .pickup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("In-Store Pickup (BOPIS)")
                            .font(.body.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)

                        Text("Client will collect items at the boutique.")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)

                        // Show scheduled pickup time if set
                        if let pickup = localPickupDate ?? session.scheduledPickupAt {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.checkmark")
                                    .foregroundStyle(RSMSTheme.success)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pickup Scheduled")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.success)
                                    HStack(spacing: 0) {
                                        Text(pickup, style: .date)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Text(" · ")
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                        Text(pickup, style: .time)
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                    }
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RSMSTheme.success.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Schedule / Reschedule button for paid pickup orders
                        if isPaid {
                            Button {
                                showSchedulePickup = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text(localPickupDate != nil || session.scheduledPickupAt != nil ? "Reschedule Pickup" : "Schedule Pickup Time")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RSMSTheme.primary.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                } else if method == .shipping {
                    if let addr = shippingAddress {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(addr.name)
                                .font(.body.weight(.bold))
                                .foregroundStyle(RSMSTheme.textPrimary)

                            HStack {
                                Image(systemName: "phone")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Text(addr.phone)
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }

                            Text(addr.address)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textSecondary)

                            Text("\(addr.city), \(addr.state) - \(addr.pincode)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    } else {
                        Text("Awaiting shipping address entry from client...")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            } else {
                Text("Client has not selected fulfillment method yet.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding()
        .rsmsCard()
    }
    
    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Order Pieces", systemImage: "tag.circle.fill")
                .font(.headline)
                .foregroundStyle(RSMSTheme.primary)
            
            Divider().overlay(RSMSTheme.divider)
            
            if cartItems.isEmpty {
                Text("No items found in this order.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            } else {
                ForEach(cartItems) { item in
                    let product = appViewModel.dataStore.product(by: item.productId)
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(RSMSTheme.surfaceSecondary)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: product?.categoryIconName ?? "gift.fill")
                                    .foregroundStyle(RSMSTheme.primary)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product?.name ?? "Unknown Product")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .lineLimit(1)
                            
                            Text("Qty: \(item.quantity) • \(product?.brand.uppercased() ?? "")")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        
                        Spacer()
                        
                        let price = appViewModel.dataStore.resolvedPrice(for: item)
                        Text("₹\(Int(price * Double(item.quantity)).formatted())")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .rsmsCard()
    }
    
    private var costSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Cost Summary", systemImage: "indianrupeesign.circle.fill")
                .font(.headline)
                .foregroundStyle(RSMSTheme.primary)
            
            Divider().overlay(RSMSTheme.divider)
            
            HStack {
                Text("Subtotal")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text("₹\(Int(subtotalAmount).formatted())")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            
            if discountAmount > 0 {
                HStack {
                    Text("Discount")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.danger)
                    Spacer()
                    Text("- ₹\(Int(discountAmount).formatted())")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.danger)
                }
            }
            
            HStack {
                Text("Tax (20%)")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text("₹\(Int(taxAmount).formatted())")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            HStack {
                Text("Total Estimated")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                Text("₹\(Int(totalAmount).formatted())")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RSMSTheme.primary)
            }
        }
        .padding()
        .rsmsCard()
    }
    
    private var paymentDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Payment & Transaction Details", systemImage: "creditcard.circle.fill")
                .font(.headline)
                .foregroundStyle(RSMSTheme.primary)
            
            Divider().overlay(RSMSTheme.divider)
            
            HStack {
                Text("Payment Status:")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text(session.status == .paid || session.status == .readyForPickup || session.status == .readyForShipping || session.status == .completed ? "Paid" : "Awaiting Payment")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(session.status == .paid || session.status == .readyForPickup || session.status == .readyForShipping || session.status == .completed ? RSMSTheme.success : RSMSTheme.warning)
            }
            
            if let payMethod = session.paymentMethod {
                HStack {
                    Text("Method:")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                    Text(payMethod == .online ? "Online Payment (Razorpay)" : "Pay in Boutique / Cash / Card")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
            }
        }
        .padding()
        .rsmsCard()
    }
    
    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Checkout Timeline", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(RSMSTheme.primary)
            
            Divider().overlay(RSMSTheme.divider)
            
            let status = session.status
            
            VStack(spacing: 0) {
                TimelineStepView(
                    title: "Link Generated",
                    description: "Associate generated the checkout session.",
                    isCompleted: true,
                    isCurrent: status == .linkGenerated,
                    isLast: false
                )
                
                TimelineStepView(
                    title: "Link Opened",
                    description: "Client opened the checkout website.",
                    isCompleted: status != .linkGenerated,
                    isCurrent: status == .viewed,
                    isLast: false
                )
                
                TimelineStepView(
                    title: "Fulfillment Confirmed",
                    description: "Delivery method and details selected.",
                    isCompleted: status != .linkGenerated && status != .viewed,
                    isCurrent: status == .pendingPayment,
                    isLast: false
                )
                
                TimelineStepView(
                    title: "Payment Received",
                    description: "Payment captured successfully.",
                    isCompleted: status == .paid || status == .readyForPickup || status == .readyForShipping || status == .completed,
                    isCurrent: status == .pendingStorePayment,
                    isLast: false
                )
                
                TimelineStepView(
                    title: "Ready for Delivery",
                    description: "Order is packed and ready for pickup/shipment.",
                    isCompleted: status == .readyForPickup || status == .readyForShipping || status == .completed,
                    isCurrent: status == .readyForPickup || status == .readyForShipping,
                    isLast: false
                )
                
                TimelineStepView(
                    title: "Order Completed",
                    description: "Items handed over or shipped to client.",
                    isCompleted: status == .completed,
                    isCurrent: status == .completed,
                    isLast: true
                )
            }
            .padding(.top, 4)
        }
        .padding()
        .rsmsCard()
    }
    
    private func checkoutSessionStatusColor(_ status: CheckoutStatus) -> Color {
        switch status {
        case .draft: return RSMSTheme.textSecondary
        case .linkGenerated: return RSMSTheme.info
        case .viewed: return RSMSTheme.warning
        case .pendingPayment, .pendingStorePayment: return RSMSTheme.warning
        case .paid, .readyForPickup, .readyForShipping: return RSMSTheme.success
        case .completed: return RSMSTheme.success
        case .expired: return RSMSTheme.textTertiary
        case .cancelled: return RSMSTheme.danger
        }
    }
}

// MARK: - Timeline Step View

struct TimelineStepView: View {
    let title: String
    let description: String
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack {
                Circle()
                    .fill(isCurrent ? RSMSTheme.primary : (isCompleted ? RSMSTheme.success : RSMSTheme.border))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(isCurrent ? RSMSTheme.primary.opacity(0.3) : Color.clear, lineWidth: 6)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? RSMSTheme.success : RSMSTheme.border)
                        .frame(width: 2, height: 35)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isCurrent ? RSMSTheme.textPrimary : (isCompleted ? RSMSTheme.textSecondary : RSMSTheme.textTertiary))
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
        }
    }
}

// MARK: - Schedule Pickup Sheet

struct SchedulePickupSheet: View {
    let session: CheckoutSession
    @Binding var scheduledDate: Date
    let onSave: (Date) -> Void
    
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var localDate: Date
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(session: CheckoutSession, scheduledDate: Binding<Date>, onSave: @escaping (Date) -> Void) {
        self.session = session
        self._scheduledDate = scheduledDate
        self.onSave = onSave
        self._localDate = State(initialValue: scheduledDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schedule BOPIS Pickup")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        Text("Select the date and time when the customer intends to pick up their order from the boutique.")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(spacing: 20) {
                        DatePicker(
                            "Pickup Date & Time",
                            selection: $localDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .tint(RSMSTheme.primary)
                        .padding()
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
                    }
                    .padding(.horizontal)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.danger)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Button {
                        saveScheduledPickup()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "calendar.badge.checkmark")
                                Text("Confirm Schedule")
                                    .fontWeight(.bold)
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
    }
    
    private func saveScheduledPickup() {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Generate a random 6-digit code
                let generatedCode = String(format: "%06d", Int.random(in: 0...999999))
                
                // Update checkout session locally & in remote Supabase/Python DB
                var updated = session
                updated.scheduledPickupAt = localDate
                updated.pickupCode = generatedCode
                
                try await appViewModel.dataStore.updateCheckoutSession(updated)
                
                // Trigger pickup confirmation email to client
                await appViewModel.dataStore.sendPickupConfirmationEmail(for: updated)
                
                await MainActor.run {
                    scheduledDate = localDate
                    isSaving = false
                    onSave(localDate)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to update pickup schedule: \(error.localizedDescription)"
                }
            }
        }
    }
}
