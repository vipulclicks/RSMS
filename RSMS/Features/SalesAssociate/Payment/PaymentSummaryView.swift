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
    @State private var finalCartItems: [UniversalCartItem] = []
    
    // Gift Receipt
    @State private var showGiftReceiptSheet = false
    @State private var pendingGiftReceipts: [PendingGiftReceipt] = []
    @State private var isGiftReceiptEnabled = false
    
    // Tax-Free Shopping State
    @State private var showTaxFreeSheet = false
    @State private var passportNumber = ""
    @State private var customerName = ""
    @State private var countryOfResidence = ""
    @State private var isTaxFreeApplied = false
    
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
    
    private var taxFreeConfig: TaxFreeConfig {
        let storeId = appVM.currentUser?.storeId ?? UUID()
        return appVM.dataStore.getTaxFreeConfig(for: storeId)
    }
    
    private var estimatedTaxFreeRefund: Double {
        guard isTaxFreeApplied else { return 0 }
        let refund = TaxFreeService.calculateRefund(
            taxAmount: Decimal(cartTax),
            refundPercentage: taxFreeConfig.refundPercentage,
            serviceFee: taxFreeConfig.serviceFee
        )
        return Double(truncating: refund as NSDecimalNumber)
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
                    cartItems: finalCartItems,
                    giftReceipts: appVM.dataStore.giftReceipts.filter { r in
                        pendingGiftReceipts.contains(where: { $0.id == r.id })
                    }
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
                                
                                if isTaxFreeApplied {
                                    HStack {
                                        Text("Tax-Free Refund Estimate")
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.success)
                                        Spacer()
                                        Text("₹\(Int(estimatedTaxFreeRefund).formatted())")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.success)
                                    }
                                }
                                
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
                                
                                if isTaxFreeApplied {
                                    Text("Tax refund is processed after eligibility verification and applicable regulatory procedures.")
                                        .font(.caption2)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 4)
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
                        
                        // Gift Receipt Option
                        VStack(spacing: 0) {
                            HStack {
                                Label("Gift Receipt", systemImage: "gift")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Spacer()
                                Toggle("", isOn: $isGiftReceiptEnabled)
                                    .tint(RSMSTheme.primary)
                                    .labelsHidden()
                            }
                            .padding()
                            .rsmsCard()

                            if isGiftReceiptEnabled && !pendingGiftReceipts.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("\(pendingGiftReceipts.count) gift receipt\(pendingGiftReceipts.count > 1 ? "s" : "") prepared")
                                }
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.success)
                                .padding(.top, 6)
                            }
                        }
                        .onChange(of: isGiftReceiptEnabled) { _, enabled in
                            if enabled && pendingGiftReceipts.isEmpty {
                                showGiftReceiptSheet = true
                            }
                        }

                        // Tax-Free Option Section
                        Button {
                            showTaxFreeSheet = true
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Tax-Free Shopping", systemImage: "globe")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    if isTaxFreeApplied {
                                        Text("Applied")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.success)
                                    } else {
                                        Text("Check Eligibility")
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                
                                if isTaxFreeApplied {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Passport: \(passportNumber)")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                        Text("Residence: \(countryOfResidence)")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding()
                            .rsmsCard()
                        }
                        .buttonStyle(.plain)
                        
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
        .task {
            // Only fetch sales goals so checkout() can update achievedAmount.
            // Do NOT call checkoutVM.loadData() here — it refetches carts by type,
            // which would overwrite the universalCarts array and wipe curated carts.
            let storeId = checkoutVM.currentStoreId
            try? await appVM.dataStore.fetchSalesGoals(storeId: storeId)
        }
        .fullScreenCover(isPresented: $showPaymentSheet) {
            if let client = client {
                RazorpayPaymentSheet(cart: cart, amount: finalAmount, client: client) { paymentId in
                    handlePaymentSuccess(paymentId: paymentId)
                }
            }
        }
        .sheet(isPresented: $showGiftReceiptSheet) {
            GiftReceiptSheet(
                cartItems: cartItems,
                cart: cart,
                generatedReceipts: $pendingGiftReceipts
            )
        }
        .sheet(isPresented: $showTaxFreeSheet) {
            TaxFreeEligibilityView(
                subtotal: cartSubtotal,
                storeCountry: appVM.dataStore.stores.first(where: { $0.id == appVM.currentUser?.storeId })?.country ?? "India",
                config: taxFreeConfig,
                passportNumber: $passportNumber,
                customerName: $customerName,
                countryOfResidence: $countryOfResidence,
                isEligible: $isTaxFreeApplied
            )
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
        // Capture amounts before checkout clears the cart items
        let capturedSubtotal = cartSubtotal
        let capturedDiscount = discountApplied
        let capturedFinalAmount = finalAmount
        let capturedItems = cartItems
        let capturedIsTaxFree = isTaxFreeApplied
        let capturedPassport = passportNumber
        let capturedCountry = countryOfResidence
        let capturedCustName = customerName
        let capturedTaxAmount = cartTax
        let capturedRefundAmount = estimatedTaxFreeRefund
        
        // Run Phase 7 & 8: Transaction Persistence and Order Creation
        isProcessing = true
        showPaymentSheet = false
        finalCartItems = capturedItems
        
        Task {
            do {
                // We use checkout method to persist transaction and tender
                try await checkoutVM.checkout(
                    cart: cart,
                    totalAmount: capturedFinalAmount,
                    taxAmount: capturedTaxAmount,
                    tenderMethod: .card, // Assumed for razorpay
                    isTaxFree: capturedIsTaxFree,
                    razorpayPaymentId: paymentId
                )
                
                // Get the created transaction (assuming it's the last one created by this cart)
                let transaction = appVM.dataStore.transactions.last { $0.cartId == cart.id }
                let transactionId = transaction?.id ?? UUID()
                
                // Create the Order
                let order = Order(
                    id: UUID(),
                    clientId: cart.clientId ?? UUID(),
                    transactionId: transactionId,
                    cartId: cart.id,
                    status: .confirmed,
                    totalAmount: capturedSubtotal,
                    discountAmount: capturedDiscount,
                    finalAmount: capturedFinalAmount,
                    createdAt: Date()
                )
                
                // We ignore backend errors here if 'orders' table doesn't exist
                // so the user still sees the success screen.
                try? await appVM.dataStore.createOrder(order)
                
                // If tax free was applied, create the TaxFreeTransaction record
                if capturedIsTaxFree {
                    let taxFreeTxn = TaxFreeTransaction(
                        orderId: order.id,
                        customerName: capturedCustName,
                        passportNumber: capturedPassport,
                        countryOfResidence: capturedCountry,
                        taxAmount: Decimal(capturedTaxAmount),
                        refundAmount: Decimal(capturedRefundAmount),
                        status: .pending,
                        createdBy: appVM.currentUser?.id ?? UUID()
                    )
                    try? await appVM.dataStore.createTaxFreeTransaction(taxFreeTxn)
                    
                    let audit = TaxFreeAudit(
                        taxFreeTransactionId: taxFreeTxn.id,
                        userId: appVM.currentUser?.id ?? UUID(),
                        action: "Created tax-free transaction"
                    )
                    try? await appVM.dataStore.createTaxFreeAudit(audit)
                }
                
                // Persist prepared gift receipts now that we have the real transactionId
                let capturedPendingReceipts = pendingGiftReceipts
                for pending in capturedPendingReceipts {
                    let linked = GiftReceipt(
                        id: pending.id,
                        transactionId: transactionId,
                        recipientNote: pending.encodedNote,
                        printedAt: pending.printedAt
                    )
                    try? await appVM.dataStore.createGiftReceipt(linked)
                }
                
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
