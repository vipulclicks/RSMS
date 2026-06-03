//
//  POSCheckoutView.swift
//  RSMS
//
//  Point of Sale checkout workflow — cart management, discount application,
//  tender selection, transaction history, and returns/exchanges.
//

import SwiftUI

struct POSCheckoutView: View {
    @State private var viewModel = POSCheckoutScreenViewModel()
    @State private var showPaymentSummary = false
    @State private var showReturnSheet = false
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("Section", selection: $viewModel.selectedTab) {
                    Text("Cart").tag(0)
                    Text("Transactions").tag(1)
                    Text("Returns").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(spacing: 20) {
                        switch viewModel.selectedTab {
                        case 0: cartSection
                        case 1: transactionSection
                        case 2: returnsSection
                        default: cartSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("POS & Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPaymentSummary) {
            // Provide the active cart. If none exists, we fallback to a mock one for the preview
            if let activeCart = appVM.dataStore.universalCarts.first(where: { $0.type == .pos && $0.status == .active }) {
                let checkoutVM = POSCheckoutViewModel(
                    dataStore: appVM.dataStore,
                    associateId: appVM.currentUser?.id ?? UUID(),
                    storeId: appVM.currentStoreId ?? UUID()
                )
                NavigationStack {
                    PaymentSummaryView(cart: activeCart, checkoutVM: checkoutVM)
                }
            } else {
                Text("Error: Failed to construct a fallback cart.")
            }
        }
        .onAppear {
            viewModel.dataStore = appVM.dataStore
        }
    }

    // MARK: - Cart Section

    private var cartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add product
            SectionHeader(title: "Active Cart", subtitle: "Scan or search to add products")

            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "barcode.viewfinder")
                    .foregroundStyle(RSMSTheme.textTertiary)
                TextField("Search by name or SKU…", text: $viewModel.productSearch)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))

            // Cart items
            if viewModel.cartItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart")
                        .font(.system(size: 40))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("Cart is empty")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .rsmsCard()
            } else {
                ForEach(viewModel.cartItems) { item in
                    POSCartItemRow(item: item, viewModel: viewModel)
                }
            }

            // Discounts
            if !viewModel.availableDiscounts.isEmpty {
                discountSection
            }

            // Cart Summary
            cartSummary

            // Checkout button
            Button {
                prepareFallbackCartIfNeeded()
                showPaymentSummary = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                    Text("Proceed to Checkout")
                }
                .font(.headline)
                .foregroundStyle(RSMSTheme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.cartItems.isEmpty
                             ? AnyShapeStyle(RSMSTheme.surfaceSecondary)
                             : AnyShapeStyle(RSMSTheme.primaryGradient))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: viewModel.cartItems.isEmpty
                        ? .clear : RSMSTheme.primary.opacity(0.3), radius: 12, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(viewModel.cartItems.isEmpty)
        }
    }

    // MARK: - Discount Section

    private var discountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Discounts")
            ForEach(viewModel.availableDiscounts) { discount in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(RSMSTheme.success.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "tag.fill")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.success)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(discount.code)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        if let conditions = discount.conditions {
                            Text(conditions)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                    Spacer()
                    Text(discount.type == .percentage
                         ? "\(Int(discount.value))% OFF"
                         : "₹\(Int(discount.value)) OFF")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RSMSTheme.success.opacity(0.10), in: Capsule())
                }
                .rsmsCard(padding: 14)
            }
        }
    }

    // MARK: - Cart Summary

    private var cartSummary: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text("₹\(Int(viewModel.cartSubtotal).formatted())")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            HStack {
                Text("Tax (20%)")
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text("₹\(Int(viewModel.cartTax).formatted())")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            Divider().overlay(RSMSTheme.divider)
            HStack {
                Text("Total")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                Text("₹\(Int(viewModel.cartTotal).formatted())")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(RSMSTheme.primary)
            }

            // Tender method
            LuxuryPicker(
                title: "Payment Method",
                selection: $viewModel.selectedTenderMethod,
                options: TenderMethod.allCases.map { $0.rawValue.replacingOccurrences(of: "_", with: " ").capitalized }
            )

            Toggle(isOn: $viewModel.isTaxFree) {
                Label("Tax-Free Purchase", systemImage: "doc.text")
                    .font(.subheadline)
            }
            .tint(RSMSTheme.primary)
        }
        .font(.subheadline)
        .rsmsCard()
    }

    // MARK: - Transaction History Section

    private var transactionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Transactions")

            ForEach(viewModel.transactions) { txn in
                POSTransactionCard(transaction: txn, viewModel: viewModel)
            }
        }
    }

    // MARK: - Returns Section

    private var returnsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Returns & Exchanges")
                Spacer()
                Button {
                    showReturnSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RSMSTheme.primary)
                }
                .accessibilityLabel("New Return")
            }

            ForEach(viewModel.exchangeReturns) { er in
                POSReturnCard(exchangeReturn: er, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Helper
    private func prepareFallbackCartIfNeeded() {
        if !appVM.dataStore.universalCarts.contains(where: { $0.type == .pos && $0.status == .active }) {
            // Ensure we have a dummy client for testing
            let clientId: UUID
            if let existing = appVM.dataStore.clients.first(where: { $0.fullName == "Sandbox User" }) {
                clientId = existing.id
            } else {
                clientId = UUID()
                let dummyClient = ClientProfile(
                    id: clientId, fullName: "Sandbox User", email: "test@example.com", phone: "+919876543210",
                    preferredStoreId: appVM.currentStoreId, vipTier: .standard, privacyConsentGiven: true, consentDate: Date(),
                    notes: nil, createdAt: Date(), updatedAt: Date(), shoeSize: nil, ringSize: nil, braceletSize: nil,
                    necklaceLength: nil, wristSize: nil, beltSize: nil, favoriteCategories: nil, favoriteMetals: nil,
                    favoriteGemstones: nil, shoeFitPreference: nil, preferredMetal: nil, preferredGemstone: nil,
                    watchCasePreference: nil, strapMaterialPreference: nil, preferredBagSize: nil, preferredBagStyle: nil,
                    preferredMaterial: nil, bucklePreference: nil, fragranceFamily: nil, fragranceStrength: nil,
                    scentPreference: nil, preferredBrands: nil, favoriteColors: nil, stylePreference: nil,
                    giftingPreference: nil, shoppingPreference: nil
                )
                appVM.dataStore.clients.append(dummyClient)
            }
            
            let newCart = UniversalCart(
                id: UUID(),
                type: .pos,
                associateId: appVM.currentUser?.id ?? UUID(),
                clientId: clientId,
                storeId: appVM.currentStoreId ?? UUID(),
                status: .active,
                note: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            appVM.dataStore.universalCarts.append(newCart)
            
            // Add items from viewModel
            for mockItem in viewModel.cartItems {
                let newItem = UniversalCartItem(
                    id: UUID(),
                    cartId: newCart.id,
                    productId: mockItem.productId,
                    quantity: mockItem.quantity,
                    unitPrice: mockItem.unitPrice,
                    discountApplied: nil,
                    note: nil
                )
                appVM.dataStore.universalCartItems.append(newItem)
            }
        }
    }

}

// MARK: - Screen ViewModel

@Observable
private final class POSCheckoutScreenViewModel {
    var dataStore: DataStore?
    var selectedTab = 0
    var productSearch = ""
    var selectedTenderMethod = "Card"
    var isTaxFree = false

    var activeCart: UniversalCart? {
        dataStore?.universalCarts.first(where: { $0.type == .pos && $0.status == .active })
    }

    var cartItems: [UniversalCartItem] {
        guard let cart = activeCart else { return [] }
        return dataStore?.universalCartItems.filter { $0.cartId == cart.id } ?? []
    }

    var availableDiscounts: [Discount] {
        dataStore?.discounts ?? []
    }

    var transactions: [Transaction] {
        dataStore?.transactions.sorted(by: { $0.createdAt > $1.createdAt }) ?? []
    }

    var exchangeReturns: [ExchangeReturn] {
        dataStore?.exchangeReturns.sorted(by: { $0.createdAt > $1.createdAt }) ?? []
    }

    var cartSubtotal: Double {
        cartItems.reduce(0) { total, item in
            let price = item.unitPrice ?? productPrice(for: item.productId)
            return total + (price * Double(item.quantity))
        }
    }

    var cartTax: Double { isTaxFree ? 0 : cartSubtotal * 0.20 }
    var cartTotal: Double { cartSubtotal + cartTax }

    func productName(for id: UUID) -> String {
        dataStore?.product(by: id)?.name ?? "Unknown"
    }

    func productPrice(for id: UUID) -> Double {
        dataStore?.product(by: id)?.price ?? 0
    }

    func transactionStatusColor(_ status: TransactionStatus) -> Color {
        switch status {
        case .pending:   return RSMSTheme.warning
        case .completed: return RSMSTheme.success
        case .voided:    return RSMSTheme.danger
        case .refunded:  return RSMSTheme.info
        }
    }

    func returnStatusColor(_ status: ExchangeReturnStatus) -> Color {
        switch status {
        case .pending:   return RSMSTheme.warning
        case .approved:  return RSMSTheme.info
        case .completed: return RSMSTheme.success
        case .rejected:  return RSMSTheme.danger
        }
    }
}

// MARK: - Cart Item Row

private struct POSCartItemRow: View {
    let item: UniversalCartItem
    let viewModel: POSCheckoutScreenViewModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(RSMSTheme.primary.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: "diamond.fill")
                    .foregroundStyle(RSMSTheme.primary.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.productName(for: item.productId))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("₹\(Int(item.unitPrice ?? viewModel.productPrice(for: item.productId)).formatted())")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(RSMSTheme.primary)
                if let discount = item.discountApplied, discount > 0 {
                    Text("-₹\(Int(discount).formatted())")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.success)
                }
            }
        }
        .rsmsCard(padding: 14)
    }
}

// MARK: - Transaction Card

private struct POSTransactionCard: View {
    let transaction: Transaction
    let viewModel: POSCheckoutScreenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order #\(transaction.id.uuidString.prefix(8).uppercased())")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(transaction.createdAt, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                StatusBadge(
                    text: transaction.status.rawValue,
                    color: viewModel.transactionStatusColor(transaction.status)
                )
            }

            Divider().overlay(RSMSTheme.divider)

            HStack {
                Label {
                    Text(transaction.currency)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } icon: {
                    Image(systemName: "banknote")
                        .foregroundStyle(RSMSTheme.textTertiary)
                }

                Spacer()

                Text("₹\(Int(transaction.totalAmount).formatted())")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(RSMSTheme.primary)
            }

            if transaction.isTaxFree {
                StatusBadge(text: "Tax-Free", color: RSMSTheme.info)
            }
        }
        .rsmsCard()
    }
}

// MARK: - Return Card

private struct POSReturnCard: View {
    let exchangeReturn: ExchangeReturn
    let viewModel: POSCheckoutScreenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(exchangeReturn.type == .exchange ? "Exchange" : "Return")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                StatusBadge(
                    text: exchangeReturn.status.rawValue,
                    color: viewModel.returnStatusColor(exchangeReturn.status)
                )
            }

            Text(exchangeReturn.reason)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)

            HStack {
                Text("Ref: #\(exchangeReturn.originalTransactionId.uuidString.prefix(8).uppercased())")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                Spacer()
                if let refund = exchangeReturn.refundAmount {
                    Text("₹\(Int(refund).formatted())")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RSMSTheme.danger)
                }
            }

            Text(exchangeReturn.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .rsmsCard()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        POSCheckoutView()
    }
}
