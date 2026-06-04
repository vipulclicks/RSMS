//
//  ApprovalDetailScreen.swift
//  RSMS
//

import SwiftUI

struct ApprovalDetailScreen: View {
    let request: DiscountApprovalRequest
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var managerNotes: String = ""
    @State private var isProcessing: Bool = false
    
    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header / Client Info
                    LuxuryFormCard(title: "Request Details", icon: "doc.text.fill") {
                        VStack(spacing: 16) {
                            detailRow(label: "Client", value: appVM.dataStore.clientName(for: request.clientId))
                            detailRow(label: "Sales Associate", value: appVM.dataStore.userName(for: request.associateId))
                            if let reason = request.reasonForDiscount {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Associate Notes")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Text(reason)
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .italic()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    
                    // Cart Summary
                    LuxuryFormCard(title: "Financials", icon: "chart.bar.doc.horizontal") {
                        VStack(spacing: 12) {
                            summaryRow(label: "Cart Total", value: request.cartTotal, isHighlight: false)
                            
                            let savings = request.discountType == .percentage ? (request.cartTotal * (request.discountValue / 100.0)) : request.discountValue
                            let savingsStr = request.discountType == .percentage ? " (\(Int(request.discountValue))%)" : ""
                            
                            summaryRow(label: "Requested Discount\(savingsStr)", value: -savings, isHighlight: true, color: RSMSTheme.danger)
                            
                            Divider().overlay(RSMSTheme.divider)
                            
                            let finalTotal = max(0, request.cartTotal - savings)
                            summaryRow(label: "Final Amount", value: finalTotal, isHighlight: true, isBold: true)
                        }
                    }
                    
                    // Action Area
                    if request.status == .pending {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Manager Notes (Required for Rejection)")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                TextField("Add comments...", text: $managerNotes, axis: .vertical)
                                    .lineLimit(3...5)
                                    .padding()
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(RSMSTheme.border, lineWidth: 1)
                                    )
                            }
                            
                            HStack(spacing: 16) {
                                Button {
                                    Task { await processRequest(approved: false) }
                                } label: {
                                    Text("Reject")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.danger)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(RSMSTheme.danger.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .disabled(managerNotes.isEmpty || isProcessing)
                                
                                Button {
                                    Task { await processRequest(approved: true) }
                                } label: {
                                    Text("Approve")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.cream)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(AnyShapeStyle(RSMSTheme.success))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .disabled(isProcessing)
                            }
                        }
                    } else {
                        // Already processed
                        LuxuryFormCard(title: "Decision", icon: request.status == .approved ? "checkmark.seal.fill" : "xmark.octagon.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                detailRow(label: "Status", value: request.status.rawValue.capitalized)
                                if let date = request.decisionDate {
                                    detailRow(label: "Date", value: date.formatted(date: .abbreviated, time: .shortened))
                                }
                                if let notes = request.managerNotes {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Manager Notes")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                        Text(notes)
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .italic()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Approval Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
    }
    
    private func summaryRow(label: String, value: Double, isHighlight: Bool, isBold: Bool = false, color: Color = RSMSTheme.textPrimary) -> some View {
        HStack {
            Text(label)
                .font(isBold ? .headline : .subheadline)
                .foregroundStyle(isHighlight ? color : RSMSTheme.textSecondary)
            Spacer()
            Text((value < 0 ? "-" : "") + "₹\(Int(abs(value)).formatted())")
                .font(isBold ? .title3.weight(.bold) : .subheadline.weight(.semibold))
                .foregroundStyle(isHighlight ? color : RSMSTheme.textPrimary)
        }
    }
    
    private func processRequest(approved: Bool) async {
        guard let managerId = appVM.currentUser?.id else { return }
        isProcessing = true
        
        do {
            // 1. Update the approval request record in the DB
            try await appVM.dataStore.updateApprovalRequestStatus(
                requestId: request.id,
                managerId: managerId,
                newStatus: approved ? .approved : .rejected,
                managerNotes: managerNotes.isEmpty ? nil : managerNotes
            )
            
            // 2. Fetch the cart directly from DB (it may not be in Manager's local cache)
            //    and update the embedded CartDiscount status in the note field
            do {
                let cart: UniversalCart = try await appVM.dataStore.api.fetchById("universal_carts", id: request.cartId)
                if var discount = cart.appliedDiscount {
                    discount.status = approved ? .approved : .rejected
                    let updatedCart = cart.applyingDiscount(discount)
                    try await appVM.dataStore.api.update("universal_carts", id: cart.id, record: updatedCart)
                }
            } catch {
                print("Failed to update cart discount status: \(error)")
            }
            
            // 3. Re-fetch approval requests so the dashboard list updates immediately
            try? await appVM.dataStore.fetchDiscountApprovalRequests()
            
            dismiss()
        } catch {
            print("Failed to process request: \(error)")
        }
        isProcessing = false
    }
}
