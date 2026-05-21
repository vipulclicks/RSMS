//
//  StoreDashboardView.swift
//  RSMS
//
//  Boutique Manager store dashboard with KPIs, staff, and alerts.
//

import SwiftUI

struct StoreDashboardView: View {
    @State private var viewModel = StoreDashboardViewModel()

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
                    
                    LazyVGrid(columns: columns, spacing: spacing) {
                        KPICard(
                            icon: "eurosign.circle.fill",
                            value: viewModel.formatCurrency(viewModel.summary.salesActual),
                            label: "Today's Sales",
                            trend: "\(Int(viewModel.summary.salesActual / viewModel.summary.salesTarget * 100))% of target",
                            trendColor: viewModel.summary.salesActual >= viewModel.summary.salesTarget ? RSMSTheme.success : RSMSTheme.warning
                        )
                        KPICard(
                            icon: "calendar.badge.clock",
                            value: "\(viewModel.summary.appointmentCount)",
                            label: "Appointments",
                            iconColor: RSMSTheme.info
                        )
                        KPICard(
                            icon: "exclamationmark.triangle.fill",
                            value: "\(viewModel.summary.lowStockAlertCount)",
                            label: "Low Stock Alerts",
                            iconColor: RSMSTheme.warning
                        )
                        KPICard(
                            icon: "figure.walk.arrival",
                            value: "\(viewModel.summary.footfallCount ?? 0)",
                            label: "Footfall Today",
                            iconColor: RSMSTheme.success
                        )
                    }

                    if viewWidth > 650 {
                        HStack(alignment: .top, spacing: 16) {
                            salesProgressCard
                            highlightsCard
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            salesProgressCard
                            highlightsCard
                        }
                    }

                    staffSection
                }
                .padding(padding)
            }
        }
        .background(RSMSTheme.background)
        .navigationTitle("Store Dashboard")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back, Sophie")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(viewModel.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(RSMSTheme.primary)
                Text(viewModel.store.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
    }

    // MARK: - Main Content Subviews

    private var salesProgressCard: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Sales Progress")
            HStack(spacing: 32) {
                CircularProgressView(
                    progress: viewModel.summary.salesActual / viewModel.summary.salesTarget,
                    label: "of target",
                    value: "\(Int(viewModel.summary.salesActual / viewModel.summary.salesTarget * 100))%"
                )
                VStack(alignment: .leading, spacing: 16) {
                    metricRow(label: "Target", value: viewModel.formatCurrency(viewModel.summary.salesTarget), color: RSMSTheme.textSecondary)
                    metricRow(label: "Actual", value: viewModel.formatCurrency(viewModel.summary.salesActual), color: RSMSTheme.primary)
                    metricRow(label: "Remaining", value: viewModel.formatCurrency(viewModel.summary.salesTarget - viewModel.summary.salesActual), color: RSMSTheme.warning)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rsmsCard()
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Highlights")

            if let topCategory = viewModel.summary.topSellingCategory {
                highlightRow(icon: "crown.fill", title: "Top Selling", value: topCategory, color: RSMSTheme.primary)
            }
            highlightRow(icon: "calendar", title: "Appointments", value: "\(viewModel.summary.appointmentCount) scheduled today", color: RSMSTheme.info)
            highlightRow(icon: "exclamationmark.shield.fill", title: "Stock Alerts", value: "\(viewModel.summary.lowStockAlertCount) items low", color: RSMSTheme.warning)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rsmsCard()
    }


    // MARK: - Staff Section

    private var staffSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Staff on Shift Today", subtitle: "\(viewModel.shifts.count) team members")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.shifts) { shift in
                    staffShiftCard(shift)
                }
            }
        }
    }

    private func staffShiftCard(_ shift: StaffShift) -> some View {
        let name = viewModel.staffName(for: shift.staffId)
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.primary.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(String(name.prefix(1)))
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(shift.role.capitalized)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(shift.startTime) – \(shift.endTime)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.primary)
                if let notes = shift.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
        }
        .rsmsCard(padding: 16)
    }

    // MARK: - Helpers

    private func metricRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
    }

    private func highlightRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        StoreDashboardView()
    }
}
