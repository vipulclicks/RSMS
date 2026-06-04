//
//  StockInHubView.swift
//  RSMS
//
//  Hub screen for receiving inventory. Offers two paths:
//    1. Scan Barcode — item-by-item scanning via InventoryBarcodeScannerView
//    2. Match ASN    — receive against an Advanced Shipment Notice via ASNMatchingView
//
//  Live pending ASN count loaded from Supabase inventory_movements.
//  No hardcoded values.
//

import SwiftUI

struct StockInHubView: View {

    @Environment(AppViewModel.self) private var appVM
    @State private var pendingASNCount: Int = 0
    @State private var appeared = false

    // Navigation state
    @State private var navigateToBarcode = false
    @State private var navigateToASN = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        headerSection
                        modeCards
                        if pendingASNCount > 0 {
                            pendingASNBanner
                        }
                        howItWorkSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Stock In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToBarcode) {
                InventoryBarcodeScannerView(initialMode: .stockIn)
                    .navigationTitle("Scan Barcode")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationDestination(isPresented: $navigateToASN) {
                ASNMatchingView()
                    .environment(appVM)
            }
            .task {
                await loadPendingASNCount()
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stock In")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Choose how you're receiving inventory today")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    // MARK: - Mode Cards

    private var modeCards: some View {
        VStack(spacing: 16) {
            // Scan Barcode card
            modeCard(
                icon: "barcode.viewfinder",
                iconColor: RSMSTheme.gold,
                title: "Scan Barcode",
                subtitle: "ITEM BY ITEM",
                description: "Scan each product's barcode as it arrives. Stock quantities are updated in real time.",
                badgeText: nil,
                badgeColor: RSMSTheme.gold
            ) {
                navigateToBarcode = true
            }

            // Match ASN card
            modeCard(
                icon: "doc.badge.checkmark",
                iconColor: RSMSTheme.info,
                title: "Match ASN",
                subtitle: "SHIPMENT RECEIPT",
                description: "Enter or scan an ASN number to receive a full shipment and validate line-item quantities.",
                badgeText: pendingASNCount > 0 ? "\(pendingASNCount) Pending" : nil,
                badgeColor: RSMSTheme.warning
            ) {
                navigateToASN = true
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    private func modeCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        description: String,
        badgeText: String?,
        badgeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 18) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)

                        if let badge = badgeText {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .tracking(0.5)
                                .foregroundStyle(badgeColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(badgeColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(RSMSTheme.textTertiary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .padding(.top, 4)
            }
            .padding(20)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pending ASN Banner

    private var pendingASNBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.warning.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(RSMSTheme.warning)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(pendingASNCount) Shipment\(pendingASNCount == 1 ? "" : "s") Awaiting Receipt")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Open ASN matching to process incoming shipments")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            Spacer()

            Button {
                navigateToASN = true
            } label: {
                Text("Open")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.background)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(RSMSTheme.warning)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(RSMSTheme.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.warning.opacity(0.2), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - How It Works Section

    private var howItWorkSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HOW IT WORKS")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.gold)

            VStack(spacing: 0) {
                howItWorksRow(
                    number: "1",
                    title: "Barcode Scanning",
                    detail: "Scan each product one by one. System matches barcode to SKU and increments stock immediately."
                )
                Rectangle().fill(RSMSTheme.divider).frame(height: 0.5).padding(.horizontal, 16)
                howItWorksRow(
                    number: "2",
                    title: "ASN Matching",
                    detail: "Supplier sends an ASN before the shipment. Enter the ASN number, verify quantities per line item, and confirm receipt. Discrepancies are automatically logged as inventory variances."
                )
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func howItWorksRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.12))
                    .frame(width: 30, height: 30)
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.gold)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
    }

    // MARK: - Data Loading

    /// Counts in-transit movements with an ASN number destined for this store — no hardcoding.
    private func loadPendingASNCount() async {
        guard let storeId = appVM.currentStoreId else { return }

        if appVM.dataStore.inventoryMovements.isEmpty {
            try? await appVM.dataStore.fetchInventoryMovements()
        }

        let storeIdString = storeId.uuidString
        pendingASNCount = appVM.dataStore.inventoryMovements.filter { movement in
            movement.asnNumber != nil &&
            movement.status == .inTransit &&
            movement.destinationId == storeIdString
        }.count
    }
}

// MARK: - Previews

#Preview {
    StockInHubView()
        .environment(AppViewModel())
}
