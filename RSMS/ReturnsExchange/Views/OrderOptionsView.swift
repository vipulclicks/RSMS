//
//  OrderOptionsView.swift
//  RSMS
//

import SwiftUI

struct OrderOptionsView: View {
    let order: Order
    let returnVM: POSReturnViewModel
    let exchangeVM: POSExchangeViewModel
    @Environment(AppViewModel.self) private var appVM
    
    struct ReturnRoute: Identifiable, Hashable {
        var id: UUID { product.id }
        let order: Order
        let product: Product
        let remainingQty: Int
    }
    
    struct ExchangeRoute: Identifiable, Hashable {
        var id: UUID { productToExchange.id }
        let order: Order
        let productToExchange: Product
        let remainingQty: Int
    }
    
    @State private var activeReturnRoute: ReturnRoute?
    @State private var activeExchangeRoute: ExchangeRoute?
    
    var body: some View {
        List {
            Section("Order Information") {
                LabeledContent("Order ID", value: order.id.uuidString)
                LabeledContent("Date", value: order.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Customer", value: appVM.dataStore.clientName(for: order.clientId))
                LabeledContent("Order Status", value: order.status.rawValue.capitalized)
                LabeledContent("Total Amount", value: order.finalAmount, format: .currency(code: "INR"))
            }
            .listRowBackground(RSMSTheme.surfacePrimary)
            
            Section("Purchased Products") {
                let items = returnVM.getCartItems(for: order)
                if items.isEmpty {
                    Text("No items found for this order.")
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .listRowBackground(RSMSTheme.surfacePrimary)
                } else {
                    ForEach(items) { item in
                        if let product = returnVM.getProduct(for: item.productId) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name)
                                            .font(.headline)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Text("SKU: \(product.sku)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Purchased: \(item.quantity)")
                                            .font(.subheadline)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        let unit = item.unitPrice ?? 0.0
                                        let disc = item.discountApplied ?? 0.0
                                        Text(unit - disc, format: .currency(code: "INR"))
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                }
                                
                                let remaining = returnVM.getRemainingEligibleQuantity(for: order, productId: product.id)
                                HStack {
                                    Text("Eligible Qty: \(remaining)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(remaining > 0 ? RSMSTheme.success : RSMSTheme.danger)
                                    Spacer()
                                    
                                    if remaining > 0 {
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                activeReturnRoute = ReturnRoute(order: order, product: product, remainingQty: remaining)
                                            }) {
                                                Text("Return")
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(RSMSTheme.primary)
                                            
                                            Button(action: {
                                                activeExchangeRoute = ExchangeRoute(order: order, productToExchange: product, remainingQty: remaining)
                                            }) {
                                                Text("Exchange")
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(RSMSTheme.primary)
                                        }
                                    } else {
                                        Text("Returned or Exchanged")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(RSMSTheme.surfacePrimary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Order details")
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationDestination(item: $activeReturnRoute) { route in
            ReturnRequestView(order: route.order, product: route.product, remainingQty: route.remainingQty, returnVM: returnVM)
        }
        .navigationDestination(item: $activeExchangeRoute) { route in
            ExchangeRequestView(order: route.order, productToExchange: route.productToExchange, remainingQty: route.remainingQty, exchangeVM: exchangeVM)
        }
        .task {
            do {
                try await appVM.dataStore.fetchUniversalCartItems(cartId: order.cartId)
                await appVM.dataStore.fetchPOSReturnsExchanges()
            } catch {
                print("Failed to fetch cart items for order \(order.id): \(error)")
            }
        }
    }
}
