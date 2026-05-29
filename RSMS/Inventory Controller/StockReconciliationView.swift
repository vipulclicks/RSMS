//
//  StockReconciliationView.swift
//  RSMS
//
//  Premium mobile UI for Inventory Controllers to identify and resolve
//  stock mismatches between physical inventory and system records.
//  Follows the luxury beige-burgundy design language of RSMSTheme.
//

import SwiftUI

struct StockReconciliationView: View {

    @Environment(AppViewModel.self) private var appVM

    @State private var viewModel = StockReconciliationViewModel()
    @State private var appeared = false
    @State private var showSearchField = false
    @State private var showFilterMenu = false
    @State private var showShrinkageAnalysis = false

    // Segment control
    enum ReconcileSegment: String, CaseIterable {
        case mismatches = "Open Mismatches"
        case auditLog   = "Audit History"
    }
    @State private var segment: ReconcileSegment = .mismatches

    // Reconciliation sheet
    @State private var selectedItem: DiscrepancyItem? = nil

    // Audit expansion
    @State private var isAuditExpanded = false

    private let kpiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            RSMSTheme.background
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    segmentPicker

                    if segment == .mismatches {
                        if showSearchField { searchSection }
                        analyticsSection
                        discrepancySection
                    } else {
                        auditLogSection
                    }
                }
                .padding(24)
                .padding(.bottom, 80)
            }

            // Success Modal Overlay
            if viewModel.showSuccessModal {
                successOverlay
            }
        }
        .navigationTitle("Audit & Reconcile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
            if segment == .mismatches {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showSearchField.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(RSMSTheme.gold)
                    }

                    Menu {
                        Button("All") { viewModel.filterStatus = nil }
                        ForEach(ReconciliationStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) { viewModel.filterStatus = status }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(RSMSTheme.gold)
                    }
                }
            }
            }
        }
        .sheet(item: $selectedItem) { item in
            reconcileSheet(for: item)
        }
        .sheet(isPresented: $showShrinkageAnalysis) {
            ShrinkageAnalysisView(
                shrinkagePercentage: viewModel.shrinkagePercentage,
                shrinkageValue: viewModel.shrinkageValue,
                totalInventoryValue: viewModel.totalStoreInventoryValue,
                highRiskItems: viewModel.discrepancyItems.filter { $0.actualQty < $0.expectedQty },
                shrinkageRecord: viewModel.shrinkageRecord
            )
        }
        .task {
            if let storeId = appVM.currentStoreId {
                await viewModel.load(from: appVM.dataStore, storeId: storeId)
            }
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(ReconcileSegment.allCases, id: \.self) { seg in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { segment = seg }
                } label: {
                    Text(seg.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            segment == seg ? RSMSTheme.background : RSMSTheme.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            segment == seg
                                ? RSMSTheme.textPrimary
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(RSMSTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Audit & Reconcile")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Resolve inventory discrepancies and review audit trail")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    // MARK: - Search

    private var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(RSMSTheme.textTertiary)
            TextField("Search products, SKUs…", text: $viewModel.searchText)
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(RSMSTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Analytics Section

    private var analyticsSection: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: kpiColumns, spacing: 14) {
                KPICard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(viewModel.totalDiscrepancies)",
                    label: "Total Discrepancies",
                    iconColor: RSMSTheme.gold
                )
                KPICard(
                    icon: "clock.fill",
                    value: "\(viewModel.pendingVerification)",
                    label: "Pending Verification",
                    iconColor: RSMSTheme.warning
                )
                KPICard(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.resolvedToday)",
                    label: "Resolved Today",
                    iconColor: RSMSTheme.success
                )
                KPICard(
                    icon: "doc.text.fill",
                    value: "\(viewModel.auditLogsUpdated)",
                    label: "Audit Logs Updated",
                    iconColor: RSMSTheme.info
                )
            }
            
            Button {
                showShrinkageAnalysis = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                    Text("View Shrinkage Analysis")
                }
                .font(.headline)
                .foregroundStyle(RSMSTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RSMSTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    // MARK: - Discrepancy Cards

    private var discrepancySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("DISCREPANCIES")
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(RSMSTheme.gold)
            }

            ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                discrepancyCard(item)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08), value: appeared)
            }
        }
    }

    private func discrepancyCard(_ item: DiscrepancyItem) -> some View {
        VStack(spacing: 0) {
            // Top: Product info
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RSMSTheme.surfaceSecondary.opacity(0.3))
                        .frame(width: 56, height: 56)
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundStyle(RSMSTheme.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                    Text("SKU: \(item.product.sku)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("Updated \(timeAgo(item.lastUpdated))")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary.opacity(0.7))
                }

                Spacer(minLength: 0)
                StatusBadge(text: item.status.rawValue, color: item.status.color)
            }
            .padding(18)

            // Quantity comparison
            HStack(spacing: 8) {
                quantityBlock(label: "EXPECTED", value: "\(item.expectedQty)", color: RSMSTheme.textSecondary)
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                quantityBlock(
                    label: "ACTUAL",
                    value: "\(item.actualQty)",
                    color: item.status == .resolved ? RSMSTheme.success : RSMSTheme.danger
                )
                Image(systemName: "minus.circle.fill")
                    .font(.caption)
                    .foregroundStyle(item.variance == 0 ? RSMSTheme.success : RSMSTheme.danger)
                quantityBlock(
                    label: "VARIANCE",
                    value: "\(item.variance)",
                    color: item.variance == 0 ? RSMSTheme.success : RSMSTheme.danger
                )
            }
            .padding(.horizontal, 18)

            // CTA Button
            Button {
                if item.status != .resolved {
                    viewModel.resetReconcileForm()
                    selectedItem = item
                }
            } label: {
                HStack(spacing: 6) {
                    if item.status == .resolved {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Reconciled")
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Reconcile Stock")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(item.status == .resolved ? RSMSTheme.success : RSMSTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    item.status == .resolved
                        ? RSMSTheme.success.opacity(0.12)
                        : RSMSTheme.gold
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(item.status == .resolved)
            .padding(18)
            .padding(.top, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(RSMSTheme.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            item.status == .resolved
                                ? RSMSTheme.success.opacity(0.25)
                                : RSMSTheme.border,
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private func quantityBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RSMSTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Audit Log Section

    private var auditLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AUDIT HISTORY")
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(RSMSTheme.gold)

            VStack(spacing: 0) {
                // Toggle header
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        isAuditExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(RSMSTheme.gold.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(RSMSTheme.gold)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reconciliation Timeline")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("\(viewModel.auditEntries.count) recent entries")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .rotationEffect(.degrees(isAuditExpanded ? 180 : 0))
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)

                // Expandable entries
                if isAuditExpanded {
                    ForEach(viewModel.auditEntries) { entry in
                        auditEntryRow(entry)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(RSMSTheme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
        .opacity(appeared ? 1 : 0)
    }

    private func auditEntryRow(_ entry: ReconciliationAuditEntry) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(RSMSTheme.divider)
                .frame(height: 0.5)
                .padding(.horizontal, 14)

            HStack(alignment: .top, spacing: 12) {
                // Timeline dot
                VStack(spacing: 4) {
                    Circle()
                        .fill(RSMSTheme.gold)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(RSMSTheme.divider)
                        .frame(width: 2)
                }
                .frame(width: 10)
                .padding(.top, 4)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.userName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        Text(formatTimestamp(entry.timestamp))
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reconciled **\(entry.productName)**")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)

                        Text("Reason: \(entry.reason.rawValue)")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)

                        HStack(spacing: 6) {
                            Text("\(entry.previousQty)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.danger)
                                .strikethrough()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9))
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text("\(entry.updatedQty)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.success)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }


    // MARK: - Reconciliation Bottom Sheet

    private func reconcileSheet(for item: DiscrepancyItem) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product summary
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(RSMSTheme.surfaceSecondary.opacity(0.3))
                                .frame(width: 48, height: 48)
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundStyle(RSMSTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.product.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("SKU: \(item.product.sku)")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Qty summary
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text("EXPECTED")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text("\(item.expectedQty)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RSMSTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(spacing: 4) {
                            Text("CURRENT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text("\(item.actualQty)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(RSMSTheme.danger)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RSMSTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Form fields
                    LuxuryTextField(title: "Corrected Quantity", text: $viewModel.correctedQty)
                        .keyboardType(.numberPad)

                    LuxuryPicker(
                        title: "Adjustment Reason",
                        selection: Binding(
                            get: { viewModel.selectedReason?.rawValue ?? "" },
                            set: { newVal in
                                viewModel.selectedReason = AdjustmentReason.allCases.first { $0.rawValue == newVal }
                            }
                        ),
                        options: AdjustmentReason.allCases.map(\.rawValue)
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        TextEditor(text: $viewModel.adjustmentNotes)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80)
                            .padding(12)
                            .background(RSMSTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(RSMSTheme.border, lineWidth: 1)
                            )
                    }

                    // CTA
                    Button {
                        viewModel.reconcile(
                            item: item,
                            currentUser: appVM.currentUser,
                            dataStore: appVM.dataStore
                        )
                        selectedItem = nil
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                            Text("Verify & Reconcile")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.correctedQty.isEmpty || viewModel.selectedReason == nil)
                    .opacity(viewModel.correctedQty.isEmpty || viewModel.selectedReason == nil ? 0.5 : 1)
                }
                .padding(24)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("RECONCILE STOCK")
                        .font(.system(.headline, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { selectedItem = nil }
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
        }
    }

    // MARK: - Success Modal

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.spring()) {
                        viewModel.showSuccessModal = false
                    }
                }

            VStack(spacing: 20) {
                // Success checkmark
                ZStack {
                    Circle()
                        .fill(RSMSTheme.success.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(RSMSTheme.success)
                        .symbolEffect(.bounce, value: viewModel.showSuccessModal)
                }

                VStack(spacing: 8) {
                    Text("Stock Reconciled Successfully")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Inventory records and audit logs updated.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Qty change display
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("PREVIOUS")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text("\(viewModel.reconciledOldQty)")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(RSMSTheme.danger)
                            .strikethrough()
                    }

                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textTertiary)

                    VStack(spacing: 4) {
                        Text("UPDATED")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text("\(viewModel.reconciledNewQty)")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(RSMSTheme.success)
                    }
                }
                .padding(16)
                .background(RSMSTheme.surfaceSecondary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Timestamp
                Text(viewModel.reconciledTimestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)

                // Close
                Button {
                    withAnimation(.spring()) {
                        viewModel.showSuccessModal = false
                    }
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(RSMSTheme.success)
                        )
                }
                .padding(.top, 4)
            }
            .padding(32)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .background(RSMSTheme.background.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private func timeAgo(_ date: Date) -> String {
        let mins = Int(-date.timeIntervalSinceNow / 60)
        if mins < 1 { return "just now" }
        if mins < 60 { return "\(mins)m ago" }
        let hours = mins / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }

    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, \(date.formatted(date: .omitted, time: .shortened))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StockReconciliationView()
    }
}
