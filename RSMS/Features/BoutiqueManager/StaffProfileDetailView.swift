import SwiftUI
import Charts

struct StaffProfileDetailView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel: StaffProfileViewModel
    @State private var showingCommissionSheet = false
    
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
            await viewModel.load(dataStore: appVM.dataStore)
        }
        .sheet(isPresented: $showingCommissionSheet) {
            // Re-fetch transactions for total sales
            let periodSales = appVM.dataStore.transactions
                .filter { $0.associateId == viewModel.staff.id }
                .reduce(0) { $0 + $1.totalAmount }
            
            CommissionAssignSheet(
                staffId: viewModel.staff.id,
                staffName: viewModel.staff.fullName,
                periodSales: periodSales,
                targetAmount: viewModel.currentMonthlyGoal?.targetAmount ?? 0.0,
                period: .monthly
            )
            .onDisappear {
                Task {
                    await viewModel.load(dataStore: appVM.dataStore)
                }
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
                    .font(.system(size: 32, weight: .bold))
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
                            Text("\(Int(viewModel.goalAchievementPercentage * 100))%")
                                .font(.title.weight(.bold))
                                .foregroundStyle(RSMSTheme.gold)
                            Text("Achieved")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }
                    
                    if let goal = viewModel.currentMonthlyGoal {
                        Text("\(goal.achievedAmount.formatted(.currency(code: "INR").precision(.fractionLength(0)))) / \(goal.targetAmount.formatted(.currency(code: "INR").precision(.fractionLength(0))))")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    } else {
                        Text("No active goal")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
                .frame(maxWidth: 200)
                .frame(maxWidth: .infinity) // Center in VStack
                .rsmsCard(padding: 24)
    }
    
    private var barChart: some View {
        VStack(alignment: .leading, spacing: 16) {
                    Text("Achievement History")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    if viewModel.chartGoalsData.isEmpty {
                        Text("No history available")
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Chart(viewModel.chartGoalsData) { goal in
                            BarMark(
                                x: .value("Date", goal.createdAt, unit: .day),
                                y: .value("Achieved", goal.achievedAmount)
                            )
                            .foregroundStyle(RSMSTheme.gold)
                            .cornerRadius(4)
                            
                            // Optional: overlay target as a rule mark or secondary bar
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                    }
                }
                .frame(height: 200)
                .rsmsCard(padding: 24)
    }
    
    // MARK: - Commission Section
    private var commissionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Commission", subtitle: "Payout History")
                Spacer()
                Button {
                    showingCommissionSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Assign")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.primaryDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.primaryDark.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            if viewModel.chartCommissionData.isEmpty {
                Text("No commission history found.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .rsmsCard(padding: 24)
            } else {
                VStack(spacing: 24) {
                    // Line Chart
                    Chart(viewModel.chartCommissionData) { comm in
                        LineMark(
                            x: .value("Date", comm.createdAt, unit: .day),
                            y: .value("Amount", comm.amount)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(RSMSTheme.primaryDark)
                        .symbol {
                            Circle().fill(RSMSTheme.primaryDark).frame(width: 8, height: 8)
                        }
                        
                        AreaMark(
                            x: .value("Date", comm.createdAt, unit: .day),
                            y: .value("Amount", comm.amount)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(LinearGradient(colors: [RSMSTheme.primaryDark.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                    }
                    .frame(height: 200)
                    
                    Divider().overlay(RSMSTheme.divider)
                    
                    // List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Payouts")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .tracking(1)
                        
                        ForEach(viewModel.chartCommissionData.reversed().prefix(5)) { comm in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(comm.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text(comm.status.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(comm.status == .paid ? RSMSTheme.success : RSMSTheme.info)
                                }
                                Spacer()
                                Text(comm.amount.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .rsmsCard(padding: 24)
            }
        }
    }
}
