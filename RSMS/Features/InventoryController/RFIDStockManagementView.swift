//
//  RFIDStockManagementView.swift
//  RSMS
//
//  RFID inventory tracking, scans, discrepancies, and shrinkage analytics.
//

import SwiftUI

struct RFIDStockManagementView: View {
    @State private var viewModel = RFIDStockManagementViewModel()

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
                value: "\(viewModel.scanRecord.itemsScanned)",
                label: "Items Scanned",
                iconColor: RSMSTheme.primary
            )
            KPICard(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.scanRecord.itemsScanned - viewModel.scanRecord.exceptionsFound)",
                label: "Verified OK",
                iconColor: RSMSTheme.success
            )
            KPICard(
                icon: "exclamationmark.triangle.fill",
                value: "\(viewModel.scanRecord.exceptionsFound)",
                label: "Exceptions",
                iconColor: RSMSTheme.warning
            )
            KPICard(
                icon: "chart.line.downtrend.xyaxis",
                value: "€\(String(format: "%,.0f", viewModel.shrinkage.totalLossValue))",
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
                            .foregroundStyle(RSMSTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Store-wide Scan")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("Performed by Emma Leroy")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        Spacer()
                        Text(viewModel.timeAgo(from: viewModel.scanRecord.scannedAt))
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    Divider().overlay(RSMSTheme.divider)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        scanMetric(label: "Items Scanned", value: "\(viewModel.scanRecord.itemsScanned)", color: RSMSTheme.info)
                        scanMetric(label: "Exceptions", value: "\(viewModel.scanRecord.exceptionsFound)", color: RSMSTheme.warning)
                    }

                    if let notes = viewModel.scanRecord.notes {
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

                let product = viewModel.trackedProduct

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.surfaceSecondary)
                            .frame(width: 56, height: 56)
                        Image(systemName: "watch.analog")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.primary)
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

                    StatusBadge(text: viewModel.stockItem.status.rawValue.replacingOccurrences(of: "_", with: " "),
                                color: viewModel.stockStatusColor(viewModel.stockItem.status))
                }

                Divider().overlay(RSMSTheme.divider)

                VStack(spacing: 8) {
                    detailRow(label: "RFID Tag", value: viewModel.stockItem.rfidTag ?? "—")
                    detailRow(label: "Location", value: (viewModel.stockItem.location ?? "Unknown").capitalized)
                    detailRow(label: "Quantity", value: "\(viewModel.stockItem.quantity)")
                    detailRow(label: "Last Scanned", value: viewModel.stockItem.lastScannedAt != nil ? "Just now" : "—")
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

                let product = viewModel.discrepancyProduct

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.danger)
                        Text(product?.name ?? "Product")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        StatusBadge(text: viewModel.discrepancy.status.rawValue.replacingOccurrences(of: "_", with: " "),
                                    color: viewModel.discrepancyStatusColor(viewModel.discrepancy.status))
                    }

                    Divider().overlay(RSMSTheme.divider)

                    HStack(spacing: 20) {
                        varianceBlock(label: "Expected", value: "\(viewModel.discrepancy.expectedQty)", color: RSMSTheme.textSecondary)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        varianceBlock(label: "Actual", value: "\(viewModel.discrepancy.actualQty)", color: RSMSTheme.danger)
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(RSMSTheme.danger)
                        varianceBlock(label: "Variance", value: "\(viewModel.stockVariance)", color: RSMSTheme.danger)
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
                            Text("€\(String(format: "%,.0f", viewModel.shrinkage.totalLossValue))")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSTheme.danger)
                            Text("Total Loss Value")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }

                        Divider().frame(height: 50).overlay(RSMSTheme.divider)

                        VStack(spacing: 6) {
                            Text("\(viewModel.shrinkage.totalLossUnits)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSTheme.warning)
                            Text("Units Lost")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }

                    Divider().overlay(RSMSTheme.divider)

                    if let category = viewModel.shrinkage.topCategory {
                        detailRow(label: "Top Category", value: category)
                    }
                    if let cause = viewModel.shrinkage.primaryCause {
                        detailRow(label: "Primary Cause", value: cause)
                    }
                    detailRow(label: "Currency", value: viewModel.shrinkage.currency)
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
}

#Preview {
    NavigationStack {
        RFIDStockManagementView()
    }
}
