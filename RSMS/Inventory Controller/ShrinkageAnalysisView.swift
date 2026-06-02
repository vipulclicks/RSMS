//
//  ShrinkageAnalysisView.swift
//  RSMS
//
//  Displays shrinkage metrics and highest risk items for the Inventory Controller.
//  All data sourced live from Supabase:
//   - Hero KPIs derived from live inventory_variances + stock_items
//   - Period summary card from shrinkage_analytics table
//   - Category breakdown derived from variance data
//   - High-risk items ranked by missing value
//

import SwiftUI

struct ShrinkageAnalysisView: View {
    @Environment(\.dismiss) var dismiss

    // Live-computed values from StockReconciliationViewModel
    let shrinkagePercentage: Double
    let shrinkageValue: Double
    let totalInventoryValue: Double
    let highRiskItems: [DiscrepancyItem]

    // Most recent record from shrinkage_analytics table (nil if not yet fetched)
    let shrinkageRecord: ShrinkageAnalytics?

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        heroKPISection

                        // Period summary from Supabase shrinkage_analytics — only shown when data exists
                        if let record = shrinkageRecord {
                            periodSummarySection(record: record)
                        }

                        categoryBreakdownSection
                        highRiskItemsSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Shrinkage Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
    }

    // MARK: - Hero KPI Section

    private var heroKPISection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                kpiCard(
                    title: "SHRINKAGE RATE",
                    value: String(format: "%.2f%%", shrinkagePercentage),
                    icon: "chart.line.downtrend.xyaxis",
                    accentColor: shrinkagePercentage > 2.0 ? RSMSTheme.danger : RSMSTheme.warning
                )

                kpiCard(
                    title: "LOSS VALUE",
                    value: "\(shrinkageRecord?.currency ?? "EUR") \(Int(shrinkageValue).formatted())",
                    icon: "dollarsign.arrow.circlepath",
                    accentColor: RSMSTheme.danger
                )
            }

            HStack {
                Text("TOTAL INVENTORY VALUE")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(RSMSTheme.textTertiary)
                Spacer()
                Text("\(shrinkageRecord?.currency ?? "EUR") \(Int(totalInventoryValue).formatted())")
                    .font(.subheadline.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding()
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
    }

    private func kpiCard(title: String, value: String, icon: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                Spacer()
            }
            Text(title)
                .font(.caption2.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Period Summary (from shrinkage_analytics Supabase table)

    private func periodSummarySection(record: ShrinkageAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PERIOD SUMMARY")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("FROM SUPABASE")
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(RSMSTheme.textTertiary.opacity(0.6))
            }

            VStack(spacing: 0) {
                periodRow(
                    label: "PERIOD",
                    value: "\(record.periodStart.formatted(date: .abbreviated, time: .omitted)) – \(record.periodEnd.formatted(date: .abbreviated, time: .omitted))"
                )
                Divider().background(RSMSTheme.divider).padding(.horizontal, 16)

                periodRow(
                    label: "UNITS LOST",
                    value: "\(record.totalLossUnits) units"
                )
                Divider().background(RSMSTheme.divider).padding(.horizontal, 16)

                periodRow(
                    label: "TOTAL LOSS",
                    value: "\(record.currency) \(Int(record.totalLossValue).formatted())"
                )

                if let topCategory = record.topCategory {
                    Divider().background(RSMSTheme.divider).padding(.horizontal, 16)
                    periodRow(label: "TOP CATEGORY", value: topCategory)
                }

                if let primaryCause = record.primaryCause {
                    Divider().background(RSMSTheme.divider).padding(.horizontal, 16)
                    periodRow(label: "PRIMARY CAUSE", value: primaryCause)
                }
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.gold.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func periodRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.weight(.semibold))
                .tracking(1)
                .foregroundStyle(RSMSTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LOSS BY CATEGORY")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.gold)

            let categoryGroups = Dictionary(grouping: highRiskItems, by: { $0.product.category })
            let categories = categoryGroups.map { (key, items) in
                let value = items.reduce(0.0) { sum, item in
                    let missing = max(0, item.expectedQty - item.actualQty)
                    return sum + (Double(missing) * item.product.price)
                }
                return (category: key, value: value)
            }.filter { $0.value > 0 }.sorted { $0.value > $1.value }

            if categories.isEmpty {
                Text("No shrinkage data available.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(.vertical)
            } else {
                VStack(spacing: 16) {
                    ForEach(categories, id: \.category) { item in
                        categoryRow(name: item.category, value: item.value, totalValue: shrinkageValue)
                    }
                }
                .padding()
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private func categoryRow(name: String, value: Double, totalValue: Double) -> some View {
        let percent = totalValue > 0 ? (value / totalValue) : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text("\(shrinkageRecord?.currency ?? "EUR") \(Int(value).formatted())")
                    .font(.subheadline.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(RSMSTheme.surfaceSecondary)
                    Capsule()
                        .fill(RSMSTheme.gold)
                        .frame(width: max(0, geo.size.width * CGFloat(percent)))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - High Risk Items

    private var highRiskItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HIGHEST RISK ITEMS")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.gold)

            if highRiskItems.isEmpty {
                Text("No items at risk.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(highRiskItems.prefix(5).enumerated()), id: \.element.id) { index, item in
                        let missing = max(0, item.expectedQty - item.actualQty)
                        let lossValue = Double(missing) * item.product.price

                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(RSMSTheme.surfaceSecondary)
                                    .frame(width: 48, height: 48)
                                Image(systemName: item.icon)
                                    .foregroundStyle(RSMSTheme.gold)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.product.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .lineLimit(1)
                                Text("\(missing) units missing")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.danger)
                            }

                            Spacer()

                            Text("-\(shrinkageRecord?.currency ?? "EUR") \(Int(lossValue).formatted())")
                                .font(.subheadline.bold())
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        .padding(.vertical, 12)

                        if index < min(highRiskItems.count, 5) - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
            }
        }
    }
}
