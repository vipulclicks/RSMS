import SwiftUI

struct StoreDashboardView: View {
    // MARK: - View Models & State
    @State private var dashboardVM = StoreDashboardViewModel()
    @State private var showingNotifications = false
    
    private let summary = DashboardSummary.preview
    private let shifts = StaffShift.all
    private let store = Store.preview

    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                kpiCardsRow
                mainContentRow
                staffSection
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Store Dashboard")

        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                notificationBell
            }
        }

        .sheet(isPresented: $showingNotifications) {
            LowStockNotificationView(alerts: dashboardVM.lowStockAlerts)
        }
    }

    // MARK: - Native iOS Notification Bell
    private var notificationBell: some View {
        Button {
            showingNotifications = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    

                if !dashboardVM.lowStockAlerts.isEmpty {
                    let count = dashboardVM.lowStockAlerts.count
                    let displayText = count > 99 ? "99+" : "\(count)"

                    Text(displayText)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, count >= 10 ? 4 : 0)
                        .frame(
                            minWidth: count >= 10 ? 10 : 14,
                            minHeight: 14
                        )
                        .background(.red)
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back, Sophie")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            Spacer()

            Button {
                dashboardVM.simulateStockDrop()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(RSMSTheme.gold)

                    Text(store.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RSMSTheme.surfaceSecondary)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - KPI Cards
    private var kpiCardsRow: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            KPICard(
                icon: "indianrupeesign.square.fill",
                value: summary.salesActual.formatted(
                    .currency(code: "INR").precision(.fractionLength(0))
                ),
                label: "Today's Sales",
                trend: "\(Int(summary.salesActual / summary.salesTarget * 100))% of target",
                trendColor: summary.salesActual >= summary.salesTarget
                    ? RSMSTheme.success
                    : RSMSTheme.warning
            )

            KPICard(
                icon: "calendar.badge.clock",
                value: "\(summary.appointmentCount)",
                label: "Appointments",
                iconColor: RSMSTheme.info
            )

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

            KPICard(
                icon: "figure.walk.arrival",
                value: "\(summary.footfallCount ?? 0)",
                label: "Footfall Today",
                iconColor: RSMSTheme.success
            )
        }
    }

    // MARK: - Main Content
    private var mainContentRow: some View {
        HStack(spacing: 16) {
            VStack(spacing: 16) {
                SectionHeader(title: "Sales Progress")

                HStack(spacing: 32) {
                    CircularProgressView(
                        progress: summary.salesActual / summary.salesTarget,
                        label: "of target",
                        value: "\(Int(summary.salesActual / summary.salesTarget * 100))%"
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        metricRow(
                            label: "Target",
                            value: summary.salesTarget.formatted(
                                .currency(code: "INR").precision(.fractionLength(0))
                            ),
                            color: RSMSTheme.textSecondary
                        )

                        metricRow(
                            label: "Actual",
                            value: summary.salesActual.formatted(
                                .currency(code: "INR").precision(.fractionLength(0))
                            ),
                            color: RSMSTheme.gold
                        )

                        metricRow(
                            label: "Remaining",
                            value: (summary.salesTarget - summary.salesActual).formatted(
                                .currency(code: "INR").precision(.fractionLength(0))
                            ),
                            color: RSMSTheme.warning
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .rsmsCard()

            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Highlights")

                if let topCategory = summary.topSellingCategory {
                    highlightRow(
                        icon: "crown.fill",
                        title: "Top Selling",
                        value: topCategory,
                        color: RSMSTheme.gold
                    )
                }

                highlightRow(
                    icon: "calendar",
                    title: "Appointments",
                    value: "\(summary.appointmentCount) scheduled today",
                    color: RSMSTheme.info
                )

                highlightRow(
                    icon: "exclamationmark.shield.fill",
                    title: "Stock Alerts",
                    value: "\(dashboardVM.lowStockAlerts.count) items low",
                    color: RSMSTheme.warning
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .rsmsCard()
        }
    }

    // MARK: - Staff Section
    private var staffSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Staff on Shift Today",
                subtitle: "\(shifts.count) team members"
            )

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(shifts) { shift in
                    staffShiftCard(shift)
                }
            }
        }
    }

    private func staffShiftCard(_ shift: StaffShift) -> some View {
        let name = UserProfile.all.first(where: { $0.id == shift.staffId })?.fullName ?? "Unknown"

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
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: .now)
    }
}

#Preview {
    NavigationStack {
        StoreDashboardView()
    }
}
