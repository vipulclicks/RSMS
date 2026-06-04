import SwiftUI

struct StaffShiftPlanningView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var navPath = [StaffRoute]()
    @State private var salesGoalVM = SalesGoalViewModel()
    @State private var shiftPlanningVM = StaffManagementViewModel()
    @State private var showingNewAssociateSheet = false

    var body: some View {
        Group {
            if shiftPlanningVM.isLoading || salesGoalVM.isLoading {
                ProgressView("Loading Planning Data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = shiftPlanningVM.errorMessage ?? salesGoalVM.errorMessage {
                ContentUnavailableView(
                    "Error Loading Data",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                NavigationStack(path: $navPath) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            goalsAndCommissionsRow
                            allStaffSection
                        }
                        .padding(24)
                    }
                    .background(RSMSTheme.background.ignoresSafeArea())
                    .navigationTitle("Staff & Shift Planning")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                showingNewAssociateSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("New Associate")
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                    .navigationDestination(for: StaffRoute.self) { route in
                        switch route {
                        case .assignGoalForm:
                            AssignGoalFormView(viewModel: salesGoalVM, navPath: $navPath)
                        case .staffPicker:
                            StaffPickerView(viewModel: salesGoalVM, navPath: $navPath)
                        case .allStaff:
                            EmptyView()
                        case .staffProfile(let staff):
                            StaffProfileDetailView(staff: staff)
                        }
                    }
                    .sheet(isPresented: $showingNewAssociateSheet) {
                        CreateAssociateView {
                            Task {
                                if let storeId = appVM.currentStoreId {
                                    await salesGoalVM.load(dataStore: appVM.dataStore, storeId: storeId)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            if let storeId = appVM.currentStoreId {
                await shiftPlanningVM.load(dataStore: appVM.dataStore, storeId: storeId)
                await salesGoalVM.load(dataStore: appVM.dataStore, storeId: storeId)
            }
        }
    }


    // MARK: - Goals Row
    private var goalsAndCommissionsRow: some View {
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
            
            if salesGoalVM.availableStaff.isEmpty {
                Text("No sales associates available.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(salesGoalVM.availableStaff) { staff in
                        StaffGoalCard(staff: staff, viewModel: salesGoalVM)
                    }
                }
            }
        }
    }


    // MARK: - All Staff Section
    private var allStaffSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "All Staff", subtitle: "Currently assigned to this store")
            
            if shiftPlanningVM.allStaff.isEmpty {
                Text("No staff found for this store.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(shiftPlanningVM.allStaff) { staff in
                        staffProgressCard(staff)
                    }
                }
            }
        }
    }
    
    // MARK: - Staff Progress Card
    private func staffProgressCard(_ staff: UserProfile) -> some View {
        let goal = salesGoalVM.activeGoals.first { $0.staffId == staff.id }
        let targetAmount = goal?.targetAmount ?? 0.0
        let achievedAmount = goal?.achievedAmount ?? 0.0
        let progress = targetAmount > 0 ? min(1.0, achievedAmount / targetAmount) : 0.0
        
        return HStack(spacing: 16) {
            // Profile
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Text(String(staff.fullName.prefix(1)))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RSMSTheme.gold)
            }
            
            // Name & Role
            VStack(alignment: .leading, spacing: 4) {
                Text(staff.fullName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text(staff.role.displayName)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                if targetAmount > 0 {
                    Text("Target: \(targetAmount.formatted(.currency(code: "INR").precision(.fractionLength(0))))")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            
            Spacer()
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(RSMSTheme.surfaceTertiary, lineWidth: 5)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(RSMSTheme.gold, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(RSMSTheme.gold)
            }
        }
        .rsmsCard(padding: 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(staff.fullName), \(staff.role.displayName)")
        .accessibilityValue(targetAmount > 0 ? "Target: \(targetAmount.formatted(.currency(code: "INR").precision(.fractionLength(0)))), Progress: \(Int(progress * 100))%" : "Progress: \(Int(progress * 100))%")
    }
}

// MARK: - Dynamic Goal Card
struct StaffGoalCard: View {
    let staff: UserProfile
    var viewModel: SalesGoalViewModel
    var onNameTap: (() -> Void)? = nil
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPeriod: GoalPeriod = .monthly
    
    var body: some View {
        let currentGoal = viewModel.activeGoals.first { $0.staffId == staff.id && $0.period == selectedPeriod }
        
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    onNameTap?()
                } label: {
                    Text(staff.fullName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // MARK: The 4 Filter Buttons (Added Quarterly)
                HStack(spacing: 4) {
                    ForEach([GoalPeriod.weekly, .monthly], id: \.self) { period in
                        Button {
                            withAnimation(reduceMotion ? nil : .snappy) { selectedPeriod = period }
                        } label: {
                            Text(period.rawValue.capitalized)
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .rsmsCard(padding: 16)
    }
}

#Preview("Staff & Shift Planning") {
    StaffShiftPlanningView()
        .environment(AppViewModel())
}
