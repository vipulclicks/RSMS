//
//  InventoryDashboardSections.swift
//  RSMS
//
//  All dashboard card sections for InventoryControllerHomeView.
//  Split into a separate file to keep the navigation shell readable.
//  Access to @State and @Environment properties is provided by the extension.
//

import SwiftUI

extension InventoryControllerHomeView {

    // MARK: - Greeting

    var greetingSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CONTROLLER")
                    .font(.caption.weight(.medium))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)

                let firstName = viewModel.currentUser?.fullName
                    .components(separatedBy: " ").first ?? "Controller"
                Text("Hello, \(firstName)")
                    .font(.title2.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
            }

            Spacer()

            TimelineView(.periodic(from: .now, by: 60)) { context in
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(context.date.formatted(.dateTime.hour().minute()))
                        .font(.title3.bold())
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
            }
        }
    }

    // MARK: - Hero KPI Card

    var heroKPICard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL INVENTORY")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(RSMSTheme.gold)
                    Text(dashVM.snapshot.totalInventoryCount.formatted())
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.gold)
                }
                Spacer()
                Image(systemName: "shippingbox.fill")
                    .font(.title)
                    .foregroundStyle(RSMSTheme.gold.opacity(0.4))
                    .padding(12)
                    .background(RSMSTheme.gold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Rectangle().fill(RSMSTheme.divider).frame(height: 1)

            HStack(spacing: 12) {
                // Circular progress ring
                ZStack {
                    Circle().stroke(RSMSTheme.gold.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: dashVM.snapshot.scanCompletionPercent)
                        .stroke(RSMSTheme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: dashVM.snapshot.scanCompletionPercent)
                    Text("\(Int(dashVM.snapshot.scanCompletionPercent * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(RSMSTheme.gold)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S SCANS")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(RSMSTheme.gold.opacity(0.15)).frame(height: 6)
                            Capsule()
                                .fill(RSMSTheme.gold)
                                .frame(
                                    width: geo.size.width * dashVM.snapshot.scanCompletionPercent,
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 0.8), value: dashVM.snapshot.scanCompletionPercent)
                        }
                    }
                    .frame(height: 6)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(dashVM.snapshot.todaysScanCount)")
                        .font(.title3.bold())
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("UNITS")
                        .font(.caption2)
                        .tracking(1)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
        }
        .padding(20)
        .background(RSMSTheme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Alert + Tasks Row

    @ViewBuilder
    var alertTasksRow: some View {
        if horizontalSizeClass == .regular {
            HStack(spacing: 12) { lowStockCard; pendingTasksCard }
        } else {
            VStack(spacing: 12) { lowStockCard; pendingTasksCard }
        }
    }

    var lowStockCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("+\(dashVM.snapshot.newLowStockCount) New")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.gold.opacity(0.12))
                    .clipShape(Capsule())
            }
            Text("LOW STOCK")
                .font(.caption2.weight(.medium))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("\(dashVM.snapshot.lowStockAlertCount) Alerts")
                .font(.title3.bold())
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.gold.opacity(0.35), lineWidth: 1)
        )
    }

    var pendingTasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist").foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                Text("Active")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.textPrimary.opacity(0.08))
                    .clipShape(Capsule())
            }
            Text("PENDING")
                .font(.caption2.weight(.medium))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("\(dashVM.snapshot.pendingTaskCount) Tasks")
                .font(.title3.bold())
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // MARK: - System Control

    var systemControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SYSTEM CONTROL")
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(RSMSTheme.gold)

            VStack(spacing: 0) {
                Button {
                    selectedDestination = .scan
                } label: {
                    controlRow(
                        icon: "barcode.viewfinder",
                        title: "Scan Item",
                        subtitle: "Scan barcode to add inventory"
                    )
                }
                .buttonStyle(.plain)

                dashedDivider

                Button {
                    selectedDestination = .scan
                } label: {
                    controlRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Verify Inventory",
                        subtitle: "Switch to Verify mode in the scanner"
                    )
                }
                .buttonStyle(.plain)

                dashedDivider

                Button {
                    selectedDestination = .scan
                } label: {
                    controlRow(
                        icon: "clock.arrow.circlepath",
                        title: "Audit Log",
                        subtitle: "Switch to Audit mode in the scanner"
                    )
                }
                .buttonStyle(.plain)

                dashedDivider

                Button {
                    selectedDestination = .reconcile
                } label: {
                    controlRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Stock Reconciliation",
                        subtitle: "Resolve inventory discrepancies"
                    )
                }
                .buttonStyle(.plain)

            }
            .background(RSMSTheme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
    }

    func controlRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.gold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RSMSTheme.gold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.gold.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    var dashedDivider: some View {
        Rectangle()
            .fill(RSMSTheme.divider)
            .frame(height: 0.5)
            .padding(.horizontal, 14)
    }

    // MARK: - Activity Feed

    var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVITY FEED")
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Button("VIEW ALL") { }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.gold)
            }

            VStack(spacing: 0) {
                let entries = Array(dashVM.snapshot.recentActivity.prefix(5).enumerated())
                ForEach(entries, id: \.element.id) { index, entry in
                    activityRow(entry: entry)
                    if index < entries.count - 1 {
                        Rectangle()
                            .fill(RSMSTheme.divider)
                            .frame(height: 0.5)
                            .padding(.horizontal, 14)
                    }
                }
            }
            .background(RSMSTheme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
    }

    func activityRow(entry: AuditTrail) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold)
                    .frame(width: 36, height: 36)
                Text(entry.action.prefix(1))
                    .font(.caption.bold())
                    .foregroundStyle(RSMSTheme.background)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.action)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                if let details = entry.details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(entry.timestamp.formatted(.dateTime.hour().minute()))
                .font(.caption2)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
