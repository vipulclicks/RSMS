//
//  InspectionDetailView.swift
//  RSMS
//

import SwiftUI

enum InspectionRequestType: Hashable, Identifiable {
    case returnRequest(POSReturnRequest)
    case exchangeRequest(POSExchangeRequest)
    
    var id: UUID {
        switch self {
        case .returnRequest(let req): return req.id
        case .exchangeRequest(let req): return req.id
        }
    }
}

struct InspectionDetailView: View {
    let request: InspectionRequestType
    
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var condition: POSInspectionCondition = .new
    @State private var notes: String = ""
    @State private var isProcessing = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    
    private var productName: String {
        switch request {
        case .returnRequest(let req):
            return appVM.dataStore.productName(for: req.productId)
        case .exchangeRequest(let req):
            return appVM.dataStore.productName(for: req.originalProductId)
        }
    }
    
    private var isExchange: Bool {
        if case .exchangeRequest = request { return true }
        return false
    }
    
    private var replacementProductName: String? {
        if case .exchangeRequest(let req) = request {
            return appVM.dataStore.productName(for: req.replacementProductId)
        }
        return nil
    }
    
    private var quantity: Int {
        switch request {
        case .returnRequest(let req):
            return req.quantity
        case .exchangeRequest(let req):
            return req.quantity
        }
    }
    
    private var reason: String {
        switch request {
        case .returnRequest(let req):
            return req.reason
        case .exchangeRequest(let req):
            return req.reason
        }
    }
    
    private var orderId: UUID {
        switch request {
        case .returnRequest(let req):
            return req.orderId
        case .exchangeRequest(let req):
            return req.orderId
        }
    }
    
    var body: some View {
        Form {

            Section(isExchange ? "Original Product (Being Returned)" : "Product & Request Information") {
                LabeledContent("Product Name", value: productName)
                LabeledContent("Quantity", value: quantity, format: .number)
                LabeledContent("Reason", value: reason)
                LabeledContent("Original Order ID", value: orderId.uuidString)
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            // Exchange-specific: show replacement product and price difference
            if case .exchangeRequest(let exReq) = request {
                Section("Replacement Product (Being Given)") {
                    LabeledContent("Replacement Product", value: replacementProductName ?? "Unknown")
                    // Use catalog prices (single source of truth)
                    let origPrice = appVM.dataStore.resolvedPrice(for: exReq.originalProductId, fallback: NSDecimalNumber(decimal: exReq.returnedItemValue).doubleValue)
                    let replPrice = appVM.dataStore.resolvedPrice(for: exReq.replacementProductId, fallback: NSDecimalNumber(decimal: exReq.replacementItemValue).doubleValue)
                    LabeledContent("Original Value", value: origPrice * Double(exReq.quantity), format: .currency(code: "INR"))
                    LabeledContent("Replacement Value", value: replPrice * Double(exReq.quantity), format: .currency(code: "INR"))
                    LabeledContent("Difference") {
                        let diff = (replPrice - origPrice) * Double(exReq.quantity)
                        if abs(diff) < 0.01 {
                            Text("Even Exchange")
                                .foregroundStyle(RSMSTheme.success)
                                .fontWeight(.semibold)
                        } else if diff > 0 {
                            Text("Customer pays \(diff, format: .currency(code: "INR"))")
                                .foregroundStyle(RSMSTheme.danger)
                                .fontWeight(.semibold)
                        } else {
                            Text("Refund \(abs(diff), format: .currency(code: "INR"))")
                                .foregroundStyle(RSMSTheme.success)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .listRowBackground(RSMSTheme.surfacePrimary)
            }
            
            Section("Inspection Decision") {
                Picker("Product Condition", selection: $condition) {
                    ForEach(POSInspectionCondition.allCases) { cond in
                        Text(cond.rawValue).tag(cond)
                    }
                }
                
                TextField("Inspection Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...5)
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            

            Section {
                HStack(spacing: 20) {
                    Button(action: { Task { await processDecision(approved: false) } }) {
                        Text("Reject Request")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .background(RSMSTheme.danger, in: RoundedRectangle(cornerRadius: 10))
                    .buttonStyle(.plain)
                    
                    Button(action: { Task { await processDecision(approved: true) } }) {
                        Text("Approve Request")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .background(RSMSTheme.success, in: RoundedRectangle(cornerRadius: 10))
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.clear)
                .disabled(isProcessing)
            }
        }
        .navigationTitle(isExchange ? "Inspect Exchange" : "Inspect Return")
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
        .alert("Inspection Complete", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var inventoryPreviewText: String {
        switch condition {
        case .new:
            return "Item is in new condition. Will be returned to 'Showroom Floor' and added to Available stock (\(quantity) unit(s) will be added)."
        case .opened:
            return "Item was opened. Will be placed on hold in 'Inspection Hold Room' for further checks."
        case .used:
            return "Item was used. Will be placed on hold in 'Inspection Hold Room' for further checks."
        case .damaged:
            return "Item is damaged. Will be moved to 'Damaged Inventory Area' (marked as damaged, no resale)."
        case .defective:
            return "Item is defective. Will be moved to 'Defective Inventory Area' (marked as defective, no resale)."
        }
    }
    
    private func processDecision(approved: Bool) async {
        guard let currentUser = appVM.currentUser else { return }
        isProcessing = true
        
        do {
            let inspectionService = InventoryInspectionService.shared
            
            switch request {
            case .returnRequest(let req):
                var mutableReq = req
                let results = inspectionService.inspectReturn(
                    request: &mutableReq,
                    condition: condition,
                    notes: notes,
                    userId: currentUser.id
                )
                
                if approved {
                    mutableReq.status = .approved
                    // Reconcile stock
                    try await appVM.dataStore.reconcileStockItem(
                        productId: req.productId,
                        storeId: req.storeId,
                        quantity: quantity,
                        status: results.stockStatus,
                        location: results.location
                    )
                } else {
                    mutableReq.status = .rejected
                }
                
                let repository = ReturnRepository(dataStore: appVM.dataStore)
                try await repository.updateReturnRequest(
                    mutableReq,
                    user: currentUser,
                    action: approved ? "Return Approved" : "Return Rejected",
                    prevStatus: req.status
                )
                
                // If return is approved, we can trigger the refund right away
                if approved {
                    var refundedReq = mutableReq
                    refundedReq.status = .refunded
                    try await repository.updateReturnRequest(
                        refundedReq,
                        user: currentUser,
                        action: "Refund Processed",
                        prevStatus: .approved
                    )
                }
                
            case .exchangeRequest(let req):
                var mutableReq = req
                let results = inspectionService.inspectExchange(
                    request: &mutableReq,
                    condition: condition,
                    notes: notes,
                    userId: currentUser.id
                )
                
                if approved {
                    // Reconcile stock
                    try await appVM.dataStore.reconcileStockItem(
                        productId: req.originalProductId,
                        storeId: req.storeId,
                        quantity: quantity,
                        status: results.stockStatus,
                        location: results.location
                    )
                    
                    // Decrement stock for the replacement item
                    try await appVM.dataStore.reconcileStockItem(
                        productId: req.replacementProductId,
                        storeId: req.storeId,
                        quantity: -quantity,
                        status: .available,
                        location: "Showroom Floor"
                    )
                    
                    // Use catalog prices (single source of truth) instead of stale stored differenceAmount
                    let origCatalogPrice = appVM.dataStore.resolvedPrice(for: req.originalProductId)
                    let replCatalogPrice = appVM.dataStore.resolvedPrice(for: req.replacementProductId)
                    let catalogDiff = (replCatalogPrice - origCatalogPrice) * Double(quantity)
                    if abs(catalogDiff) < 0.01 {
                        mutableReq.status = .completed
                    } else {
                        // Payment pending for both:
                        // diff > 0: customer pays the extra
                        // diff < 0: store refunds the difference
                        mutableReq.status = .paymentPending
                    }
                } else {
                    mutableReq.status = .rejected
                }
                
                let repository = ExchangeRepository(dataStore: appVM.dataStore)
                try await repository.updateExchangeRequest(
                    mutableReq,
                    user: currentUser,
                    action: approved ? "Exchange Approved" : "Exchange Rejected",
                    prevStatus: req.status
                )
                
                // If approved and no payment pending, we can log complete
                if approved && mutableReq.status == .completed {
                    let audit = POSReturnAuditLog(
                        requestId: req.id,
                        requestType: "exchange",
                        userId: currentUser.id,
                        userRole: currentUser.role.rawValue,
                        action: "Exchange Completed",
                        previousStatus: "approved",
                        newStatus: "completed"
                    )
                    try await repository.createAuditLog(audit)
                }
            }
            
            alertMessage = approved ? "The request has been successfully approved and stock has been reconciled." : "The request has been rejected."
            showSuccessAlert = true
        } catch {
            alertMessage = "An error occurred: \(error.localizedDescription)"
            showSuccessAlert = true
        }
        
        isProcessing = false
    }
}
