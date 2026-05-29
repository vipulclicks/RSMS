//
//  ScanResultSheet.swift
//  RSMS
//
//  Sheet presented after every barcode scan. Handles four states:
//  found · not-found · duplicate · error — each with its own UI and actions.
//  Colors sourced from RSMSTheme.
//

import SwiftUI

// MARK: - Scan Result Sheet

struct ScanResultSheet: View {

    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss

    var scannerVM: BarcodeScannerViewModel

    @State private var enteredCount: String = ""
    @State private var hasInitializedCount: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    resultContent
                }
                .padding(20)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(navigationTitle)
                        .font(.system(.headline, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch scannerVM.state {
        case .found:              return "SCAN RESULT"
        case .notFound:           return "NOT FOUND"
        case .duplicate:          return "DUPLICATE"
        case .error:              return "ERROR"
        case .idle, .loading:     return ""
        }
    }

    // MARK: - Content Router

    @ViewBuilder
    private var resultContent: some View {
        switch scannerVM.state {
        case .found(let product, let stockItem):
            foundView(product: product, stockItem: stockItem)
                .onAppear {
                    if !hasInitializedCount {
                        enteredCount = "\(stockItem?.quantity ?? 0)"
                        hasInitializedCount = true
                    }
                }
        case .notFound(let barcode):
            notFoundView(barcode: barcode)
        case .duplicate(let product):
            duplicateView(product: product)
        case .error(let message):
            errorView(message: message)
        case .idle, .loading:
            EmptyView()
        }
    }

    // MARK: - Found State

    private func foundView(product: Product, stockItem: StockItem?) -> some View {
        VStack(spacing: 16) {
            statusIcon(systemName: "checkmark.circle.fill", color: RSMSTheme.success)

            VStack(spacing: 14) {
                Text(product.name)
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(product.sku)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(RSMSTheme.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.gold.opacity(0.08))
                    .clipShape(Capsule())

                Rectangle().fill(RSMSTheme.divider).frame(height: 1)

                VStack(spacing: 10) {
                    resultRow(label: "Category", value: product.category)
                    resultRow(label: "Brand", value: product.brand)
                    resultRow(
                        label: "Price",
                        value: "\(product.currency) \(Int(product.price).formatted())"
                    )
                    if let stockItem {
                        Rectangle().fill(RSMSTheme.divider).frame(height: 1)
                        resultRow(
                            label: "Current Stock",
                            value: "\(stockItem.quantity) units",
                            valueColor: stockItem.quantity <= 5 ? RSMSTheme.warning : RSMSTheme.success
                        )
                        
                        if scannerVM.scanMode == .verification {
                            Rectangle().fill(RSMSTheme.divider).frame(height: 1)
                            
                            HStack {
                                Text("Actual Count")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Spacer()
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if let val = Int(enteredCount), val > 0 {
                                            enteredCount = "\(val - 1)"
                                        } else if enteredCount.isEmpty {
                                            enteredCount = "0"
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    
                                    TextField("0", text: $enteredCount)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .font(.title3.bold())
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .frame(width: 50)
                                    
                                    Button(action: {
                                        let val = Int(enteredCount) ?? 0
                                        enteredCount = "\(val + 1)"
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if let location = stockItem.location {
                            resultRow(label: "Location", value: location)
                        }
                    } else {
                        Rectangle().fill(RSMSTheme.divider).frame(height: 1)
                        resultRow(
                            label: "Current Stock",
                            value: "Not tracked at this store",
                            valueColor: RSMSTheme.textTertiary
                        )
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.border, lineWidth: 1))

            modeBadge
            confirmButton(product: product, stockItem: stockItem)
            scanAgainButton
        }
    }

    // MARK: - Not Found State

    private func notFoundView(barcode: String) -> some View {
        VStack(spacing: 16) {
            statusIcon(systemName: "questionmark.circle.fill", color: RSMSTheme.danger)

            VStack(spacing: 12) {
                Text("Unrecognized Barcode")
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)

                Text(barcode)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.danger.opacity(0.06))
                    .clipShape(Capsule())

                Text("This code does not match any product in the system.\nVerify the barcode and try again.")
                    .font(.callout)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(RSMSTheme.danger.opacity(0.18), lineWidth: 1)
            )

            scanAgainButton
        }
    }

    // MARK: - Duplicate State

    private func duplicateView(product: Product) -> some View {
        VStack(spacing: 16) {
            statusIcon(systemName: "exclamationmark.triangle.fill", color: RSMSTheme.warning)

            VStack(spacing: 12) {
                Text("Already Scanned")
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)

                Text(product.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Text(product.sku)
                    .font(.caption.monospaced())
                    .foregroundStyle(RSMSTheme.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RSMSTheme.gold.opacity(0.08))
                    .clipShape(Capsule())

                Text("This product was already processed in this session.\nTap 'Force Add' only if you intend to add it again.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(RSMSTheme.warning.opacity(0.25), lineWidth: 1)
            )

            // Force-add button
            let stockItem = appVM.dataStore.stockItems.first {
                $0.productId == product.id && $0.storeId == appVM.currentStoreId
            }
            Button {
                Task {
                    await scannerVM.forceConfirm(
                        product: product,
                        stockItem: stockItem,
                        enteredCount: Int(enteredCount),
                        dataStore: appVM.dataStore,
                        user: appVM.currentUser!
                    )
                }
            } label: {
                HStack(spacing: 8) {
                    if scannerVM.isConfirming {
                        ProgressView().tint(RSMSTheme.background)
                    } else {
                        Image(systemName: "plus.circle.fill")
                        Text("Force Add")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(RSMSTheme.background)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RSMSTheme.warning)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(scannerVM.isConfirming || appVM.currentUser == nil)

            scanAgainButton
        }
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            statusIcon(systemName: "xmark.circle.fill", color: RSMSTheme.danger)

            VStack(spacing: 10) {
                Text("Something Went Wrong")
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)

                Text(message)
                    .font(.callout)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(RSMSTheme.danger.opacity(0.18), lineWidth: 1)
            )

            scanAgainButton
        }
    }

    // MARK: - Reusable Components

    private func statusIcon(systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.10))
                .frame(width: 72, height: 72)
            Image(systemName: systemName)
                .font(.system(size: 34))
                .foregroundStyle(color)
        }
    }

    private var modeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: scannerVM.scanMode.icon)
                .font(.caption.weight(.medium))
            Text(scannerVM.scanMode.rawValue)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(scannerVM.scanMode.badgeColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(scannerVM.scanMode.badgeColor.opacity(0.10))
        .clipShape(Capsule())
    }

    private func confirmButton(product: Product, stockItem: StockItem?) -> some View {
        Button {
            guard let user = appVM.currentUser else { return }
            Task {
                await scannerVM.confirm(
                    product: product,
                    stockItem: stockItem,
                    enteredCount: Int(enteredCount),
                    dataStore: appVM.dataStore,
                    user: user
                )
            }
        } label: {
            HStack(spacing: 8) {
                if scannerVM.isConfirming {
                    ProgressView().tint(RSMSTheme.background)
                } else {
                    Image(systemName: scannerVM.scanMode.icon)
                    Text(confirmButtonLabel)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(RSMSTheme.background)
            .frame(maxWidth: .infinity)
            .padding()
            .background(RSMSTheme.gold)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(scannerVM.isConfirming || appVM.currentUser == nil)
    }

    private var confirmButtonLabel: String {
        switch scannerVM.scanMode {
        case .stockIn:      return "Add to Inventory"
        case .verification: return "Count"
        case .audit:        return "Record in Audit"
        }
    }

    private var scanAgainButton: some View {
        Button { dismiss() } label: {
            Text("Scan Again")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
        }
    }

    private func resultRow(
        label: String,
        value: String,
        valueColor: Color = RSMSTheme.textPrimary
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueColor)
        }
    }
}
