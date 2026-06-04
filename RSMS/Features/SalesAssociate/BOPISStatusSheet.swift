//
//  BOPISStatusSheet.swift
//  RSMS
//

import SwiftUI

struct BOPISStatusSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    let session: CheckoutSession
    
    @State private var currentSession: CheckoutSession
    @State private var isLoading = false
    @State private var pollingTimer: Timer? = nil
    
    init(session: CheckoutSession) {
        self.session = session
        self._currentSession = State(initialValue: session)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current status card
                        VStack(spacing: 12) {
                            Text("Real-time Tracking")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textTertiary)
                                .textCase(.uppercase)
                            
                            Text(currentSession.status.rawValue.replacingOccurrences(of: "linkGenerated", with: "Link Generated").capitalized)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(RSMSTheme.primary)
                            
                            if let expires = expiryText {
                                Text(expires)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
                        
                        // Order Summary card
                        LuxuryFormCard(title: "Order Summary", icon: "cart.fill") {
                            // Item rows
                            ForEach(cartItems) { item in
                                let productName = appVM.dataStore.productName(for: item.productId)
                                let price = appVM.dataStore.resolvedPrice(for: item)
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(productName)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Text("Qty: \(item.quantity)")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    Spacer()
                                    Text("₹\(Int(price * Double(item.quantity)).formatted())")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                }
                                .padding(.vertical, 4)
                                if item.id != cartItems.last?.id {
                                    Divider()
                                }
                            }

                            if cartItems.isEmpty {
                                Text("No items found for this cart.")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }

                            Divider().padding(.vertical, 4)

                            // Totals breakdown
                            HStack {
                                Text("Subtotal (\(itemCount) item\(itemCount == 1 ? "" : "s"))")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Spacer()
                                Text("₹\(Int(subtotal).formatted())")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }

                            if discountAmount > 0 {
                                HStack {
                                    Text("Discount")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.success)
                                    Spacer()
                                    Text("- ₹\(Int(discountAmount).formatted())")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(RSMSTheme.success)
                                }
                            }

                            HStack {
                                Text("GST (20%)")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Spacer()
                                Text("₹\(Int(tax).formatted())")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }

                            HStack {
                                Text("Total")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Spacer()
                                Text("₹\(Int(total).formatted())")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Vertical stepper/timeline
                        VStack(alignment: .leading, spacing: 0) {
                            TimelineStepRow(
                                title: "Link Created",
                                subtitle: "Payment link was generated by you.",
                                isCompleted: true,
                                isCurrent: currentSession.status == .linkGenerated,
                                isLast: false
                            )
                            
                            TimelineStepRow(
                                title: "Client Opened Link",
                                subtitle: "The client viewed the checkout page.",
                                isCompleted: currentSession.status != .linkGenerated,
                                isCurrent: currentSession.status == .viewed,
                                isLast: false
                            )
                            
                            TimelineStepRow(
                                title: "Fulfillment Selected",
                                subtitle: fulfillmentSubtitle,
                                isCompleted: isFulfillmentSelected,
                                isCurrent: currentSession.status == .pendingPayment || currentSession.status == .pendingStorePayment,
                                isLast: false
                            )
                            
                            TimelineStepRow(
                                title: "Payment Done",
                                subtitle: paymentSubtitle,
                                isCompleted: isPaid,
                                isCurrent: currentSession.status == .paid || currentSession.status == .readyForPickup || currentSession.status == .readyForShipping,
                                isLast: false
                            )
                            
                            TimelineStepRow(
                                title: "Fulfillment Handover",
                                subtitle: handoverSubtitle,
                                isCompleted: currentSession.status == .completed,
                                isCurrent: currentSession.status == .completed,
                                isLast: true
                            )
                        }
                        .padding()
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
                        
                        // Close / Refresh actions
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await refreshStatus()
                                }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView().tint(RSMSTheme.cream)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Refresh Status")
                                }
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.cream)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RSMSTheme.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(isLoading)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Checkout Session Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                startPolling()
                Task {
                    try? await appVM.dataStore.fetchUniversalCartItems(cartId: currentSession.cartId)
                }
            }
            .onDisappear {
                stopPolling()
            }
        }
    }
    
    // MARK: - Helper Computed properties
    
    private var expiryText: String? {
        if currentSession.status == .completed || currentSession.status == .cancelled || currentSession.status == .expired {
            return nil
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Expires " + formatter.localizedString(for: currentSession.expiresAt, relativeTo: Date())
    }
    
    private var isFulfillmentSelected: Bool {
        currentSession.fulfillmentMethod != nil || currentSession.status == .completed || currentSession.status == .paid
    }
    
    private var isPaid: Bool {
        currentSession.status == .paid || currentSession.status == .readyForPickup || currentSession.status == .readyForShipping || currentSession.status == .completed
    }
    
    private var cartItems: [UniversalCartItem] {
        let activeItems = appVM.dataStore.universalCartItems.filter { $0.cartId == currentSession.cartId }
        if !activeItems.isEmpty {
            return activeItems
        }
        // Fallback to inventory reservations if cart items were cleared after payment
        let reservations = appVM.dataStore.inventoryReservations.filter { $0.checkoutSessionId == currentSession.id }
        print("[BOPISStatusSheet] ℹ️ Cart items empty. Falling back to \(reservations.count) inventory reservations for session \(currentSession.id).")
        return reservations.map { res in
            UniversalCartItem(
                id: res.id,
                cartId: currentSession.cartId,
                productId: res.productId,
                quantity: res.quantity,
                unitPrice: appVM.dataStore.product(by: res.productId)?.price,
                discountApplied: nil,
                note: nil
            )
        }
    }

    private var itemCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    private var subtotal: Double {
        cartItems.reduce(0.0) { sum, item in
            let price = appVM.dataStore.resolvedPrice(for: item)
            return sum + (price * Double(item.quantity))
        }
    }

    private var discountAmount: Double {
        guard let cart = appVM.dataStore.universalCarts.first(where: { $0.id == currentSession.cartId }),
              let discount = cart.appliedDiscount else { return 0.0 }
        if discount.type == .percentage { return subtotal * (discount.value / 100.0) }
        return discount.value
    }

    private var tax: Double { max(0, subtotal - discountAmount) * 0.20 }

    private var total: Double { max(0, subtotal - discountAmount) + tax }
    
    private var fulfillmentSubtitle: String {
        if let method = currentSession.fulfillmentMethod {
            return "Chosen: \(method.rawValue.capitalized)"
        }
        return "Waiting for client to select pickup or shipping."
    }
    
    private var paymentSubtitle: String {
        if let payMethod = currentSession.paymentMethod {
            if payMethod == .instore {
                return "Selected: Pay In Store (Awaiting Arrival)"
            } else {
                return "Completed: Paid Online (Razorpay)"
            }
        }
        if currentSession.status == .pendingStorePayment {
            return "Selected: Pay In Store"
        }
        return "Waiting for payment completion."
    }
    
    private var handoverSubtitle: String {
        if currentSession.status == .completed {
            return "Order successfully handed over to client."
        }
        if currentSession.status == .readyForPickup {
            return "Ready for pickup. Customer will arrive at your store."
        }
        if currentSession.status == .readyForShipping {
            return "Ready to ship. Prepare the packing slip."
        }
        return "Waiting for order fulfillment."
    }
    
    // MARK: - Actions
    
    private func refreshStatus() async {
        isLoading = true
        let checkoutVM = POSCheckoutViewModel(
            dataStore: appVM.dataStore,
            associateId: appVM.currentUser?.id ?? UUID(),
            storeId: appVM.currentStoreId ?? UUID()
        )
        do {
            let fresh = try await checkoutVM.fetchCheckoutSessionStatus(token: currentSession.token)
            await MainActor.run {
                self.currentSession = fresh
            }
        } catch {
            print("[BOPISStatusSheet] Error refreshing: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await refreshStatus()
            }
        }
    }
    
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}

// MARK: - Step Row Helper

struct TimelineStepRow: View {
    let title: String
    let subtitle: String
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                // Node icon
                ZStack {
                    Circle()
                        .fill(nodeColor.opacity(0.12))
                        .frame(width: 28, height: 28)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(nodeColor)
                    } else if isCurrent {
                        Circle()
                            .fill(nodeColor)
                            .frame(width: 10, height: 10)
                    } else {
                        Circle()
                            .fill(RSMSTheme.border)
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Connector line
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? RSMSTheme.success : RSMSTheme.border)
                        .frame(width: 2, height: 36)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isCompleted || isCurrent ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .lineLimit(2)
            }
            .padding(.bottom, isLast ? 0 : 16)
            
            Spacer()
        }
    }
    
    private var nodeColor: Color {
        if isCompleted {
            return RSMSTheme.success
        }
        if isCurrent {
            return RSMSTheme.primary
        }
        return RSMSTheme.textTertiary
    }
}
