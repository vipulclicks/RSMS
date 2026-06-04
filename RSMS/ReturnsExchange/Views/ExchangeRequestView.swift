//
//  ExchangeRequestView.swift
//  RSMS
//

import SwiftUI

struct ExchangeRequestView: View {
    let order: Order
    let productToExchange: Product
    let remainingQty: Int
    let exchangeVM: POSExchangeViewModel
    
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    @State private var showProductPicker = false
    
    // Local state to avoid mutating the shared @Observable viewmodel
    // (which would trigger parent re-renders and destroy navigation state)
    @State private var selectedReplacement: Product?
    @State private var quantity: Int = 1
    @State private var reason: String = ""
    @State private var returnedValue: Decimal = 0
    @State private var replacementValue: Decimal = 0
    @State private var differenceAmount: Decimal = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    private let exchangeService = ExchangeService.shared
    
    var body: some View {
        Form {
            Section("Original Product Details") {
                LabeledContent("Name", value: productToExchange.name)
                LabeledContent("SKU", value: productToExchange.sku)
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section("Replacement Configuration") {
                Button {
                    showProductPicker = true
                } label: {
                    HStack {
                        Text("Select Replacement Product")
                            .foregroundStyle(RSMSTheme.primary)
                        Spacer()
                        if let repl = selectedReplacement {
                            Text(repl.name)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                }
                
                Stepper(value: $quantity, in: 1...remainingQty) {
                    LabeledContent("Quantity to Exchange", value: quantity, format: .number)
                }
                .onChange(of: quantity) {
                    recalculateLocally()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason for Exchange")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    TextField("Enter custom reason...", text: $reason, axis: .vertical)
                        .lineLimit(3...5)
                        .font(.body)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            if selectedReplacement != nil {
                Section("Financial Summary") {
                    LabeledContent("Returned Item Value", value: returnedValue, format: .currency(code: "INR"))
                    LabeledContent("Replacement Item Value", value: replacementValue, format: .currency(code: "INR"))
                    
                    HStack {
                        Text("Difference")
                            .fontWeight(.bold)
                        Spacer()
                        if differenceAmount == 0 {
                            Text("Even Exchange")
                                .fontWeight(.bold)
                                .foregroundStyle(RSMSTheme.success)
                        } else if differenceAmount > 0 {
                            Text("Customer Pays \(differenceAmount, format: .currency(code: "INR"))")
                                .fontWeight(.bold)
                                .foregroundStyle(RSMSTheme.danger)
                        } else {
                            Text("Store Refunds \(abs(differenceAmount), format: .currency(code: "INR"))")
                                .fontWeight(.bold)
                                .foregroundStyle(RSMSTheme.success)
                        }
                    }
                }
                .listRowBackground(RSMSTheme.surfacePrimary)
                
                Section {
                    Button(action: submitRequest) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Exchange Request")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .listRowBackground(RSMSTheme.primary)
                    .disabled(isLoading)
                }
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(RSMSTheme.danger)
                        .font(.subheadline)
                }
                .listRowBackground(Color.clear)
            }
            
            if let success = successMessage {
                Section {
                    Text(success)
                        .foregroundStyle(RSMSTheme.success)
                        .font(.subheadline)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Request Exchange")
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showProductPicker) {
            ProductSelectionView(
                products: appVM.dataStore.products.filter { $0.id != productToExchange.id },
                onSelect: { product in
                    selectedReplacement = product
                    recalculateLocally()
                }
            )
        }
    }
    
    // Calculate difference locally without touching the shared viewmodel
    private func recalculateLocally() {
        guard let replProduct = selectedReplacement else { return }
        
        let cartItems = appVM.dataStore.universalCartItems.filter { $0.cartId == order.cartId }
        guard let cartItem = cartItems.first(where: { $0.productId == productToExchange.id }) else { return }
        
        let results = exchangeService.calculateExchangeDifference(
            originalItem: cartItem,
            replacementProduct: replProduct,
            quantity: quantity
        )
        
        returnedValue = results.returnedValue
        replacementValue = results.replacementValue
        differenceAmount = results.difference
    }
    
    private func submitRequest() {
        guard let associateId = appVM.currentUser?.id else { return }
        guard let replProduct = selectedReplacement else {
            errorMessage = "Please select a replacement product first."
            return
        }
        
        let storeId = appVM.currentUser?.storeId ?? appVM.dataStore.stores.first?.id ?? UUID(uuidString: "3f89979f-c73f-4a55-bb08-bb0726d74920")!
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            // 1. Fetch fresh stock items and returns/exchanges from Supabase before validating
            try? await appVM.dataStore.fetchStockItems(storeId: storeId)
            await appVM.dataStore.fetchPOSReturnsExchanges()
            
            // 2. Validate locally without touching the shared viewmodel
            let cartItems = appVM.dataStore.universalCartItems.filter { $0.cartId == order.cartId }
            
            let validationResult = exchangeService.validateExchangeEligibility(
                order: order,
                originalProductId: productToExchange.id,
                replacementProductId: replProduct.id,
                quantity: quantity,
                cartItems: cartItems,
                existingReturns: appVM.dataStore.posReturnRequests,
                existingExchanges: appVM.dataStore.posExchangeRequests,
                stockItems: appVM.dataStore.stockItems,
                storeId: storeId
            )
            
            switch validationResult {
            case .failure(let error):
                errorMessage = error.localizedDescription
                isLoading = false
                return
            case .success:
                break
            }
            
            // 3. Build request and persist directly via the repository
            recalculateLocally()
            
            let request = POSExchangeRequest(
                orderId: order.id,
                originalProductId: productToExchange.id,
                replacementProductId: replProduct.id,
                quantity: quantity,
                reason: reason,
                status: .inspectionPending,
                returnedItemValue: returnedValue,
                replacementItemValue: replacementValue,
                differenceAmount: differenceAmount,
                storeId: storeId,
                associateId: associateId
            )
            
            do {
                try await exchangeVM.exchangeRepository.createExchangeRequest(request)
                successMessage = "Exchange request submitted successfully and is pending inspection."
                isLoading = false
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Product Selection Sheet

struct ProductSelectionView: View {
    let products: [Product]
    let onSelect: (Product) -> Void
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(filteredProducts) { product in
                Button {
                    onSelect(product)
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        ProductRowImageView(product: product)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("SKU: \(product.sku)")
                                .font(.caption.monospaced())
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        Spacer()
                        Text(product.price, format: .currency(code: "INR"))
                            .fontWeight(.semibold)
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(RSMSTheme.surfacePrimary)
            }
            .searchable(text: $searchText, prompt: "Search products...")
            .navigationTitle("Select Product")
            .scrollContentBackground(.hidden)
            .background(RSMSTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.primary)
                }
            }
        }
    }
    
    var filteredProducts: [Product] {
        if searchText.isEmpty { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sku.localizedCaseInsensitiveContains(searchText)
        }
    }
}
