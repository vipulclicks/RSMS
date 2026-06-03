//
//  InventoryDashboardSections.swift
//  RSMS
//
//  All dashboard card sections for InventoryControllerHomeView
//

import SwiftUI

extension InventoryControllerHomeView {

    // MARK: - Greeting Section

    var greetingSection: some View {
        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 4) {

                Text("CONTROLLER")
                    .font(.caption.weight(.medium))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)

                Text(
                    "Hello, \(viewModel.currentUser?.fullName.components(separatedBy: " ").first ?? "Controller")"
                )
                .font(.title2.bold())
                .foregroundStyle(RSMSTheme.textPrimary)
            }

            Spacer()
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

                    Text(
                        String(dashVM.snapshot?.totalInventoryCount ?? 0)
                    )
                    .font(
                        .system(
                            size: 48,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(RSMSTheme.gold)
                }

                Spacer()

                Image(systemName: "shippingbox.fill")
                    .font(.title)
                    .foregroundStyle(
                        RSMSTheme.gold.opacity(0.4)
                    )
                    .padding(12)
                    .background(
                        RSMSTheme.gold.opacity(0.08)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
            }

            Rectangle()
                .fill(RSMSTheme.divider)
                .frame(height: 1)

            HStack(spacing: 12) {

                // MARK: Progress Ring

                ZStack {

                    Circle()
                        .stroke(
                            RSMSTheme.gold.opacity(0.15),
                            lineWidth: 6
                        )

                    Circle()
                        .trim(
                            from: 0,
                            to: dashVM.snapshot?.scanCompletionPercent ?? 0.0
                        )
                        .stroke(
                            RSMSTheme.gold,
                            style: StrokeStyle(
                                lineWidth: 6,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(
                            .easeInOut(duration: 0.8),
                            value: dashVM.snapshot?.scanCompletionPercent ?? 0.0
                        )

                    Text(
                        "\(Int((dashVM.snapshot?.scanCompletionPercent ?? 0.0) * 100))%"
                    )
                    .font(.caption2.bold())
                    .foregroundStyle(RSMSTheme.gold)
                }
                .frame(width: 44, height: 44)

                // MARK: Progress Bar

                VStack(alignment: .leading, spacing: 6) {

                    Text("TODAY'S SCANS")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(RSMSTheme.textTertiary)

                    GeometryReader { geo in

                        ZStack(alignment: .leading) {

                            Capsule()
                                .fill(
                                    RSMSTheme.gold.opacity(0.15)
                                )
                                .frame(height: 6)

                            Capsule()
                                .fill(RSMSTheme.gold)
                                .frame(
                                    width: geo.size.width *
                                    (dashVM.snapshot?.scanCompletionPercent ?? 0.0),
                                    height: 6
                                )
                                .animation(
                                    .easeInOut(duration: 0.8),
                                    value: dashVM.snapshot?.scanCompletionPercent ?? 0.0
                                )
                        }
                    }
                    .frame(height: 6)
                }

                // MARK: Units

                VStack(alignment: .trailing, spacing: 2) {

                    Text(
                        "\(dashVM.snapshot?.todaysScanCount ?? 0)"
                    )
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
        .background(RSMSTheme.surfacePrimary)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    RSMSTheme.gold.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Action Grid

    @ViewBuilder
    var actionGrid: some View {

        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

        if horizontalSizeClass == .regular {

            LazyVGrid(columns: columns, spacing: 16) {

                lowStockCard
                transferCard
                dcShipmentsCard
                vendorReturnsCard
                serviceTrackingCard
                cycleCountCard
                auditReconcileCard
            }

        } else {

            VStack(spacing: 16) {

                lowStockCard
                transferCard
                dcShipmentsCard
                vendorReturnsCard
                serviceTrackingCard
                cycleCountCard
                auditReconcileCard
            }
        }
    }

    // MARK: - Reusable Action Card

    private func actionCard(
        title: String,
        subtitle: String,
        icon: String,
        accentColor: Color,
        badgeText: String?,
        action: @escaping () -> Void
    ) -> some View {

        Button {

            action()

        } label: {

            VStack(alignment: .leading, spacing: 12) {

                HStack {

                    Image(systemName: icon)
                        .foregroundStyle(accentColor)

                    Spacer()

                    if let badgeText {

                        Text(badgeText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                accentColor.opacity(0.12)
                            )
                            .clipShape(Capsule())
                    }
                }

                Text(subtitle)
                    .font(.caption2.weight(.medium))
                    .tracking(1.5)
                    .foregroundStyle(RSMSTheme.textTertiary)

                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding(16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(RSMSTheme.surfacePrimary)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        accentColor.opacity(0.35),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cards

    var lowStockCard: some View {

        actionCard(
            title: "\(dashVM.snapshot?.lowStockAlertCount ?? 0) Alerts",
            subtitle: "LOW STOCK",
            icon: "exclamationmark.triangle.fill",
            accentColor: RSMSTheme.gold,
            badgeText: "+\(dashVM.snapshot?.newLowStockCount ?? 0) New"
        ) {
            selectedDestination = .notify
        }
    }
    var cycleCountCard: some View {

        actionCard(
            title: "Cycle Counts",
            subtitle: "VERIFY STOCK",
            icon: "arrow.triangle.2.circlepath",
            accentColor: RSMSTheme.success,
            badgeText: "\(dashVM.snapshot?.pendingTaskCount ?? 0) Tasks"
        ) {
            selectedDestination = .cycleCounts
        }
    }

    var auditReconcileCard: some View {

        actionCard(
            title: "Reconcile",
            subtitle: "DISCREPANCIES",
            icon: "doc.text.magnifyingglass",
            accentColor: RSMSTheme.warning,
            badgeText: "Audit"
        ) {
            selectedDestination = .auditReconcile
        }
    }

    var transferCard: some View {

        actionCard(
            title: "Transfers",
            subtitle: "STORE TRANSFERS",
            icon: "arrow.left.arrow.right",
            accentColor: RSMSTheme.info,
            badgeText: "Manage"
        ) {
            selectedDestination = .transfer
        }
    }

    var dcShipmentsCard: some View {

        actionCard(
            title: "DC Shipments",
            subtitle: "REPLENISHMENT",
            icon: "shippingbox.and.arrow.backward.fill",
            accentColor: Color(hue: 0.52, saturation: 0.6, brightness: 0.75),
            badgeText: "Inbound"
        ) {
            selectedDestination = .dcReplenishment
        }
    }

    var vendorReturnsCard: some View {

        actionCard(
            title: "Vendor Returns",
            subtitle: "RMA / DEFECTIVE",
            icon: "shippingbox.and.arrow.forward.fill",
            accentColor: Color(hue: 0.8, saturation: 0.6, brightness: 0.6),
            badgeText: "Manage"
        ) {
            selectedDestination = .vendorReturns
        }
    }
    
    var serviceTrackingCard: some View {

        actionCard(
            title: "Service Center",
            subtitle: "REPAIRS & LOGISTICS",
            icon: "wrench.and.screwdriver.fill",
            accentColor: RSMSTheme.primary,
            badgeText: "Track"
        ) {
            selectedDestination = .serviceTracking
        }
    }

    // MARK: - Activity Feed

    var activityFeedSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text("ACTIVITY FEED")
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(RSMSTheme.gold)
            }

            VStack(spacing: 0) {

                let entries = Array(
                    (dashVM.snapshot?.recentActivity ?? [])
                        .prefix(5)
                        .enumerated()
                )

                ForEach(entries, id: \.offset) { item in

                    activityRow(entry: item.element)

                    if item.offset < entries.count - 1 {

                        Rectangle()
                            .fill(RSMSTheme.divider)
                            .frame(height: 0.5)
                            .padding(.horizontal, 14)
                    }
                }
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        RSMSTheme.border,
                        lineWidth: 1
                    )
            )
            
            Button {
                selectedDestination = .auditTrail
            } label: {
                Text("View All Activity")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RSMSTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Activity Row

    func activityRow(entry: AuditTrail) -> some View {

        HStack(spacing: 12) {

            ZStack {

                Circle()
                    .fill(RSMSTheme.gold)
                    .frame(width: 36, height: 36)

                Text(String(entry.action.prefix(1)))
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

            Text(
                entry.timestamp.formatted(
                    .dateTime.hour().minute()
                )
            )
            .font(.caption2)
            .foregroundStyle(RSMSTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
