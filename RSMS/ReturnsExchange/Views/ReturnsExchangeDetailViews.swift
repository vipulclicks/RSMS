//
//  ReturnsExchangeDetailViews.swift
//  RSMS
//

import SwiftUI

// MARK: - Return Request Detail View

struct ReturnRequestDetailView: View {
    let request: POSReturnRequest
    let dataStore: DataStore
    
    var body: some View {
        List {
            Section("Status Information") {
                LabeledContent("Status") {
                    Text(request.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .fontWeight(.bold)
                        .foregroundStyle(statusColor(request.status))
                }
                LabeledContent("Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Last Updated", value: request.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section("Return Item Details") {
                LabeledContent("Product", value: dataStore.productName(for: request.productId))
                LabeledContent("Quantity", value: request.quantity, format: .number)
                LabeledContent("Reason", value: request.reason)
                LabeledContent("Refund Amount", value: request.originalPaidAmount, format: .currency(code: "INR"))
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section("Order & Store Details") {
                LabeledContent("Order ID", value: request.orderId.uuidString)
                LabeledContent("Store ID", value: request.storeId.uuidString)
                LabeledContent("Associate ID", value: request.associateId.uuidString)
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            if let condition = request.inspectionCondition {
                Section("Inspection Information") {
                    LabeledContent("Condition Check", value: condition.rawValue)
                    LabeledContent("Inspector", value: dataStore.userName(for: request.inspectedBy ?? UUID()))
                    if let date = request.inspectedAt {
                        LabeledContent("Inspection Date", value: date.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let notes = request.inspectionNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                    }
                }
                .listRowBackground(RSMSTheme.surfacePrimary)
            }
        }
        .navigationTitle("Return Request details")
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
    }
    
    private func statusColor(_ status: POSReturnStatus) -> Color {
        switch status {
        case .requested: return RSMSTheme.info
        case .inspectionPending: return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .rejected: return RSMSTheme.danger
        case .refunded: return RSMSTheme.primary
        }
    }
}

// MARK: - Exchange Request Detail View

struct ExchangeRequestDetailView: View {
    let request: POSExchangeRequest
    let dataStore: DataStore
    
    @Environment(AppViewModel.self) private var appVM
    @State private var showPaymentSheet = false
    @State private var localRequest: POSExchangeRequest?
    @State private var paymentSuccess = false
    @State private var paymentId: String?
    @State private var isProcessingRefund = false
    @State private var refundProcessed = false
    
    private var currentRequest: POSExchangeRequest {
        localRequest ?? request
    }
    
    var body: some View {
        List {
            Section("Status Information") {
                LabeledContent("Status") {
                    Text(currentRequest.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .fontWeight(.bold)
                        .foregroundStyle(statusColor(currentRequest.status))
                }
                LabeledContent("Created At", value: currentRequest.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Last Updated", value: currentRequest.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section("Exchange Details") {
                LabeledContent("Returned Item", value: dataStore.productName(for: currentRequest.originalProductId))
                LabeledContent("Replacement Item", value: dataStore.productName(for: currentRequest.replacementProductId))
                LabeledContent("Quantity", value: currentRequest.quantity, format: .number)
                LabeledContent("Reason", value: currentRequest.reason)
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section("Financial Reconcile") {
                LabeledContent("Returned Value", value: currentRequest.returnedItemValue, format: .currency(code: "INR"))
                LabeledContent("Replacement Value", value: currentRequest.replacementItemValue, format: .currency(code: "INR"))
                
                let diff = currentRequest.differenceAmount
                LabeledContent("Difference") {
                    if diff == 0 {
                        Text("Even Exchange")
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.success)
                    } else if diff > 0 {
                        Text("Customer Pays \(diff, format: .currency(code: "INR"))")
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.danger)
                    } else {
                        Text("Store Refunds \(abs(diff), format: .currency(code: "INR"))")
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.success)
                    }
                }
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            // Refund completed confirmation
            if refundProcessed {
                Section("Refund Confirmation") {
                    LabeledContent("Refund Amount") {
                        Text("\(abs(request.differenceAmount), format: .currency(code: "INR"))")
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.success)
                    }
                    LabeledContent("Status") {
                        Text("Refund Processed")
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.success)
                    }
                }
                .listRowBackground(RSMSTheme.surfacePrimary)
            }
            
            // Payment completed confirmation
            if paymentSuccess, let pid = paymentId {
                Section("Payment Confirmation") {
                    LabeledContent("Payment ID", value: pid)
                    LabeledContent("Status") {
                        Text("Paid Successfully")
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.success)
                    }
                }
                .listRowBackground(RSMSTheme.surfacePrimary)
            }
            
            Section("Order & Store Details") {
                LabeledContent("Order ID", value: currentRequest.orderId.uuidString)
                LabeledContent("Store ID", value: currentRequest.storeId.uuidString)
                LabeledContent("Associate ID", value: currentRequest.associateId.uuidString)
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            if let condition = currentRequest.inspectionCondition {
                Section("Inspection Information") {
                    LabeledContent("Condition Check", value: condition.rawValue)
                    LabeledContent("Inspector", value: dataStore.userName(for: currentRequest.inspectedBy ?? UUID()))
                    if let date = currentRequest.inspectedAt {
                        LabeledContent("Inspection Date", value: date.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let notes = currentRequest.inspectionNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                    }
                }
                .listRowBackground(RSMSTheme.surfacePrimary)
            }
        }
        .navigationTitle("Exchange Request details")
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $showPaymentSheet) {
            ExchangePaymentSheet(
                request: currentRequest,
                dataStore: dataStore,
                onPaymentSuccess: { razorpayPaymentId in
                    paymentSuccess = true
                    paymentId = razorpayPaymentId
                    // Update local state to reflect completed status
                    var updated = currentRequest
                    updated.status = .completed
                    updated.updatedAt = Date()
                    localRequest = updated
                }
            )
        }
        .safeAreaInset(edge: .bottom) {
            if currentRequest.status == .paymentPending {
                VStack(spacing: 0) {
                    Divider()
                        .background(RSMSTheme.divider)
                    if currentRequest.differenceAmount > 0 {
                        Button {
                            showPaymentSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "indianrupeesign.circle.fill")
                                Text("Collect Payment via Razorpay (\(currentRequest.differenceAmount, format: .currency(code: "INR")) due)")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(RSMSTheme.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    } else if currentRequest.differenceAmount < 0 {
                        Button {
                            Task { await processRefund() }
                        } label: {
                            HStack {
                                if isProcessingRefund {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                }
                                Text("Process Refund to Customer (\(abs(currentRequest.differenceAmount), format: .currency(code: "INR")))")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .disabled(isProcessingRefund)
                        .buttonStyle(.borderedProminent)
                        .tint(RSMSTheme.success)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
                .background(RSMSTheme.background.ignoresSafeArea())
            }
        }
    }
    
    private func statusColor(_ status: POSExchangeStatus) -> Color {
        switch status {
        case .requested: return RSMSTheme.info
        case .inspectionPending: return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .paymentPending: return RSMSTheme.warning
        case .completed: return RSMSTheme.primary
        case .rejected: return RSMSTheme.danger
        }
    }
    
    private func processRefund() async {
        guard let user = appVM.currentUser else { return }
        isProcessingRefund = true
        
        var updated = currentRequest
        updated.status = .completed
        updated.updatedAt = Date()
        
        let repo = ExchangeRepository(dataStore: dataStore)
        let refundAmount = abs(NSDecimalNumber(decimal: currentRequest.differenceAmount).doubleValue)
        
        do {
            try await repo.updateExchangeRequest(
                updated,
                user: user,
                action: "Refund of ₹\(String(format: "%.2f", refundAmount)) processed to customer",
                prevStatus: .paymentPending
            )
            
            refundProcessed = true
            localRequest = updated
        } catch {
            print("[ExchangeRefund] Failed to process refund: \(error)")
        }
        
        isProcessingRefund = false
    }
}

// MARK: - Exchange Payment Sheet (Razorpay)

struct ExchangePaymentSheet: View {
    let request: POSExchangeRequest
    let dataStore: DataStore
    let onPaymentSuccess: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @State private var state: PaymentSheetState = .loading
    
    private var amountDue: Double {
        NSDecimalNumber(decimal: request.differenceAmount).doubleValue
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                switch state {
                case .loading:
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(RSMSTheme.primary)
                        Text("Initializing Payment...")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .onAppear { createOrder() }
                    
                case .checkout(let order):
                    let clientId = dataStore.orders.first(where: { $0.id == request.orderId })?.clientId ?? UUID()
                    let client = dataStore.client(by: clientId)
                    
                    RazorpayCheckoutWebView(
                        orderId: order.id,
                        amount: order.amount,
                        currency: order.currency,
                        customerName: client?.fullName ?? "Customer",
                        email: client?.email ?? "no-email@example.com",
                        phone: client?.phone ?? "",
                        cartId: request.id.uuidString,
                        clientId: clientId.uuidString,
                        onSuccess: { result in
                            state = .success(paymentId: result.paymentId, amount: amountDue, date: Date())
                            handlePaymentCompletion(paymentId: result.paymentId)
                        },
                        onFailure: { reason in
                            state = .failure(reason: reason)
                        },
                        onDismiss: {
                            dismiss()
                        }
                    )
                    
                case .success(let pid, let amount, let date):
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(RSMSTheme.success)
                        
                        Text("Payment Successful")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        VStack(spacing: 12) {
                            detailRow(title: "Payment ID", value: pid)
                            detailRow(title: "Amount Paid", value: "₹\(String(format: "%.2f", amount))")
                            detailRow(title: "Date", value: date.formatted())
                            detailRow(title: "Exchange ID", value: request.id.uuidString.prefix(8).uppercased())
                        }
                        .padding()
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RSMSTheme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(24)
                    
                case .failure(let reason):
                    VStack(spacing: 24) {
                        Image(systemName: "xmark.octagon.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(RSMSTheme.danger)
                        
                        Text("Payment Failed")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        Text(reason)
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            Button {
                                state = .loading
                            } label: {
                                Text("Retry")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RSMSTheme.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RSMSTheme.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Exchange Payment")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if case .loading = state {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(RSMSTheme.primary)
                    } else if case .checkout = state {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(RSMSTheme.primary)
                    }
                }
            }
        }
    }
    
    private func createOrder() {
        Task {
            do {
                let order = try await RazorpayService.createOrder(
                    amount: amountDue,
                    receipt: "exchange-\(request.id.uuidString.prefix(8))"
                )
                state = .checkout(order)
            } catch {
                state = .failure(reason: error.localizedDescription)
            }
        }
    }
    
    private func handlePaymentCompletion(paymentId: String) {
        Task {
            // 1. Create and record a new UniversalCart, UniversalCartItem, Transaction, Tender, and Commission records for the payment difference
            let originalOrder = dataStore.orders.first(where: { $0.id == request.orderId })
            let clientId = originalOrder?.clientId
            
            let exchangeCartId = UUID()
            let newCart = UniversalCart(
                id: exchangeCartId,
                type: .pos,
                associateId: request.associateId,
                clientId: clientId,
                storeId: request.storeId,
                status: .completed,
                note: "Exchange Cart",
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let cartItem = UniversalCartItem(
                id: UUID(),
                cartId: exchangeCartId,
                productId: request.replacementProductId,
                quantity: request.quantity,
                unitPrice: NSDecimalNumber(decimal: request.replacementItemValue).doubleValue,
                discountApplied: 0.0,
                note: "Exchange Replacement"
            )
            
            let txn = Transaction(
                id: UUID(),
                cartId: exchangeCartId,
                storeId: request.storeId,
                associateId: request.associateId,
                clientId: clientId,
                totalAmount: amountDue,
                taxAmount: amountDue * 0.2 / 1.2,
                currency: "INR",
                status: .completed,
                isTaxFree: false,
                createdAt: Date()
            )
            
            let tender = Tender(
                id: UUID(),
                transactionId: txn.id,
                method: .card,
                amount: amountDue,
                reference: "online-payment-\(paymentId)"
            )
            
            let commissionRate = 0.05
            let commission = Commission(
                id: UUID(),
                staffId: request.associateId,
                transactionId: txn.id,
                amount: amountDue * commissionRate,
                rate: commissionRate,
                status: .pending,
                createdAt: Date()
            )
            
            do {
                _ = try await dataStore.createUniversalCart(newCart)
                _ = try await dataStore.createUniversalCartItem(cartItem)
                _ = try await dataStore.createTransaction(txn)
                _ = try await dataStore.createTender(tender)
                _ = try await dataStore.createCommission(commission)
            } catch {
                print("[ExchangePayment] Failed to record transaction/tender: \(error)")
            }

            // Update exchange status to completed in Supabase
            var updated = request
            updated.status = .completed
            updated.updatedAt = Date()
            
            let repo = ExchangeRepository(dataStore: dataStore)
            guard let user = appVM.currentUser else {
                print("[ExchangePayment] No current user to record audit")
                onPaymentSuccess(paymentId)
                return
            }
            
            do {
                try await repo.updateExchangeRequest(
                    updated,
                    user: user,
                    action: "Payment collected via Razorpay (ID: \(paymentId))",
                    prevStatus: .paymentPending
                )
            } catch {
                print("[ExchangePayment] Failed to update status: \(error)")
            }
            
            onPaymentSuccess(paymentId)
        }
    }
    
    private func detailRow(title: String, value: some StringProtocol) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(RSMSTheme.textPrimary)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

