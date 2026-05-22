import SwiftUI

struct StoreDashboardView: View {
    // MARK: - Environment
    @Environment(AppViewModel.self) private var appVM
    
    // MARK: - View Models & State
    @State private var dashboardVM = BoutiqueDashboardViewModel()
    @State private var showingNotifications = false
    @State private var showingAppointments = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
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
            } else if dashboardVM.todaySales == 0 && dashboardVM.salesTarget == 0 && dashboardVM.shifts.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.pie",
                    description: Text("Dashboard data is unavailable for this store. Start logging transactions to see insights.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        headerSection
                        kpiCardsRow
                        salesProgressCard
                        staffSection
                    }
                    .padding(24)
                }
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Store Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                notificationBell
            }
        }
        .sheet(isPresented: $showingNotifications) {
            LowStockNotificationView(dashboardVM: dashboardVM)
        }
        .sheet(isPresented: $showingAppointments) {
            TodayAppointmentsSheet()
        }
        .task {
            if let storeId = appVM.currentStoreId {
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
                
                if !dashboardVM.lowStockAlerts.isEmpty {
                    let count = dashboardVM.lowStockAlerts.count
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
            .animation(.spring(response: 0.3), value: dashboardVM.lowStockAlerts.count)
        }
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
            columns: columns,
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
                showingAppointments = true
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
                showingNotifications = true
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
        }
    }
    
    // MARK: - Sales Progress
    private var salesProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Sales Progress")
            
            HStack(spacing: 32) {
                CircularProgressView(
                    progress: dashboardVM.salesProgress,
                    label: "of target",
                    value: "\(Int(dashboardVM.salesProgress * 100))%"
                )
                
                VStack(alignment: .leading, spacing: 16) {
                    metricRow(
                        label: "Target",
                        value: dashboardVM.formatCurrency(dashboardVM.salesTarget),
                        color: RSMSTheme.textSecondary
                    )
                    
                    metricRow(
                        label: "Actual",
                        value: dashboardVM.formatCurrency(dashboardVM.todaySales),
                        color: RSMSTheme.gold
                    )
                    
                    metricRow(
                        label: "Remaining",
                        value: dashboardVM.formatCurrency(max(0, dashboardVM.salesTarget - dashboardVM.todaySales)),
                        color: RSMSTheme.warning
                    )
                }
            }
        }
        .rsmsCard()
    }
    
    // MARK: - Staff Section
    private var staffSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Staff on Shift Today",
                subtitle: "\(dashboardVM.shifts.count) team members"
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(dashboardVM.shifts.prefix(3)) { shift in
                        staffShiftCard(shift)
                            .frame(width: 260)
                    }
                    
                    if dashboardVM.shifts.count > 3 {
                        NavigationLink(destination: StaffView()) {
                            HStack {
                                Text("See All")
                                    .font(.subheadline.weight(.semibold))
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(RSMSTheme.primaryDark)
                            .padding(.horizontal, 24)
                            .frame(maxHeight: .infinity)
                            .background(RSMSTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
        }
    }
    
    private func staffShiftCard(_ shift: StaffShift) -> some View {
        let name = appVM.dataStore.userName(for: shift.staffId)
        
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(String(name.prefix(1)))
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.gold)
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
                    .foregroundStyle(RSMSTheme.gold)
                
                if let notes = shift.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
        }
        .rsmsCard(padding: 16)
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
    
    var body: some View {
        NavigationStack {
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
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
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
