import SwiftUI
import Charts

enum DashboardRoute: Hashable {
    case appointments
    case lowStock
    case approvals
}

struct StoreDashboardView: View {
    // MARK: - Environment
    @Environment(AppViewModel.self) private var appVM
    
    // MARK: - View Models & State
    @State private var dashboardVM = BoutiqueDashboardViewModel()
    @State private var cycleCountVM = CycleCountViewModel()
    @State private var lookbookVM = LookbookViewModel()
    @State private var navPath = NavigationPath()
    @State private var showingNotifications = false
    @State private var showingProfile = false
    @State private var showingSalesBreakdown = false
    @State private var carouselSelection: Int = 0
    @State private var selectedSalesDate: Date? = nil
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var kpiColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
            if dashboardVM.isLoading {
                ProgressView("Loading Dashboard...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = dashboardVM.errorMessage {
                ContentUnavailableView(
                    "Dashboard Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        headerSection
                        kpiCardsRow
                        salesProgressCard
                        
                        CycleCountSectionView(cycleCountVM: cycleCountVM)
                        
                        LookbookSectionView(lookbookVM: lookbookVM, navPath: $navPath)
                    }
                    .padding(24)
                }
            }
        }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Store Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        profileButton
                    }
                }
            }
            .navigationDestination(for: DashboardRoute.self) { route in
                switch route {
                case .appointments:
                    TodayAppointmentsSheet()
                case .lowStock:
                    ScrollView {
                        InventoryAlertsView(dashboardVM: dashboardVM)
                            .padding(32)
                    }
                    .background(RSMSTheme.background.ignoresSafeArea())
                    .navigationTitle("Inventory Alerts")
                    .navigationBarTitleDisplayMode(.inline)
                case .approvals:
                    ApprovalDashboardView()
                }
            }
            .navigationDestination(for: Lookbook.self) { lookbook in
                LookbookDetailView(lookbook: lookbook, lookbookVM: lookbookVM)
            }
            .navigationDestination(isPresented: $showingProfile) {
                BoutiqueManagerProfileView()
            }
            .sheet(isPresented: $showingNotifications) {
                NavigationStack {
                    ManagerNotificationSheet(dashboardVM: dashboardVM)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showingNotifications = false }
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.gold)
                            }
                        }
                }
            }
            .sheet(isPresented: $showingSalesBreakdown) {
                NavigationStack {
                    Group {
                        if dashboardVM.todaySalesByStaff.isEmpty {
                            ContentUnavailableView("No Sales Today", systemImage: "indianrupeesign.circle", description: Text("There are no completed transactions for today yet."))
                        } else {
                            List(dashboardVM.todaySalesByStaff) { staff in
                                HStack {
                                    Text(staff.staffName)
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Text(dashboardVM.formatCurrency(staff.totalSales))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.primaryDark)
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(RSMSTheme.surfacePrimary)
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden)
                        }
                    }
                    .background(RSMSTheme.background.ignoresSafeArea())
                    .navigationTitle("Today's Sales Breakdown")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showingSalesBreakdown = false }
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.gold)
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .task {
                if let storeId = appVM.currentStoreId {
                    await dashboardVM.load(dataStore: appVM.dataStore, storeId: storeId)
                    await cycleCountVM.load(dataStore: appVM.dataStore, storeId: storeId)
                }
                await lookbookVM.load(dataStore: appVM.dataStore)
            }
            .onChange(of: appVM.dataStore.salesGoals) { _, _ in
                reloadDashboard()
            }
            .onChange(of: appVM.dataStore.transactions.count) { _, _ in
                reloadDashboard()
            }
        }
    }
    
    private func reloadDashboard() {
        if let storeId = appVM.currentStoreId {
            Task {
                await dashboardVM.load(dataStore: appVM.dataStore, storeId: storeId)
            }
        }
    }
    
    // MARK: - Notification Bell
    private var notificationBell: some View {
        Button {
            showingNotifications = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                if !dashboardVM.lowStockAlerts.isEmpty || pendingApprovalsCount > 0 {
                    let count = dashboardVM.lowStockAlerts.count + pendingApprovalsCount
                    let displayText = count > 99 ? "99+" : "\(count)"
                    
                    Text(displayText)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(RSMSTheme.cream)
                        .padding(.horizontal, count >= 10 ? 4 : 0)
                        .frame(
                            minWidth: count >= 10 ? 10 : 14,
                            minHeight: 14
                        )
                        .background(RSMSTheme.danger)
                        .clipShape(Capsule())
                        .offset(x: 2, y: -6)
                        .transition(.scale)
                }
            }
            .animation(.spring(response: 0.3), value: dashboardVM.lowStockAlerts.count + pendingApprovalsCount)
        }
    }
    
    private var pendingApprovalsCount: Int {
        appVM.dataStore.discountApprovalRequests.filter { $0.status == .pending }.count
    }
    
    // MARK: - Profile Button
    private var profileButton: some View {
        Button {
            showingProfile = true
        } label: {
            ZStack {
                Circle()
                    .fill(RSMSTheme.primaryGradient)
                    .frame(width: 32, height: 32)
                
                if let user = appVM.currentUser {
                    Text(getInitials(from: user.fullName))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(RSMSTheme.cream)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(RSMSTheme.cream)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return ""
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back")
                .font(.title2.weight(.bold))
                .foregroundStyle(RSMSTheme.primaryDark)
            
            Text(formattedDate)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
    }
    
    private var kpiCardsRow: some View {
        return LazyVGrid(
            columns: kpiColumns,
            alignment: .leading,
            spacing: 16
        ) {
            Button {
                showingSalesBreakdown = true
            } label: {
                KPICard(
                    icon: "indianrupeesign.square.fill",
                    value: dashboardVM.formatCurrency(dashboardVM.todaySales),
                    label: "Today's Sales",
                    trend: "\(dashboardVM.todayTransactions.count) transactions",
                    trendColor: RSMSTheme.success
                )
            }
            .buttonStyle(.plain)
            
            Button {
                navPath.append(DashboardRoute.appointments)
            } label: {
                KPICard(
                    icon: "calendar.badge.clock",
                    value: "\(dashboardVM.appointmentCount)",
                    label: "Appointments Today",
                    iconColor: RSMSTheme.info
                )
            }
            .buttonStyle(.plain)
            
            Button {
                navPath.append(DashboardRoute.lowStock)
            } label: {
                KPICard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(dashboardVM.lowStockAlerts.count)",
                    label: "Low Stock Alerts",
                    iconColor: dashboardVM.lowStockAlerts.isEmpty
                    ? RSMSTheme.success
                    : RSMSTheme.warning
                )
            }
            .buttonStyle(.plain)
            
            Button {
                navPath.append(DashboardRoute.approvals)
            } label: {
                KPICard(
                    icon: "tag.fill",
                    value: "\(pendingApprovalsCount)",
                    label: "Pending Approvals",
                    iconColor: pendingApprovalsCount == 0
                    ? RSMSTheme.success
                    : .orange
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var salesProgressCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionHeader(title: "Sales Progress")
                Spacer()
                Picker("Period", selection: Bindable(dashboardVM).selectedPeriod) {
                    ForEach([GoalPeriod.weekly, GoalPeriod.monthly], id: \.self) { period in
                        Text(period.rawValue.capitalized).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)
            
            if dashboardVM.periodAchievedAmount > 0 || dashboardVM.hasGoalsForPeriod {
                TabView(selection: $carouselSelection) {
                    storeSalesOverviewSlide
                        .tag(0)
                        
                    storeSalesChartSlide
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(height: 330)
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(RSMSTheme.primaryDark)
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor(RSMSTheme.textTertiary)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 36))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("No \(dashboardVM.selectedPeriod.rawValue) sales yet")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("Check back later or set targets for your associates.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 64)
            }
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: RSMSTheme.border, radius: 15, x: 0, y: 5)
    }
    
    private var storeSalesOverviewSlide: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Store Sales")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text(dashboardVM.formatCurrency(dashboardVM.periodAchievedAmount))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(RSMSTheme.primaryDark)
                }
                Spacer()
                
                if dashboardVM.salesIncrementPercentage > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text(String(format: "%.1f%%", dashboardVM.salesIncrementPercentage))
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.success.opacity(0.15))
                    .foregroundStyle(RSMSTheme.success)
                    .clipShape(Capsule())
                } else if dashboardVM.salesIncrementPercentage < 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right")
                        Text(String(format: "%.1f%%", abs(dashboardVM.salesIncrementPercentage)))
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.danger.opacity(0.15))
                    .foregroundStyle(RSMSTheme.danger)
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 32) {
                ZStack {
                    // Permanent background ring
                    Circle()
                        .stroke(RSMSTheme.border, lineWidth: 14)
                        .frame(width: 126, height: 126)
                    
                    Chart {
                        if dashboardVM.salesTarget > 0 {
                            SectorMark(
                                angle: .value("Achieved", dashboardVM.periodAchievedAmount),
                                innerRadius: .ratio(0.8),
                                angularInset: 2.0
                            )
                            .cornerRadius(4)
                            .foregroundStyle(RSMSTheme.gold)
                            
                            if dashboardVM.salesTarget > dashboardVM.periodAchievedAmount {
                                SectorMark(
                                    angle: .value("Remaining", dashboardVM.salesTarget - dashboardVM.periodAchievedAmount),
                                    innerRadius: .ratio(0.8),
                                    angularInset: 2.0
                                )
                                .foregroundStyle(Color.clear)
                            }
                        }
                    }
                    .frame(width: 140, height: 140)
                    
                    VStack(spacing: 4) {
                        if dashboardVM.salesTarget > 0 {
                            Text("\(Int(dashboardVM.salesProgress * 100))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("of target")
                                .font(.system(size: 11))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        } else {
                            Text("0%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("No Target")
                                .font(.system(size: 11))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }
                }
                
                VStack(spacing: 20) {
                    metricRow(label: "Target", value: dashboardVM.formatCurrency(dashboardVM.salesTarget), color: RSMSTheme.textSecondary)
                    metricRow(label: "Actual", value: dashboardVM.formatCurrency(dashboardVM.periodAchievedAmount), color: RSMSTheme.gold)
                    
                    let remaining = max(0, dashboardVM.salesTarget - dashboardVM.periodAchievedAmount)
                    metricRow(label: "Remaining", value: dashboardVM.formatCurrency(remaining), color: RSMSTheme.gold)
                }
            }
            .padding(24)
            .background(RSMSTheme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            Spacer()
        }
        .padding(24)
    }
    
    private var storeSalesChartSlide: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack(alignment: .top) {
                Text(dashboardVM.formatCurrency(dashboardVM.periodAchievedAmount))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(RSMSTheme.primaryDark)
                
                Spacer()
                
                if dashboardVM.salesIncrementPercentage > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text(String(format: "%.1f%%", dashboardVM.salesIncrementPercentage))
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.success.opacity(0.15))
                    .foregroundStyle(RSMSTheme.success)
                    .clipShape(Capsule())
                } else if dashboardVM.salesIncrementPercentage < 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right")
                        Text(String(format: "%.1f%%", abs(dashboardVM.salesIncrementPercentage)))
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.danger.opacity(0.15))
                    .foregroundStyle(RSMSTheme.danger)
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                Chart {
                    ForEach(dashboardVM.chartSalesData) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Sales", data.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(RSMSTheme.primaryDark)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("Sales", data.amount)
                        )
                        .foregroundStyle(RSMSTheme.primaryDark)
                        .symbolSize(selectedSalesDate == data.date ? 150 : 50)
                        .annotation(position: .top) {
                            if selectedSalesDate != data.date && data.amount > 0 {
                                Text(dashboardVM.formatCurrency(data.amount))
                                    .font(.system(size: 9))
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                        }
                        
                        AreaMark(
                            x: .value("Date", data.date),
                            y: .value("Sales", data.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [RSMSTheme.primaryDark.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        if let selectedDate = selectedSalesDate, selectedDate == data.date {
                            RuleMark(
                                x: .value("Selected", selectedDate)
                            )
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .top, spacing: 10, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                VStack {
                                    Text(dashboardVM.formatCurrency(data.amount))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(RSMSTheme.primaryDark)
                                    if dashboardVM.selectedPeriod == .monthly {
                                        Text(data.date, format: .dateTime.month())
                                            .font(.system(size: 10))
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    } else {
                                        if let endDate = Calendar.current.date(byAdding: .day, value: 6, to: data.date) {
                                            Text("\(data.date.formatted(.dateTime.day().month())) - \(endDate.formatted(.dateTime.day().month()))")
                                                .font(.system(size: 10))
                                                .foregroundStyle(RSMSTheme.textSecondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(RSMSTheme.surfacePrimary)
                                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                                )
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: dashboardVM.chartSalesData.map { $0.date }) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(RSMSTheme.border)
                        if let date = value.as(Date.self) {
                            AxisValueLabel(anchor: .top) {
                                if dashboardVM.selectedPeriod == .monthly {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .font(.system(size: 10))
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                } else {
                                    if let endDate = Calendar.current.date(byAdding: .day, value: 6, to: date) {
                                        Text("\(date.formatted(.dateTime.day().month(.abbreviated)))-\n\(endDate.formatted(.dateTime.day().month(.abbreviated)))")
                                            .font(.system(size: 8))
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let location = value.location
                                        let x = location.x - geometry[proxy.plotAreaFrame].origin.x
                                        if let date: Date = proxy.value(atX: x) {
                                            let closest = dashboardVM.chartSalesData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
                                            if let closestDate = closest?.date {
                                                selectedSalesDate = closestDate
                                            }
                                        }
                                    }
                                    .onEnded { _ in }
                            )
                            .simultaneousGesture(
                                TapGesture(count: 2)
                                    .onEnded { selectedSalesDate = nil }
                            )
                    }
                }
                .frame(height: 150)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text(dashboardVM.formatCurrency(dashboardVM.salesTarget))
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Progress")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text("\(Int(dashboardVM.salesProgress * 100))%")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private func associateProgressSlide(_ progress: BoutiqueDashboardViewModel.AssociateSalesProgress) -> some View {
        VStack(alignment: .center, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primaryGradient)
                        .frame(width: 44, height: 44)
                    Text(String(progress.associateName.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(RSMSTheme.cream)
                }
                Text(progress.associateName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                // Permanent background ring
                Circle()
                    .stroke(RSMSTheme.border, lineWidth: 30)
                    .frame(width: 170, height: 170)
                
                Chart {
                    if let target = progress.targetAmount, target > 0 {
                        SectorMark(
                            angle: .value("Achieved", progress.achievedAmount),
                            innerRadius: .ratio(0.7),
                            angularInset: 2.0
                        )
                        .cornerRadius(4)
                        .foregroundStyle(RSMSTheme.primaryDark)
                        
                        if target > progress.achievedAmount {
                            SectorMark(
                                angle: .value("Remaining", target - progress.achievedAmount),
                                innerRadius: .ratio(0.7),
                                angularInset: 2.0
                            )
                            .foregroundStyle(Color.clear)
                        }
                    }
                }
                .frame(width: 200, height: 200)
                
                VStack(spacing: 4) {
                    if let target = progress.targetAmount, target > 0 {
                        Text("\(Int(progress.progressPercentage * 100))%")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSTheme.primaryDark)
                        Text("Achieved")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    } else {
                        Text("0%")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSTheme.primaryDark)
                        Text("No Target")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
            
            HStack(spacing: 24) {
                VStack {
                    Text("Sales")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(dashboardVM.formatCurrency(progress.achievedAmount))
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.primaryDark)
                }
                
                if let target = progress.targetAmount {
                    Divider().frame(height: 30)
                    VStack {
                        Text("Target")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text(dashboardVM.formatCurrency(target))
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RSMSTheme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
        }
        .padding(24)
    }
    
    // MARK: - Staff Section
    private var staffColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible(), spacing: 16)]
        } else {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }
    }
    
    private var staffSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Staff on Shift Today",
                subtitle: "\(dashboardVM.shifts.count) team members"
            )
            
            LazyVGrid(columns: staffColumns, spacing: 16) {
                ForEach(dashboardVM.shifts.prefix(4)) { shift in
                    staffShiftCard(shift)
                }
                
                if dashboardVM.shifts.count > 4 {
                    NavigationLink(destination: StaffView()) {
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(RSMSTheme.primaryDark)
                            Text("See All")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.primaryDark)
                            Text("\(dashboardVM.shifts.count - 4) more")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .background(RSMSTheme.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
        }
    }
    
    private func staffShiftCard(_ shift: StaffShift) -> some View {
        let name = appVM.dataStore.userName(for: shift.staffId)
        let status = shiftStatus(for: shift)
        let progress = shiftProgress(for: shift)
        
        return VStack(alignment: .leading, spacing: 0) {
            // Top section: Avatar + Name + Role badge
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.surfaceTertiary)
                        .frame(width: 52, height: 52)
                    
                    // Circular progress background
                    Circle()
                        .stroke(RSMSTheme.border, lineWidth: 3)
                        .frame(width: 52, height: 52)
                    
                    // Circular progress fill
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(statusColor(for: status), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                        
                    Text(String(name.prefix(1)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(RSMSTheme.primaryDark)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("\(shift.startTime) – \(shift.endTime)")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(RSMSTheme.textSecondary)
                }
                
                Spacer(minLength: 0)
            }
            .padding(18)
            
            // Role badge + Status
            HStack {
                Text(shift.role.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RSMSTheme.surfaceTertiary)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(status)
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(statusColor(for: status))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
            
            // Notes footer
            if let notes = shift.notes, !notes.isEmpty {
                Divider().overlay(RSMSTheme.border)
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(2)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            }
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: RSMSTheme.border, radius: 15, x: 0, y: 5)
    }
    
    // MARK: - Shift Helpers
    private func shiftStatus(for shift: StaffShift) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: shift.startTime),
              let end = formatter.date(from: shift.endTime) else {
            return "UPCOMING"
        }
        
        let now = Date()
        let cal = Calendar.current
        
        let startToday = cal.date(bySettingHour: cal.component(.hour, from: start), minute: cal.component(.minute, from: start), second: 0, of: now) ?? now
        let endToday = cal.date(bySettingHour: cal.component(.hour, from: end), minute: cal.component(.minute, from: end), second: 0, of: now) ?? now
        
        if now < startToday { return "UPCOMING" }
        if now > endToday { return "ENDED" }
        return "ACTIVE"
    }
    
    private func shiftProgress(for shift: StaffShift) -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: shift.startTime),
              let end = formatter.date(from: shift.endTime) else {
            return 0.0
        }
        
        let now = Date()
        let cal = Calendar.current
        
        let startToday = cal.date(bySettingHour: cal.component(.hour, from: start), minute: cal.component(.minute, from: start), second: 0, of: now) ?? now
        let endToday = cal.date(bySettingHour: cal.component(.hour, from: end), minute: cal.component(.minute, from: end), second: 0, of: now) ?? now
        
        if now < startToday { return 0.0 }
        if now > endToday { return 1.0 }
        
        let totalDuration = endToday.timeIntervalSince(startToday)
        let elapsed = now.timeIntervalSince(startToday)
        return max(0.0, min(1.0, elapsed / totalDuration))
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "ACTIVE": return RSMSTheme.primaryDark
        case "UPCOMING": return RSMSTheme.primary
        case "ENDED": return RSMSTheme.textSecondary
        default: return RSMSTheme.textSecondary
        }
    }
    
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
    
    private func highlightRow(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {
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
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: .now)
    }
}

// MARK: - Today's Appointments Sheet
struct TodayAppointmentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let todaysAppointments = appVM.dataStore.appointments.filter {
                        Calendar.current.isDateInToday($0.dateTime)
                    }.sorted { $0.dateTime < $1.dateTime }
                    
                    if todaysAppointments.isEmpty {
                        ContentUnavailableView(
                            "No Appointments",
                            systemImage: "calendar.badge.clock",
                            description: Text("No appointments scheduled for today.")
                        )
                    } else {
                        let cols = horizontalSizeClass == .compact ? [GridItem(.flexible())] : [GridItem(.flexible()), GridItem(.flexible())]
                        LazyVGrid(columns: cols, spacing: 16) {
                            ForEach(todaysAppointments) { appointment in
                                appointmentCard(appointment)
                            }
                        }
                    }
                }
                .padding(32)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Today's Appointments")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    private func appointmentCard(_ appointment: Appointment) -> some View {
        let clientName = appVM.dataStore.clientName(for: appointment.clientId)
        let associateName = appVM.dataStore.userName(for: appointment.associateId)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(clientName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                StatusBadge(text: appointment.status.rawValue, color: statusColor(for: appointment.status))
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(RSMSTheme.textSecondary)
                Text(appointment.dateTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(RSMSTheme.textSecondary)
                Text("With \(associateName)")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            if let notes = appointment.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .rsmsCard(padding: 16)
    }
    
    private func statusColor(for status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled: return RSMSTheme.info
        case .confirmed: return RSMSTheme.info
        case .inProgress: return RSMSTheme.primary
        case .completed: return RSMSTheme.success
        case .cancelled: return RSMSTheme.danger
        case .noShow: return RSMSTheme.warning
        }
    }
}

#Preview {
    NavigationStack {
        StoreDashboardView()
            .environment(AppViewModel())
    }
}
