import SwiftUI

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
    @State private var navPath: [DashboardRoute] = []
    @State private var showingNotifications = false
    @State private var showingProfile = false
    
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
                        
                        LookbookSectionView(lookbookVM: lookbookVM)
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
                        notificationBell
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
                LookbookDetailView(lookbook: lookbook)
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
            .task {
                if let storeId = appVM.currentStoreId {
                    await dashboardVM.load(dataStore: appVM.dataStore, storeId: storeId)
                    await cycleCountVM.load(dataStore: appVM.dataStore, storeId: storeId)
                }
                await lookbookVM.load(dataStore: appVM.dataStore)
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
            KPICard(
                icon: "indianrupeesign.square.fill",
                value: dashboardVM.formatCurrency(dashboardVM.todaySales),
                label: "Today's Sales",
                trend: "\(dashboardVM.todayTransactions.count) transactions",
                trendColor: RSMSTheme.success
            )
            
            Button {
                navPath.append(.appointments)
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
                navPath.append(.lowStock)
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
                navPath.append(.approvals)
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
    
    // MARK: - Sales Progress
    private var salesProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Sales Progress")
                Spacer()
                Picker("Period", selection: Bindable(dashboardVM).selectedPeriod) {
                    ForEach(GoalPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue.capitalized).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }
            
            if dashboardVM.hasGoalsForPeriod {
                if horizontalSizeClass == .compact {
                    VStack(spacing: 24) {
                        CircularProgressView(
                            progress: dashboardVM.salesProgress,
                            label: "of target",
                            value: "\(Int(dashboardVM.salesProgress * 100))%"
                        )
                        salesMetricsList
                    }
                } else {
                    HStack(spacing: 32) {
                        CircularProgressView(
                            progress: dashboardVM.salesProgress,
                            label: "of target",
                            value: "\(Int(dashboardVM.salesProgress * 100))%"
                        )
                        salesMetricsList
                    }
                }
                
                Text("\(dashboardVM.goalAssociateCount) associate\(dashboardVM.goalAssociateCount == 1 ? "" : "s") with \(dashboardVM.selectedPeriod.rawValue) goals")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            } else {
                // No goals empty state
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 36))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("No \(dashboardVM.selectedPeriod.rawValue) goal has been set")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("Set \(dashboardVM.selectedPeriod.rawValue) sales targets for your associates to track progress here.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            
            // Show individual associate sales for the period
            if !dashboardVM.periodAssociateProgress.isEmpty {
                Divider().overlay(RSMSTheme.divider)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sales by Associate")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    ForEach(dashboardVM.periodAssociateProgress) { progress in
                        HStack {
                            Text(progress.associateName)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            Spacer()
                            if let target = progress.targetAmount {
                                Text("\(dashboardVM.formatCurrency(progress.achievedAmount)) / \(dashboardVM.formatCurrency(target))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            } else {
                                Text("\(dashboardVM.formatCurrency(progress.achievedAmount))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                        }
                        
                        if progress.targetAmount != nil {
                            ProgressView(value: progress.progressPercentage)
                                .progressViewStyle(LinearProgressViewStyle(tint: RSMSTheme.primaryDark))
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .rsmsCard()
    }
    
    private var salesMetricsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            metricRow(
                label: "Target",
                value: dashboardVM.formatCurrency(dashboardVM.salesTarget),
                color: RSMSTheme.textSecondary
            )
            
            metricRow(
                label: "Achieved",
                value: dashboardVM.formatCurrency(dashboardVM.periodAchievedAmount),
                color: RSMSTheme.gold
            )
            
            metricRow(
                label: "Remaining",
                value: dashboardVM.formatCurrency(max(0, dashboardVM.salesTarget - dashboardVM.periodAchievedAmount)),
                color: RSMSTheme.warning
            )
        }
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
