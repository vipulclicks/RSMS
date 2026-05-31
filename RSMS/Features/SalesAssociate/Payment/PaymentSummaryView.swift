//
//  PaymentSummaryView.swift
//  RSMS
//

import SwiftUI

struct PaymentSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    let cart: UniversalCart
    let checkoutVM: POSCheckoutViewModel
    
    @State private var showPaymentSheet = false
    @State private var orderCompleted = false
    @State private var completedOrder: Order?
    @State private var successfulPaymentId: String?
    @State private var isProcessing = false
    
    // Computed states for validation
    private var cartItems: [UniversalCartItem] {
        checkoutVM.cartItems(for: cart.id)
    }
    
    private var client: ClientProfile? {
        if let clientId = cart.clientId {
            return appVM.dataStore.client(by: clientId)
        }
        return nil
    }
    
    private var discountRequest: DiscountApprovalRequest? {
        appVM.dataStore.discountApprovalRequests.first { $0.cartId == cart.id }
    }
    
    private var cartSubtotal: Double {
        cartItems.reduce(0) { $0 + (($1.unitPrice ?? appVM.dataStore.product(by: $1.productId)?.price ?? 0) * Double($1.quantity)) }
    }
    
    private var discountApplied: Double {
        if let discount = cart.appliedDiscount {
            if discount.type == .percentage || discount.type == .vip {
                return cartSubtotal * (discount.value / 100.0)
            } else {
                return discount.value
            }
        }
        return 0
    }
    
    private var cartTax: Double {
        max(0, cartSubtotal - discountApplied) * 0.20
    }
    
    private var finalAmount: Double {
        max(0, cartSubtotal - discountApplied) + cartTax
    }
    
    private var validationErrors: [String] {
        var errors: [String] = []
        
        if cartItems.isEmpty {
            errors.append("Cart is empty.")
        }
        if client == nil {
            errors.append("No client associated with this cart.")
        }
        if let req = discountRequest, req.status != .approved {
            errors.append("Discount approval is pending or rejected.")
        } else if let discount = cart.appliedDiscount, discountRequest == nil {
            // Edge case: discount applied but no request found. Assuming auto-approved for VIP if valid, otherwise error
            if discount.status != .approved {
                errors.append("Discount not approved.")
            }
        }
        if finalAmount <= 0 {
            errors.append("Final payable amount must be greater than 0.")
        }
        
        return errors
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            if orderCompleted, let completedOrder, let successfulPaymentId {
                OrderCompletionView(
                    order: completedOrder,
                    client: client!,
                    paymentId: successfulPaymentId,
                    cartItems: cartItems
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Client Section
                        if let client = client {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Client details")
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(client.fullName)
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text(client.email ?? "No email")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Text(client.phone ?? "No phone")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .rsmsCard()
                            }
                        }
                        
                        // Product List
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Products")
                            
                            ForEach(cartItems) { item in
                                let product = appVM.dataStore.product(by: item.productId)
                                HStack {
                                    if let urlString = product?.imageURL, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Color.gray.opacity(0.1)
                                            }
                                        }
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .padding(.trailing, 8)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(RSMSTheme.surfaceSecondary)
                                            .frame(width: 60, height: 60)
                                            .overlay(Image(systemName: product?.categoryIconName ?? "gift.fill").foregroundStyle(RSMSTheme.textTertiary))
                                            .padding(.trailing, 8)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product?.name ?? "Unknown")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Text("Qty: \(item.quantity)")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    Spacer()
                                    Text("₹\(Int(item.unitPrice ?? product?.price ?? 0).formatted())")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                }
                                .padding()
                                .rsmsCard()
                            }
                        }
                        
                        // Financial Summary Footer
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Order Summary")
                            
                            VStack(spacing: 12) {
                                summaryRow(label: "Items (\(cartItems.count))", value: cartSubtotal)
                                
                                if let discount = cart.appliedDiscount {
                                    let status = discountRequest?.status ?? discount.status
                                    HStack {
                                        Text("Discount Applied")
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.danger)
                                        Spacer()
                                        StatusBadge(text: status.rawValue.capitalized, color: status == .approved ? RSMSTheme.success : RSMSTheme.warning)
                                        Text("-₹\(Int(discountApplied).formatted())")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.danger)
                                    }
                                }
                                
                                summaryRow(label: "Tax (20%)", value: cartTax)
                                
                                Divider().overlay(RSMSTheme.divider)
                                
                                HStack {
                                    Text("Final Amount")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Text("₹\(Int(finalAmount).formatted())")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(RSMSTheme.primary)
                                }
                            }
                            .padding()
                            .rsmsCard()
                        }
                        
                        // Validation Errors
                        if !validationErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(validationErrors, id: \.self) { error in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text(error)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.danger)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RSMSTheme.danger.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Actions
                        Button {
                            showPaymentSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                if isProcessing {
                                    ProgressView().tint(RSMSTheme.cream)
                                }
                                Text("Proceed to Payment")
                            }
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(validationErrors.isEmpty ? AnyShapeStyle(RSMSTheme.primaryGradient) : AnyShapeStyle(RSMSTheme.surfaceSecondary))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!validationErrors.isEmpty || isProcessing)
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle("Payment Summary")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPaymentSheet) {
            if let client = client {
                RazorpayPaymentSheet(cart: cart, amount: finalAmount, client: client) { paymentId in
                    handlePaymentSuccess(paymentId: paymentId)
                }
            }
        }
    }
    
    private func summaryRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text("₹\(Int(value).formatted())")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
    }
    
    private func handlePaymentSuccess(paymentId: String) {
        // Run Phase 7 & 8: Transaction Persistence and Order Creation
        isProcessing = true
        showPaymentSheet = false
        
        Task {
            do {
                // We use checkout method to persist transaction and tender
                try await checkoutVM.checkout(
                    cart: cart,
                    totalAmount: finalAmount,
                    taxAmount: 0, // Simplified for sandbox
                    tenderMethod: .card, // Assumed for razorpay
                    isTaxFree: false,
                    razorpayPaymentId: paymentId
                )
                
                // Get the created transaction (assuming it's the last one created by this cart)
                // In a robust implementation, checkout() would return the Transaction
                let transaction = appVM.dataStore.transactions.last { $0.cartId == cart.id }
                let transactionId = transaction?.id ?? UUID()
                
                // Create the Order
                let order = Order(
                    id: UUID(),
                    clientId: cart.clientId ?? UUID(),
                    transactionId: transactionId,
                    cartId: cart.id,
                    status: .confirmed,
                    totalAmount: cartSubtotal,
                    discountAmount: discountApplied,
                    finalAmount: finalAmount,
                    createdAt: Date()
                )
                
                try await appVM.dataStore.createOrder(order)
                
                successfulPaymentId = paymentId
                completedOrder = order
                orderCompleted = true
            } catch {
                print("Failed to save transaction or order: \(error)")
            }
            isProcessing = false
        }
    }
}
