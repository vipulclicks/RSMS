import SwiftUI

struct StaffShiftPlanningView: View {
    @State private var navPath = [SalesGoalRoute]()
    @State private var salesGoalVM = SalesGoalViewModel()
    
    private let shifts = StaffShift.all
    private let commission = Commission.preview
    private let metric = PerformanceMetric.preview

    var body: some View {
        NavigationStack(path: $navPath) {
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
            .navigationDestination(for: SalesGoalRoute.self) { route in
                switch route {
                case .assignGoalForm:
                    AssignGoalFormView(viewModel: salesGoalVM, navPath: $navPath)
                case .staffPicker:
                    StaffPickerView(viewModel: salesGoalVM, navPath: $navPath)
                }
            }
        }
    }

    // MARK: - Shifts Section
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
                    Circle().fill(RSMSTheme.gold.opacity(0.1)).frame(width: 40, height: 40)
                    Text(String(name.prefix(1))).font(.headline).foregroundStyle(RSMSTheme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(RSMSTheme.textPrimary)
                    StatusBadge(text: shift.role, color: roleBadgeColor(shift.role))
                }
            }
            Divider().overlay(RSMSTheme.divider)
            HStack {
                Image(systemName: "clock.fill").font(.caption).foregroundStyle(RSMSTheme.gold)
                Text("\(shift.startTime) – \(shift.endTime)").font(.subheadline.weight(.medium)).foregroundStyle(RSMSTheme.textPrimary)
            }
        }
        .rsmsCard(padding: 16)
    }

    // MARK: - Goals & Commissions Row
    private var goalsAndCommissionsRow: some View {
        HStack(alignment: .top, spacing: 16) {
            
            // MARK: Sales Goals Column
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    SectionHeader(title: "Sales Goals")
                    Spacer()
                    Button {
                        navPath.append(.assignGoalForm)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("New Goal")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RSMSTheme.gold.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                ForEach(salesGoalVM.availableStaff) { staff in
                    StaffGoalCard(staff: staff, viewModel: salesGoalVM)
                }
            }
            .frame(maxWidth: .infinity)

            // MARK: Commissions Column
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Recent Commissions")
                let staffName = UserProfile.all.first(where: { $0.id == commission.staffId })?.fullName ?? "Staff"
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(staffName).font(.subheadline.weight(.semibold)).foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        StatusBadge(text: commission.status.rawValue, color: commissionColor(commission.status))
                    }
                    Divider().overlay(RSMSTheme.divider)
                    
                    infoRow(label: "Amount", value: commission.amount.formatted(.currency(code: "INR").precision(.fractionLength(2))))
                    infoRow(label: "Rate", value: "\(Int(commission.rate * 100))%")
                }
                .rsmsCard(padding: 16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let staffName = UserProfile.all.first(where: { $0.id == metric.staffId })?.fullName ?? "Staff"
            SectionHeader(title: "Performance Overview", subtitle: staffName + " · \(metric.period.rawValue.capitalized)")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                KPICard(icon: "indianrupeesign.square.fill", value: metric.totalSales.formatted(.currency(code: "INR").precision(.fractionLength(0))), label: "Total Sales", iconColor: RSMSTheme.gold)
                KPICard(icon: "bag.fill", value: "\(metric.unitsSold)", label: "Units Sold", iconColor: RSMSTheme.info)
                KPICard(icon: "chart.line.uptrend.xyaxis", value: metric.avgTransactionValue.formatted(.currency(code: "INR").precision(.fractionLength(0))), label: "Avg Transaction", iconColor: RSMSTheme.success)
                KPICard(icon: "percent", value: "\(Int((metric.conversionRate ?? 0) * 100))%", label: "Conversion Rate", iconColor: RSMSTheme.warning)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(RSMSTheme.textPrimary)
        }
    }

    private func roleBadgeColor(_ role: String) -> Color {
        switch role {
        case "floor": return RSMSTheme.success
        case "cashier": return RSMSTheme.info
        case "back_office": return RSMSTheme.warning
        default: return RSMSTheme.textSecondary
        }
    }

    private func commissionColor(_ status: CommissionStatus) -> Color {
        switch status {
        case .pending: return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .paid: return RSMSTheme.info
        }
    }
}

// MARK: - Dynamic Goal Card
struct StaffGoalCard: View {
    let staff: UserProfile
    var viewModel: SalesGoalViewModel
    
    @State private var selectedPeriod: GoalPeriod = .monthly
    
    var body: some View {
        let currentGoal = viewModel.activeGoals.first { $0.staffId == staff.id && $0.period == selectedPeriod }
        
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(staff.fullName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Spacer()
                
                // MARK: The 4 Filter Buttons (Added Quarterly)
                HStack(spacing: 4) {
                    ForEach([GoalPeriod.daily, .weekly, .monthly, .quarterly], id: \.self) { period in
                        Button {
                            withAnimation(.snappy) { selectedPeriod = period }
                        } label: {
                            Text(period.rawValue.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6) // Slightly tighter padding to fit all 4
                                .padding(.vertical, 4)
                                .background(selectedPeriod == period ? RSMSTheme.gold : RSMSTheme.surfaceTertiary)
                                .foregroundStyle(selectedPeriod == period ? RSMSTheme.background : RSMSTheme.textSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // MARK: Progress Bar & Data
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6).fill(RSMSTheme.surfaceTertiary)
                        
                        if let goal = currentGoal, goal.targetAmount > 0 {
                            RoundedRectangle(cornerRadius: 6).fill(RSMSTheme.goldGradient)
                                .frame(width: geo.size.width * min((goal.achievedAmount / goal.targetAmount), 1.0))
                        }
                    }
                }
                .frame(height: 12)
                
                HStack {
                    if let goal = currentGoal {
                        Text(goal.achievedAmount.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.gold)
                        Spacer()
                        Text(goal.targetAmount.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    } else {
                        Text("₹0")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Spacer()
                        Text("No Target Set")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
            
            if let goal = currentGoal, goal.targetAmount > 0 {
                Text("\(Int((goal.achievedAmount / goal.targetAmount) * 100))% achieved")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                Text("0% achieved")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
        .rsmsCard(padding: 16)
    }
}

#Preview("Staff & Shift Planning") {
    StaffShiftPlanningView()
        .environment(AppViewModel())
}
