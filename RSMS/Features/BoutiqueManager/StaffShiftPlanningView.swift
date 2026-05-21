//
//  StaffShiftPlanningView.swift
//  RSMS
//
//  Staff scheduling, goals, commissions, and performance metrics.
//

import SwiftUI

struct StaffShiftPlanningView: View {
    @State private var viewModel = StaffShiftPlanningViewModel()

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width
            let padding: CGFloat = viewWidth > 550 ? 24 : 20
            let availableWidth = viewWidth - (padding * 2)

            // Dynamic columns for shifts (max 3)
            let shiftColumns: [GridItem] = {
                let count: Int
                if availableWidth >= 700 {
                    count = 3
                } else if availableWidth >= 480 {
                    count = 2
                } else {
                    count = 1
                }
                return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
            }()

            // Dynamic columns for performance KPIs (max 4)
            let perfColumns: [GridItem] = {
                let count: Int
                if availableWidth >= 700 {
                    count = 4
                } else if availableWidth >= 480 {
                    count = 3
                } else {
                    count = 2
                }
                return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
            }()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Shifts section with dynamic columns
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Today's Shifts", subtitle: "\(viewModel.shifts.count) staff members on duty")

                        LazyVGrid(columns: shiftColumns, spacing: 12) {
                            ForEach(viewModel.shifts) { shift in
                                shiftCard(shift)
                            }
                        }
                    }

                    // Goals & commissions dynamic layout
                    if viewWidth > 650 {
                        HStack(alignment: .top, spacing: 16) {
                            salesGoalsCard
                            commissionsCard
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            salesGoalsCard
                            commissionsCard
                        }
                    }

                    // Performance section with dynamic columns
                    VStack(alignment: .leading, spacing: 16) {
                        let staffName = viewModel.staffName(for: viewModel.metric.staffId)
                        SectionHeader(title: "Performance Overview", subtitle: staffName + " · \(viewModel.metric.period.rawValue.capitalized)")

                        LazyVGrid(columns: perfColumns, spacing: 12) {
                            KPICard(
                                icon: "banknote.fill",
                                value: "€\(String(format: "%,.0f", viewModel.metric.totalSales))",
                                label: "Total Sales",
                                iconColor: RSMSTheme.primary
                            )
                            KPICard(
                                icon: "bag.fill",
                                value: "\(viewModel.metric.unitsSold)",
                                label: "Units Sold",
                                iconColor: RSMSTheme.info
                            )
                            KPICard(
                                icon: "chart.line.uptrend.xyaxis",
                                value: "€\(String(format: "%,.0f", viewModel.metric.avgTransactionValue))",
                                label: "Avg Transaction",
                                iconColor: RSMSTheme.success
                            )
                            KPICard(
                                icon: "percent",
                                value: "\(Int((viewModel.metric.conversionRate ?? 0) * 100))%",
                                label: "Conversion Rate",
                                iconColor: RSMSTheme.warning
                            )
                        }
                    }
                }
                .padding(padding)
            }
        }
        .background(RSMSTheme.background)
        .navigationTitle("Staff & Shift Planning")
    }

    // MARK: - Subviews for Goals & Commissions

    private var salesGoalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Sales Goals")

            let staffName = viewModel.staffName(for: viewModel.goal.staffId)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(staffName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    StatusBadge(text: viewModel.goal.period.rawValue, color: RSMSTheme.info)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(RSMSTheme.surfaceTertiary)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(RSMSTheme.primaryGradient)
                                .frame(width: geo.size.width * viewModel.goalProgressRatio)
                        }
                    }
                    .frame(height: 12)

                    HStack {
                        Text("€\(String(format: "%,.0f", viewModel.goal.achievedAmount))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.primary)
                        Spacer()
                        Text("€\(String(format: "%,.0f", viewModel.goal.targetAmount))")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }

                Text("\(viewModel.goalAchievedPercent)% achieved")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            .rsmsCard(padding: 16)
        }
        .frame(maxWidth: .infinity)
    }

    private var commissionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Commissions")

            let staffName = viewModel.staffName(for: viewModel.commission.staffId)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(staffName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    StatusBadge(
                        text: viewModel.commission.status.rawValue,
                        color: viewModel.commissionColor(viewModel.commission.status)
                    )
                }

                Divider().overlay(RSMSTheme.divider)

                infoRow(label: "Amount", value: "€\(String(format: "%,.2f", viewModel.commission.amount))")
                infoRow(label: "Rate", value: "\(Int(viewModel.commission.rate * 100))%")
            }
            .rsmsCard(padding: 16)
        }
        .frame(maxWidth: .infinity)
    }

    private func shiftCard(_ shift: StaffShift) -> some View {
        let name = viewModel.staffName(for: shift.staffId)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Text(String(name.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    StatusBadge(text: shift.role, color: viewModel.roleBadgeColor(shift.role))
                }
            }

            Divider().overlay(RSMSTheme.divider)

            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.primary)
                Text("\(shift.startTime) – \(shift.endTime)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }

            if let notes = shift.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
        .rsmsCard(padding: 16)
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        StaffShiftPlanningView()
    }
}
