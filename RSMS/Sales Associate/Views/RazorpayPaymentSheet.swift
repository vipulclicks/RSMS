//
//  RazorpayPaymentSheet.swift
//  RSMS
//

import SwiftUI

enum PaymentSheetState {
    case loading
    case checkout(RazorpayOrder)
    case success(paymentId: String, amount: Double, date: Date)
    case failure(reason: String)
}

struct RazorpayPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    let cart: UniversalCart
    let amount: Double
    let client: ClientProfile
    
    let onPaymentSuccess: (String) -> Void
    
    @State private var state: PaymentSheetState = .loading
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                switch state {
                case .loading:
                    ProgressView("Initializing Payment...")
                        .tint(RSMSTheme.primary)
                        .onAppear {
                            createOrder()
                        }
                        
                case .checkout(let order):
                    RazorpayCheckoutWebView(
                        orderId: order.id,
                        amount: order.amount,
                        currency: order.currency,
                        customerName: client.fullName,
                        email: client.email ?? "no-email@example.com",
                        phone: client.phone ?? "",
                        cartId: cart.id.uuidString,
                        clientId: client.id.uuidString,
                        onSuccess: { result in
                            state = .success(paymentId: result.paymentId, amount: amount, date: Date())
                            onPaymentSuccess(result.paymentId)
                        },
                        onFailure: { reason in
                            state = .failure(reason: reason)
                        },
                        onDismiss: {
                            dismiss()
                        }
                    )
                    
                case .success(let paymentId, let amount, let date):
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(RSMSTheme.success)
                        
                        Text("Payment Successful")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        VStack(spacing: 12) {
                            detailRow(title: "Payment ID", value: paymentId)
                            detailRow(title: "Amount Paid", value: "₹\(Int(amount).formatted())")
                            detailRow(title: "Date", value: date.formatted())
                            detailRow(title: "Client", value: client.fullName)
                        }
                        .padding()
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button {
                            // Close the sheet since we're advancing in the background
                            dismiss()
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.cream)
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
                            .font(.largeTitle)
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
                                    .foregroundStyle(RSMSTheme.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RSMSTheme.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("Back to Summary")
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if case .loading = state {
                        Button("Cancel") {
                            dismiss()
                        }
                    } else if case .checkout = state {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func createOrder() {
        Task {
            do {
                let order = try await RazorpayService.createOrder(amount: amount, receipt: cart.id.uuidString)
                state = .checkout(order)
            } catch {
                state = .failure(reason: error.localizedDescription)
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
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
