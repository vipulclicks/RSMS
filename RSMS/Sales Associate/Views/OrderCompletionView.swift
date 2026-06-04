//
//  OrderCompletionView.swift
//  RSMS
//

import SwiftUI

struct OrderCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    
    let order: Order
    let client: ClientProfile
    let paymentId: String
    let cartItems: [UniversalCartItem]
    var giftReceipts: [GiftReceipt] = []     // default empty — no breaking change to existing call sites
    
    @State private var showReceipt = false
    @State private var showGiftReceipt = false
    @State private var selectedGiftReceipt: GiftReceipt?
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(RSMSTheme.success)
                
                VStack(spacing: 8) {
                    Text("Order Successfully Created")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    Text("Order #\(order.id.uuidString.prefix(8).uppercased())")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                
                VStack(spacing: 16) {
                    detailRow(title: "Payment ID", value: paymentId)
                    detailRow(title: "Date", value: Date().formatted(date: .abbreviated, time: .shortened))
                    detailRow(title: "Client", value: client.fullName)
                    detailRow(title: "Amount Paid", value: "₹\(Int(order.finalAmount).formatted())")
                }
                .padding()
                .rsmsCard()
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        showReceipt = true
                    } label: {
                        Text("View Receipt")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    if !giftReceipts.isEmpty {
                        Button {
                            selectedGiftReceipt = giftReceipts.first
                            showGiftReceipt = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "gift")
                                Text(giftReceipts.count == 1
                                     ? "View Gift Receipt"
                                     : "View Gift Receipts (\(giftReceipts.count))")
                            }
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Button {
                        // Return to root or dismiss entirely
                        // In a real flow, you'd pop back to the client profile.
                        dismiss()
                    } label: {
                        Text("Return to Client Profile")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showReceipt) {
            ReceiptView(order: order, client: client, paymentId: paymentId, cartItems: cartItems)
        }
        .sheet(isPresented: $showGiftReceipt) {
            if let gr = selectedGiftReceipt {
                GiftReceiptPreviewView(
                    giftReceipt: gr,
                    order: order,
                    cartItems: cartItems
                )
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
    }
}
