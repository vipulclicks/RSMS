//
//  ReturnRequestView.swift
//  RSMS
//

import SwiftUI

struct ReturnRequestView: View {
    let order: Order
    let product: Product
    let remainingQty: Int
    let returnVM: POSReturnViewModel
    
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Product Details") {
                LabeledContent("Name", value: product.name)
                LabeledContent("SKU", value: product.sku)
                LabeledContent("Purchase Date", value: order.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section("Return Configuration") {
                Stepper(value: Bindable(returnVM).quantity, in: 1...remainingQty) {
                    LabeledContent("Quantity to Return", value: returnVM.quantity, format: .number)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason for Return")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    TextField("Enter custom reason...", text: Bindable(returnVM).reason, axis: .vertical)
                        .lineLimit(3...5)
                        .font(.body)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section("Refund Preview") {
                let items = returnVM.getCartItems(for: order)
                if let cartItem = items.first(where: { $0.productId == product.id }) {
                    let refundAmt = ReturnService.shared.calculateRefundAmount(cartItem: cartItem, quantity: returnVM.quantity)
                    LabeledContent("Estimated Refund Amount", value: refundAmt, format: .currency(code: "INR"))
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.success)
                }
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section {
                Button(action: submitRequest) {
                    if returnVM.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Submit Return Request")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .listRowBackground(RSMSTheme.primary)
                .disabled(returnVM.isLoading)
            }
            
            if let error = returnVM.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(RSMSTheme.danger)
                        .font(.subheadline)
                }
                .listRowBackground(Color.clear)
            }
            
            if let success = returnVM.successMessage {
                Section {
                    Text(success)
                        .foregroundStyle(RSMSTheme.success)
                        .font(.subheadline)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Request Return")
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
        .task {
            if returnVM.selectedOrder?.id != order.id || returnVM.selectedProduct?.id != product.id {
                returnVM.selectOrder(order)
                returnVM.selectedProduct = product
                returnVM.quantity = 1
            }
        }
    }
    
    private func submitRequest() {
        guard let associateId = appVM.currentUser?.id else {
            return
        }
        let storeId = appVM.currentUser?.storeId ?? appVM.dataStore.stores.first?.id ?? UUID(uuidString: "3f89979f-c73f-4a55-bb08-bb0726d74920")!
        Task {
            await returnVM.submitReturnRequest(associateId: associateId, storeId: storeId)
            if returnVM.errorMessage == nil {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            }
        }
    }
}
