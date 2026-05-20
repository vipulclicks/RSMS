//
//  StaffShiftPlanningView.swift
//  RSMS
//
//  Staff scheduling, goals, commissions, and performance metrics.
//

import SwiftUI

struct StaffShiftPlanningView: View {
    private let shifts = StaffShift.all
    private let goal = SalesGoal.preview
    private let commission = Commission.preview
    private let metric = PerformanceMetric.preview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                shiftsSection
                goalsAndCommissionsRow
                performanceSection
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Staff & Shift Planning")
    }

    // MARK: - Shifts

    private var shiftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Today's Shifts", subtitle: "\(shifts.count) staff members on duty")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(shifts) { shift in
                    shiftCard(shift)
                }
            }
        }
    }

    private func shiftCard(_ shift: StaffShift) -> some View {
        let name = UserProfile.all.first(where: { $0.id == shift.staffId })?.fullName ?? "Staff"
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
                    StatusBadge(text: shift.role, color: roleBadgeColor(shift.role))
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

    // MARK: - Goals & Commissions

    private var goalsAndCommissionsRow: some View {
        HStack(alignment: .top, spacing: 16) {
            // Sales Goals
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Sales Goals")

                let staffName = UserProfile.all.first(where: { $0.id == goal.staffId })?.fullName ?? "Staff"

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(staffName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        StatusBadge(text: goal.period.rawValue, color: RSMSTheme.info)
                    }

                    // Progress bar
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(RSMSTheme.surfaceTertiary)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(RSMSTheme.primaryGradient)
                                    .frame(width: geo.size.width * (goal.achievedAmount / goal.targetAmount))
                            }
                        }
                        .frame(height: 12)

                        HStack {
                            Text("€\(String(format: "%,.0f", goal.achievedAmount))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RSMSTheme.primary)
                            Spacer()
                            Text("€\(String(format: "%,.0f", goal.targetAmount))")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }

                    Text("\(Int(goal.achievedAmount / goal.targetAmount * 100))% achieved")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .rsmsCard(padding: 16)
            }
            .frame(maxWidth: .infinity)

            // Commissions
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Recent Commissions")

                let staffName = UserProfile.all.first(where: { $0.id == commission.staffId })?.fullName ?? "Staff"

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(staffName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        StatusBadge(
                            text: commission.status.rawValue,
                            color: commissionColor(commission.status)
                        )
                    }

                    Divider().overlay(RSMSTheme.divider)

                    infoRow(label: "Amount", value: "€\(String(format: "%,.2f", commission.amount))")
                    infoRow(label: "Rate", value: "\(Int(commission.rate * 100))%")
                }
                .rsmsCard(padding: 16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Performance

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let staffName = UserProfile.all.first(where: { $0.id == metric.staffId })?.fullName ?? "Staff"
            SectionHeader(title: "Performance Overview", subtitle: staffName + " · \(metric.period.rawValue.capitalized)")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                KPICard(
                    icon: "banknote.fill",
                    value: "€\(String(format: "%,.0f", metric.totalSales))",
                    label: "Total Sales",
                    iconColor: RSMSTheme.primary
                )
                KPICard(
                    icon: "bag.fill",
                    value: "\(metric.unitsSold)",
                    label: "Units Sold",
                    iconColor: RSMSTheme.info
                )
                KPICard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "€\(String(format: "%,.0f", metric.avgTransactionValue))",
                    label: "Avg Transaction",
                    iconColor: RSMSTheme.success
                )
                KPICard(
                    icon: "percent",
                    value: "\(Int((metric.conversionRate ?? 0) * 100))%",
                    label: "Conversion Rate",
                    iconColor: RSMSTheme.warning
                )
            }
        }
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

    private func roleBadgeColor(_ role: String) -> Color {
        switch role {
        case "floor":       return RSMSTheme.success
        case "cashier":     return RSMSTheme.info
        case "back_office": return RSMSTheme.warning
        default:            return RSMSTheme.textSecondary
        }
    }

    private func commissionColor(_ status: CommissionStatus) -> Color {
        switch status {
        case .pending:  return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .paid:     return RSMSTheme.info
        }
    }
}

#Preview {
    NavigationStack {
        StaffShiftPlanningView()
    }
}
