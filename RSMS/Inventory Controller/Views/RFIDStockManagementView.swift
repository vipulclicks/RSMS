//
//  RFIDStockManagementView.swift
//  RSMS
//
//  RFID inventory tracking, scans, discrepancies, and shrinkage analytics.
//

import SwiftUI

struct RFIDStockManagementView: View {
    private let stockItem = StockItem(id: UUID(), productId: UUID(), storeId: UUID(), quantity: 1, rfidTag: nil, location: nil, status: .available, lastScannedAt: nil, updatedAt: Date())
    private let scanRecord = RFIDScanRecord(id: UUID(), storeId: UUID(), scannedBy: UUID(), scannedAt: Date(), itemsScanned: 0, exceptionsFound: 0, notes: nil)
    private let variance = InventoryVariance(id: UUID(), storeId: UUID(), productId: UUID(), expectedQty: 0, actualQty: 0, variance: 0, reportedBy: UUID(), status: .open, cycleCountId: nil, resolution: nil, reportedAt: Date(), resolvedAt: nil)
    private let shrinkage = ShrinkageAnalytics(id: UUID(), storeId: UUID(), periodStart: Date(), periodEnd: Date(), totalLossUnits: 0, totalLossValue: 0.0, currency: "INR", topCategory: nil, primaryCause: nil)
    private let products: [Product] = []

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width
            let padding: CGFloat = viewWidth > 550 ? 24 : 20
            let availableWidth = viewWidth - (padding * 2)
            let spacing: CGFloat = viewWidth > 550 ? 16 : 12

            let columns: [GridItem] = {
                let columnsCount: Int
                if availableWidth >= 700 {
                    columnsCount = 4
                } else if availableWidth >= 480 {
                    columnsCount = 3
                } else {
                    columnsCount = 2
                }
                return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount)
            }()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    
                    LazyVGrid(columns: columns, spacing: 12) {
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
                            value: "₹\(String(format: "%,.0f", shrinkage.totalLossValue))",
                            label: "Shrinkage (90d)",
                            iconColor: RSMSTheme.danger
                        )
                    }

                    if viewWidth > 700 {
                        HStack(alignment: .top, spacing: 16) {
                            leftColumn
                            rightColumn
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            leftColumn
                            rightColumn
                        }
                    }
                }
                .padding(padding)
            }
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

                let product = products.first(where: { $0.id == variance.productId })

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.danger)
                        Text(product?.name ?? "Product")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        StatusBadge(text: variance.status.rawValue.replacingOccurrences(of: "_", with: " "),
                                    color: varianceStatusColor(variance.status))
                    }

                    Divider().overlay(RSMSTheme.divider)

                    HStack(spacing: 20) {
                        varianceBlock(label: "Expected", value: "\(variance.expectedQty)", color: RSMSTheme.textSecondary)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        varianceBlock(label: "Actual", value: "\(variance.actualQty)", color: RSMSTheme.danger)
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(RSMSTheme.danger)
                        varianceBlock(label: "Variance", value: "\(variance.variance)", color: RSMSTheme.danger)
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
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.right.circle.fill").foregroundColor(RSMSTheme.danger)
                                Text("₹\(String(format: "%,.0f", shrinkage.totalLossValue))")
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(RSMSTheme.danger)
                            }
                            Text("Total Loss Value")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }

                        Divider().frame(height: 50).overlay(RSMSTheme.divider)

                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(RSMSTheme.warning)
                                Text("\(shrinkage.totalLossUnits)")
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(RSMSTheme.warning)
                            }
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

    private func varianceStatusColor(_ status: VarianceStatus) -> Color {
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
