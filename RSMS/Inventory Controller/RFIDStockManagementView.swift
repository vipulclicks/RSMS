//
//  RFIDStockManagementView.swift
//  RSMS
//
//  RFID inventory tracking, scans, discrepancies, and shrinkage analytics.
//

import SwiftUI

struct RFIDStockManagementView: View {
    private let stockItem = StockItem.preview
    private let scanRecord = RFIDScanRecord.preview
    private let discrepancy = StockDiscrepancy.preview
    private let shrinkage = ShrinkageAnalytics.preview
    private let products = Product.all

    private let kpiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                stockOverviewCards
                HStack(alignment: .top, spacing: 16) {
                    leftColumn
                    rightColumn
                }
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("RFID Stock Management")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            SectionHeader(title: "Inventory Overview", subtitle: "RFID-powered stock tracking & reconciliation")
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(RSMSTheme.success)
                    .frame(width: 8, height: 8)
                Text("RFID Active")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.success)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RSMSTheme.success.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Stock Overview

    private var stockOverviewCards: some View {
        LazyVGrid(columns: kpiColumns, spacing: 12) {
            KPICard(
                icon: "shippingbox.fill",
                value: "\(scanRecord.itemsScanned)",
                label: "Items Scanned",
                iconColor: RSMSTheme.gold
            )
            KPICard(
                icon: "checkmark.circle.fill",
                value: "\(scanRecord.itemsScanned - scanRecord.exceptionsFound)",
                label: "Verified OK",
                iconColor: RSMSTheme.success
            )
            KPICard(
                icon: "exclamationmark.triangle.fill",
                value: "\(scanRecord.exceptionsFound)",
                label: "Exceptions",
                iconColor: RSMSTheme.warning
            )
            KPICard(
                icon: "chart.line.downtrend.xyaxis",
                value: "€\(String(format: "%,.0f", shrinkage.totalLossValue))",
                label: "Shrinkage (90d)",
                iconColor: RSMSTheme.danger
            )
        }
    }

    // MARK: - Left Column

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recent RFID Scan
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Latest RFID Scan")

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Store-wide Scan")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("Performed by Emma Leroy")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        Spacer()
                        Text(timeAgo(scanRecord.scannedAt))
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    Divider().overlay(RSMSTheme.divider)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        scanMetric(label: "Items Scanned", value: "\(scanRecord.itemsScanned)", color: RSMSTheme.info)
                        scanMetric(label: "Exceptions", value: "\(scanRecord.exceptionsFound)", color: RSMSTheme.warning)
                    }

                    if let notes = scanRecord.notes {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "text.quote")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(RSMSTheme.surfaceSecondary))
                    }
                }
            }
            .rsmsCard()

            // Stock Item Detail
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Tracked Items")

                let product = products.first(where: { $0.id == stockItem.productId })

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.surfaceSecondary)
                            .frame(width: 56, height: 56)
                        Image(systemName: "watch.analog")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product?.name ?? "Product")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text(product?.sku ?? "")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    Spacer()

                    StatusBadge(text: stockItem.status.rawValue.replacingOccurrences(of: "_", with: " "),
                                color: stockStatusColor(stockItem.status))
                }

                Divider().overlay(RSMSTheme.divider)

                VStack(spacing: 8) {
                    detailRow(label: "RFID Tag", value: stockItem.rfidTag ?? "—")
                    detailRow(label: "Location", value: (stockItem.location ?? "Unknown").capitalized)
                    detailRow(label: "Quantity", value: "\(stockItem.quantity)")
                    detailRow(label: "Last Scanned", value: stockItem.lastScannedAt != nil ? "Just now" : "—")
                }
            }
            .rsmsCard()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Right Column

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Discrepancies
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    SectionHeader(title: "Stock Discrepancies")
                    Spacer()
                    StatusBadge(text: "Action Required", color: RSMSTheme.danger)
                }

                let product = products.first(where: { $0.id == discrepancy.productId })

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.danger)
                        Text(product?.name ?? "Product")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        StatusBadge(text: discrepancy.status.rawValue.replacingOccurrences(of: "_", with: " "),
                                    color: discrepancyStatusColor(discrepancy.status))
                    }

                    Divider().overlay(RSMSTheme.divider)

                    HStack(spacing: 20) {
                        varianceBlock(label: "Expected", value: "\(discrepancy.expectedQty)", color: RSMSTheme.textSecondary)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        varianceBlock(label: "Actual", value: "\(discrepancy.actualQty)", color: RSMSTheme.danger)
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(RSMSTheme.danger)
                        varianceBlock(label: "Variance", value: "\(discrepancy.actualQty - discrepancy.expectedQty)", color: RSMSTheme.danger)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .rsmsCard()

            // Shrinkage Analytics
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Shrinkage Analytics", subtitle: "90-day summary")

                VStack(spacing: 12) {
                    HStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("€\(String(format: "%,.0f", shrinkage.totalLossValue))")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSTheme.danger)
                            Text("Total Loss Value")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }

                        Divider().frame(height: 50).overlay(RSMSTheme.divider)

                        VStack(spacing: 6) {
                            Text("\(shrinkage.totalLossUnits)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSTheme.warning)
                            Text("Units Lost")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }

                    Divider().overlay(RSMSTheme.divider)

                    if let category = shrinkage.topCategory {
                        detailRow(label: "Top Category", value: category)
                    }
                    if let cause = shrinkage.primaryCause {
                        detailRow(label: "Primary Cause", value: cause)
                    }
                    detailRow(label: "Currency", value: shrinkage.currency)
                }
            }
            .rsmsCard()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sub-components

    private func scanMetric(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(RSMSTheme.surfaceSecondary))
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

    private func varianceBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
    }

    // MARK: - Helpers

    private func timeAgo(_ date: Date) -> String {
        let mins = Int(-date.timeIntervalSinceNow / 60)
        if mins < 60 { return "\(mins)m ago" }
        return "\(mins / 60)h ago"
    }

    private func stockStatusColor(_ status: StockStatus) -> Color {
        switch status {
        case .available: return RSMSTheme.success
        case .reserved:  return RSMSTheme.warning
        case .sold:      return RSMSTheme.textSecondary
        case .inTransit: return RSMSTheme.info
        case .damaged:   return RSMSTheme.danger
        case .onLoan:    return RSMSTheme.warning
        }
    }

    private func discrepancyStatusColor(_ status: DiscrepancyStatus) -> Color {
        switch status {
        case .open:          return RSMSTheme.danger
        case .investigating: return RSMSTheme.warning
        case .resolved:      return RSMSTheme.success
        case .writeOff:      return RSMSTheme.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        RFIDStockManagementView()
    }
}
