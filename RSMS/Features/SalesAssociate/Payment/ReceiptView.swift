//
//  ReceiptView.swift
//  RSMS
//

import SwiftUI

struct ReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM

    let order: Order
    let client: ClientProfile
    let paymentId: String
    
    // In a real app we might fetch the items from the cart.
    // Here we'll pass them in or fetch them from DataStore
    let cartItems: [UniversalCartItem]
    @State private var localCartItems: [UniversalCartItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(RSMSTheme.gold)
                        Text("Maison Lumière")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Official Receipt")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .padding(.top, 24)
                    
                    // Order Info
                    VStack(spacing: 12) {
                        detailRow(title: "Order ID", value: order.id.uuidString.prefix(8).uppercased())
                        detailRow(title: "Date", value: order.createdAt.formatted())
                        detailRow(title: "Customer", value: client.fullName)
                        detailRow(title: "Contact", value: client.phone ?? "")
                    }
                    .padding()
                    .rsmsCard()
                    
                    // Items
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Items")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        ForEach(localCartItems) { item in
                            HStack {
                                Text("\(item.quantity)x")
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Text(appVM.dataStore.productName(for: item.productId))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Spacer()
                                let price = item.unitPrice ?? appVM.dataStore.product(by: item.productId)?.price ?? 0
                                Text("₹\(Int(price).formatted())")
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .rsmsCard()
                    
                    // Financials
                    VStack(spacing: 12) {
                        detailRow(title: "Subtotal", value: "₹\(Int(order.totalAmount).formatted())")
                        if order.discountAmount > 0 {
                            detailRow(title: "Discount", value: "-₹\(Int(order.discountAmount).formatted())", color: RSMSTheme.success)
                        }
                        Divider()
                        HStack {
                            Text("Total Paid")
                                .font(.headline)
                            Spacer()
                            Text("₹\(Int(order.finalAmount).formatted())")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(RSMSTheme.primary)
                        }
                    }
                    .padding()
                    .rsmsCard()
                    
                    // Payment Info
                    VStack(spacing: 12) {
                        detailRow(title: "Payment Method", value: "Razorpay (Sandbox)")
                        detailRow(title: "Transaction Ref", value: paymentId)
                    }
                    .padding()
                    .rsmsCard()
                    
                    // Tax-Free Refund Section (If Applied)
                    if let taxFree = appVM.dataStore.taxFreeTransactions.first(where: { $0.orderId == order.id }) {
                        let layout = TaxFreeReceiptGenerator.generateLayout(
                            transactionId: taxFree.id,
                            passportNumber: taxFree.passportNumber,
                            countryOfResidence: taxFree.countryOfResidence,
                            taxAmount: taxFree.taxAmount,
                            refundAmount: taxFree.refundAmount
                        )
                        
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("Tax-Free Shopping Receipt", systemImage: "globe")
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.primary)
                                Spacer()
                            }
                            
                            Divider().overlay(RSMSTheme.divider)
                            
                            VStack(spacing: 10) {
                                detailRow(title: "Tax-Free Ref", value: layout.refNumber)
                                detailRow(title: "Passport Number", value: layout.passportNumber)
                                detailRow(title: "Country of Residence", value: layout.country)
                                detailRow(title: "VAT/GST Paid", value: "₹\(Int(truncating: layout.taxAmount as NSDecimalNumber).formatted())")
                                detailRow(title: "Refund Amount", value: "₹\(Int(truncating: layout.refundAmount as NSDecimalNumber).formatted())", color: RSMSTheme.success)
                            }
                            
                            Divider().overlay(RSMSTheme.divider)
                            
                            Text(layout.message)
                                .font(.system(size: 10).weight(.bold))
                                .foregroundStyle(RSMSTheme.textTertiary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                            
                            // QR Code Customs Verification Placeholder
                            VStack(spacing: 8) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 64))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                
                                Text("Scan at Customs Airport Kiosk")
                                    .font(.caption2.bold())
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                
                                Text(layout.qrCodeContent)
                                    .font(.system(size: 8).monospaced())
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RSMSTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .rsmsCard()
                    }
                }
                .padding(.horizontal, 24)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: "Receipt for Order \(order.id.uuidString.prefix(8)) - ₹\(order.finalAmount)") {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                if cartItems.isEmpty {
                    do {
                        try await appVM.dataStore.fetchUniversalCartItems(cartId: order.cartId)
                        localCartItems = appVM.dataStore.universalCartItems.filter { $0.cartId == order.cartId }
                    } catch {
                        print("Error fetching items for receipt: \(error)")
                    }
                } else {
                    localCartItems = cartItems
                }
            }
        }
    }
    
    private func detailRow(title: String, value: String, color: Color = RSMSTheme.textPrimary) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(color)
        }
        .font(.subheadline)
    }
}
