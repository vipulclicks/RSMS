//
//  CartDiscountSheet.swift
//  RSMS
//
//  Luxury UI sheet for applying discounts to a Curated Cart.
//

import SwiftUI

struct CartDiscountSheet: View {
    let cartId: UUID
    let clientId: UUID
    let cartSubtotal: Double
    let associateId: UUID
    @Binding var appliedDiscount: CartDiscount?
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    @State private var selectedType: DiscountType = .percentage
    @State private var discountValueText: String = ""
    @State private var reasonForDiscount: String = ""
    @State private var errorMessage: String? = nil
    
    // Limits
    private let managerApprovalThresholdPercentage: Double = 10.0
    private let managerApprovalThresholdFixed: Double = 5000.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Discount Configuration").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                    HStack {
                        Text("Percentage")
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Spacer()
                        TextField("e.g. 5", text: $discountValueText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .onChange(of: discountValueText) { _, _ in
                                validate()
                            }
                        Text("%")
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.danger)
                    }
                }
                
                Section(header: Text("Context").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                    TextField("Reason for Discount (e.g. Client Birthday)", text: $reasonForDiscount)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Section(header: Text("Financial Summary").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                    summaryRow(label: "Original Subtotal", value: cartSubtotal, isHighlight: false)
                    
                    let savings = calculatedSavings
                    summaryRow(label: "Total Savings", value: -savings, isHighlight: true, color: RSMSTheme.danger)
                    
                    let finalTotal = max(0, cartSubtotal - savings)
                    summaryRow(label: "New Subtotal", value: finalTotal, isHighlight: true, isBold: true)
                }
                
                if isValid {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: requiresApproval ? "clock.fill" : "checkmark.seal.fill")
                            Text(requiresApproval ? "Requires Manager Approval" : "Auto-Approved")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(requiresApproval ? .orange : RSMSTheme.success)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Apply Discount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task {
                            await applyDiscount()
                        }
                    }
                    .disabled(!isValid)
                    .foregroundStyle(isValid ? RSMSTheme.primary : RSMSTheme.textTertiary)
                }
                
                if appliedDiscount != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Remove") {
                            if let pendingRequest = appVM.dataStore.discountApprovalRequests.first(where: { $0.cartId == cartId && $0.status == .pending }) {
                                Task {
                                    try? await appVM.dataStore.deleteApprovalRequest(id: pendingRequest.id)
                                }
                            }
                            
                            appliedDiscount = nil
                            dismiss()
                        }
                        .foregroundStyle(RSMSTheme.danger)
                    }
                }
            }
            .onAppear {
                if let existing = appliedDiscount {
                    selectedType = existing.type
                    if existing.type == .percentage {
                        discountValueText = String(format: "%.1f", existing.value)
                    } else {
                        discountValueText = String(format: "%.0f", existing.value)
                    }
                    validate()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var valueTitle: String {
        switch selectedType {
        case .percentage, .vip: return "Percentage (%)"
        case .promotional: return "Fixed Amount (₹)"
        }
    }
    
    private var valuePlaceholder: String {
        switch selectedType {
        case .percentage, .vip: return "e.g. 5"
        case .promotional: return "e.g. 5000"
        }
    }
    
    private var numericValue: Double {
        Double(discountValueText) ?? 0
    }
    
    private var calculatedSavings: Double {
        let val = numericValue
        switch selectedType {
        case .percentage, .vip:
            return cartSubtotal * (val / 100.0)
        case .promotional:
            return val
        }
    }
    
    private var isValid: Bool {
        errorMessage == nil && numericValue > 0
    }
    
    private var requiresApproval: Bool {
        let val = numericValue
        switch selectedType {
        case .percentage, .vip:
            return val > managerApprovalThresholdPercentage
        case .promotional:
            return val > managerApprovalThresholdFixed
        }
    }
    
    private func validate() {
        let val = numericValue
        
        if discountValueText.isEmpty {
            errorMessage = nil
            return
        }
        
        if val <= 0 {
            errorMessage = "Value must be greater than 0"
            return
        }
        
        switch selectedType {
        case .percentage, .vip:
            if val > 100 {
                errorMessage = "Percentage cannot exceed 100%"
            } else {
                errorMessage = nil
            }
        case .promotional:
            if val > cartSubtotal {
                errorMessage = "Discount cannot exceed subtotal (₹\(Int(cartSubtotal)))"
            } else {
                errorMessage = nil
            }
        }
    }
    
    private func applyDiscount() async {
        let status: DiscountApprovalStatus = requiresApproval ? .pending : .approved
        
        let newDiscount = CartDiscount(
            type: selectedType,
            value: numericValue,
            status: status,
            appliedBy: associateId,
            appliedAt: Date()
        )
        
        if requiresApproval {
            do {
                _ = try await appVM.dataStore.createApprovalRequest(
                    cartId: cartId,
                    clientId: clientId,
                    associateId: associateId,
                    discountType: selectedType,
                    discountValue: numericValue,
                    cartTotal: cartSubtotal,
                    reason: reasonForDiscount.isEmpty ? nil : reasonForDiscount
                )
            } catch {
                print("Failed to create approval request: \(error)")
            }
        }
        
        appliedDiscount = newDiscount
        dismiss()
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
}
