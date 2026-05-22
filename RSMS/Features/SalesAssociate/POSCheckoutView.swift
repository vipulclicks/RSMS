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
    @State private var showCheckoutConfirmation = false
    @State private var showReturnSheet = false

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
        .alert("Complete Checkout?", isPresented: $showCheckoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm") {
                // Process checkout
            }
        } message: {
            Text("Total: ₹\(Int(viewModel.cartTotal).formatted()). This action will finalise the transaction.")
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
                showCheckoutConfirmation = true
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
                    .font(.system(size: 24, weight: .bold, design: .serif))
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
}

// MARK: - Screen ViewModel

@Observable
private final class POSCheckoutScreenViewModel {
    var selectedTab = 0
    var productSearch = ""
    var selectedTenderMethod = "Card"
    var isTaxFree = false

    // TODO: Replace mock data with DataStore
    private(set) var cartItems: [UniversalCartItem] = [UniversalCartItem.previewPOSItem]
    private(set) var availableDiscounts: [Discount] = Discount.all
    private(set) var transactions: [Transaction] = Transaction.all
    private(set) var exchangeReturns: [ExchangeReturn] = ExchangeReturn.all
    private(set) var products: [Product] = Product.all

    var cartSubtotal: Double {
        cartItems.reduce(0) { $0 + (($1.unitPrice ?? 0) * Double($1.quantity)) }
    }

    var cartTax: Double { cartSubtotal * 0.20 }
    var cartTotal: Double { cartSubtotal + cartTax }

    func productName(for id: UUID) -> String {
        products.first { $0.id == id }?.name ?? "Unknown"
    }

    func productPrice(for id: UUID) -> Double {
        products.first { $0.id == id }?.price ?? 0
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
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("₹\(Int(item.unitPrice ?? viewModel.productPrice(for: item.productId)).formatted())")
                    .font(.system(size: 15, weight: .bold, design: .serif))
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
                    .font(.system(size: 18, weight: .bold, design: .serif))
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
