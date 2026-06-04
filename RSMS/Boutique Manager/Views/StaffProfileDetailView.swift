import SwiftUI
import Charts

fileprivate func formatCompactINR(_ amount: Double) -> String {
    if amount >= 1_00_00_000 {
        return String(format: "₹%.1fCr", amount / 1_00_00_000).replacingOccurrences(of: ".0", with: "")
    } else if amount >= 1_00_000 {
        return String(format: "₹%.1fL", amount / 1_00_000).replacingOccurrences(of: ".0", with: "")
    } else if amount >= 1_000 {
        return String(format: "₹%.1fK", amount / 1_000).replacingOccurrences(of: ".0", with: "")
    } else {
        return "₹\(Int(amount))"
    }
}

struct StaffProfileDetailView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel: StaffProfileViewModel
    @State private var selectedSalesDate: Date?
    @State private var selectedCommissionDate: Date?

    
    init(staff: UserProfile) {
        _viewModel = State(initialValue: StaffProfileViewModel(staff: staff))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Profile...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Error Loading Data",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        shiftSection
                        performanceSection
                        commissionSection
                    }
                    .padding(32)
                }
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle(viewModel.staff.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let storeId = appVM.currentStoreId {
                await viewModel.load(dataStore: appVM.dataStore, storeId: storeId)
            }
        }
    }
    
    private var headerSection: some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .center, spacing: 16) {
                    headerContent
                }
                .frame(maxWidth: .infinity)
                .rsmsCard(padding: 24)
            } else {
                HStack(spacing: 24) {
                    headerContent
                    Spacer()
                }
                .rsmsCard(padding: 24)
            }
        }
    }
    
    @ViewBuilder
    private var headerContent: some View {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Text(String(viewModel.staff.fullName.prefix(1)))
                    .font(.title.weight(.bold))
                    .foregroundStyle(RSMSTheme.gold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.staff.fullName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text("Designation - \(viewModel.staff.role.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                if let email = viewModel.staff.email as String? {
                    Text("Email - \(email)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            .multilineTextAlignment(horizontalSizeClass == .compact ? .center : .leading)
    }
    
    // MARK: - Shift Section
    private var shiftSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Shift", subtitle: "Current Assigned Shift")
            
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundStyle(RSMSTheme.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Shift")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    Text(viewModel.shiftTiming)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(RSMSTheme.surfacePrimary)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
            )
        }
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Performance", subtitle: "Sales Goals vs Achievement")
            
            if horizontalSizeClass == .compact {
                VStack(spacing: 24) {
                    circularChart
                    barChart
                }
            } else {
                HStack(spacing: 24) {
                    circularChart
                    barChart
                }
            }
        }
    }
    
    private var circularChart: some View {
        VStack(spacing: 16) {
                    Text("Current Goal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    ZStack {
                        Circle()
                            .stroke(RSMSTheme.surfaceTertiary, lineWidth: 12)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.goalAchievementPercentage)
                            .stroke(RSMSTheme.gold, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.0), value: viewModel.goalAchievementPercentage)
                        
                        VStack {
                            Text("\(Int(viewModel.rawGoalAchievementPercentage * 100))%")
                                .font(.title.weight(.bold))
                                .foregroundStyle(RSMSTheme.gold)
                            Text("Achieved")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }
                    
                    if let goal = viewModel.currentMonthlyGoal {
                        Text("\(viewModel.computedAchievedAmount.formatted(.currency(code: "INR").precision(.fractionLength(0)))) / \(goal.targetAmount.formatted(.currency(code: "INR").precision(.fractionLength(0))))")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    } else {
                        Text("No active goal")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 250)
                .rsmsCard(padding: 24)
    }
    
    private var barChart: some View {
        VStack(alignment: .leading, spacing: 16) {
                    Text("Achievement History (Last 7 Days)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    if viewModel.dailySalesData.isEmpty || viewModel.dailySalesData.allSatisfy({ $0.amount == 0 }) {
                        Text("No sales history available")
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Chart(viewModel.dailySalesData) { dayData in
                            let isSelected = selectedSalesDate == nil || Calendar.current.isDate(dayData.date, inSameDayAs: selectedSalesDate!)
                            BarMark(
                                x: .value("Date", dayData.date, unit: .day),
                                y: .value("Sales", dayData.amount)
                            )
                            .foregroundStyle(isSelected ? RSMSTheme.gold.gradient : RSMSTheme.surfaceTertiary.gradient)
                            .cornerRadius(4)
                            .annotation(position: .top) {
                                if dayData.amount > 0 && isSelected {
                                    Text(formatCompactINR(dayData.amount))
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                            }
                        }
                        .chartXSelection(value: $selectedSalesDate)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                if let amount = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text(formatCompactINR(amount))
                                    }
                                    AxisGridLine()
                                }
                            }
                        }
                    }
                }
                .frame(height: 250)
                .rsmsCard(padding: 24)
    }
    
    // MARK: - Commission Section
    private var commissionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Commission", subtitle: "Transaction History")
            }
            
            if viewModel.commissionList.isEmpty {
                Text("No commission history found.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .rsmsCard(padding: 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.commissionList) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.transactionDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text("Transaction: \(item.transactionAmount.formatted(.currency(code: "INR").precision(.fractionLength(0))))")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(item.commissionEarned.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.gold)
                                Text(item.status.rawValue.capitalized)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(item.status == .paid ? RSMSTheme.success.opacity(0.2) : RSMSTheme.warning.opacity(0.2))
                                    .foregroundStyle(item.status == .paid ? RSMSTheme.success : RSMSTheme.warning)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 12)
                        
                        if item.id != viewModel.commissionList.last?.id {
                            Divider().overlay(RSMSTheme.divider)
                        }
                    }
                    
                    if !viewModel.commissionList.isEmpty {
                        Divider().overlay(RSMSTheme.divider)
                            .padding(.top, 4)
                        
                        let totalCommission = viewModel.commissionList.reduce(0) { $0 + $1.commissionEarned }
                        HStack {
                            Text("Total Commission")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            
                            Spacer()
                            
                            Text(totalCommission.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(RSMSTheme.gold)
                        }
                        .padding(.vertical, 16)
                    }
                }
                .rsmsCard(padding: 24)
            }
        }
    }
    

}
