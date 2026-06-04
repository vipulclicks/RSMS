//
//  CycleCountView.swift
//  RSMS
//
//  Cycle Counts screen — shows KPI header (Total Inventory / Pending Checks / Mismatches)
//  and a live list of products needing a physical count.
//  Tap any row to open a count sheet and submit the actual quantity.
//

import SwiftUI

struct CycleCountView: View {

    @Environment(AppViewModel.self) private var appVM
    @State private var vm = CycleCountViewModel()
    @State private var appeared = false
    @State private var showChecked = false
    @State private var showScanner = false

    private let kpiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            if vm.isLoading {
                loadingView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        
                        Button {
                            showScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Scan to Verify")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RSMSTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        kpiSection
                        pendingSection
                        checkedSection
                    }
                    .padding(24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Cycle Counts")
        .navigationBarTitleDisplayMode(.inline)

        .fullScreenCover(isPresented: $showScanner) {
            NavigationStack {
                InventoryBarcodeScannerView(initialMode: .verification)
                    .navigationTitle("Verify Inventory")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showScanner = false }
                                .foregroundStyle(RSMSTheme.gold)
                        }
                    }
            }
            .environment(appVM)
        }
        .sheet(item: $vm.itemToCount) { item in
            countSheet(for: item)
        }
        .task {
            await vm.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
        .refreshable {
            await vm.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(RSMSTheme.gold)
                .scaleEffect(1.3)
            Text("Loading inventory…")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Cycle Counts")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Physical verification of stock levels")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    // MARK: - KPI Cards

    private var kpiSection: some View {
        LazyVGrid(columns: kpiColumns, spacing: 12) {
            kpiCard(
                icon: "shippingbox.fill",
                value: "\(vm.totalInventory)",
                label: "Total Inventory",
                sublabel: "units across all SKUs",
                color: RSMSTheme.gold
            )
            kpiCard(
                icon: "clock.badge.exclamationmark.fill",
                value: "\(vm.pendingItems.count)",
                label: "Pending Checks",
                sublabel: "not verified in 30 days",
                color: RSMSTheme.warning
            )
            kpiCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(vm.openMismatches)",
                label: "Mismatches",
                sublabel: "open variances",
                color: vm.openMismatches > 0 ? RSMSTheme.danger : RSMSTheme.success
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    private func kpiCard(icon: String, value: String, label: String, sublabel: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(sublabel)
                .font(.system(size: 10))
                .foregroundStyle(RSMSTheme.textTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Pending List

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PENDING CHECKS")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                if vm.pendingItems.isEmpty {
                    Text("All clear ✓")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.success)
                } else {
                    Text("\(vm.pendingItems.count) items")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }

            if vm.pendingItems.isEmpty {
                allClearView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.pendingItems.enumerated()), id: \.element.id) { index, item in
                        Button {
                            vm.enteredCount = "\(item.expectedQty)"
                            vm.itemToCount = item
                        } label: {
                            pendingRow(item)
                        }
                        .buttonStyle(.plain)

                        if index < vm.pendingItems.count - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.warning.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }

    private func pendingRow(_ item: CycleCountItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.warning.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(RSMSTheme.warning)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.product.sku)
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("·")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("Expected: \(item.expectedQty)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                if let last = item.lastChecked {
                    Text("Last checked \(last.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.warning.opacity(0.8))
                } else {
                    Text("Never verified")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.danger.opacity(0.8))
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.gold.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var allClearView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(RSMSTheme.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("All products verified")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("No cycle counts overdue")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.success.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Checked / Completed

    private var checkedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showChecked.toggle()
                }
            } label: {
                HStack {
                    Text("VERIFIED THIS PERIOD")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(RSMSTheme.gold)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(vm.checkedItems.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.success)
                        Image(systemName: showChecked ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)

            if showChecked && !vm.checkedItems.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(vm.checkedItems.prefix(20).enumerated()), id: \.element.id) { index, item in
                        checkedRow(item)
                        if index < min(vm.checkedItems.count, 20) - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.success.opacity(0.2), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func checkedRow(_ item: CycleCountItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.success.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(RSMSTheme.success)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.product.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                Text(item.product.sku)
                    .font(.caption.monospaced())
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            Spacer(minLength: 0)

            if let date = item.lastChecked {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.success.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Count Sheet

    private func countSheet(for item: CycleCountItem) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Product header
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(RSMSTheme.gold.opacity(0.12))
                                .frame(width: 64, height: 64)
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 28))
                                .foregroundStyle(RSMSTheme.gold)
                        }
                        Text(item.product.name)
                            .font(.headline.bold())
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(item.product.sku)
                            .font(.caption.monospaced())
                            .foregroundStyle(RSMSTheme.gold)
                    }
                    .padding(.top, 8)

                    // Expected vs entry
                    VStack(spacing: 0) {
                        HStack {
                            Text("System Qty")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Spacer()
                            Text("\(item.expectedQty) units")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        Rectangle().fill(RSMSTheme.divider).frame(height: 0.5).padding(.horizontal, 16)

                        HStack {
                            Text("Actual Count")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Spacer()
                            HStack(spacing: 12) {
                                Button(action: {
                                    if let val = Int(vm.enteredCount), val > 0 {
                                        vm.enteredCount = "\(val - 1)"
                                    } else if vm.enteredCount.isEmpty {
                                        vm.enteredCount = "0"
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                
                                TextField("0", text: $vm.enteredCount)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(.title3.bold())
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .frame(width: 50)
                                
                                Button(action: {
                                    let val = Int(vm.enteredCount) ?? 0
                                    vm.enteredCount = "\(val + 1)"
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))

                    // Variance preview
                    if let actual = Int(vm.enteredCount), actual != item.expectedQty {
                        let diff = actual - item.expectedQty
                        HStack(spacing: 8) {
                            Image(systemName: diff > 0 ? "plus.circle.fill" : "minus.circle.fill")
                                .foregroundStyle(diff > 0 ? RSMSTheme.success : RSMSTheme.danger)
                            Text("Variance of \(abs(diff)) will be logged as a mismatch")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(diff > 0 ? RSMSTheme.success : RSMSTheme.danger)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((diff > 0 ? RSMSTheme.success : RSMSTheme.danger).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Submit
                    Button {
                        guard let user = appVM.currentUser else { return }
                        Task {
                            await vm.submitCount(
                                for: item,
                                dataStore: appVM.dataStore,
                                user: user
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if vm.isSaving {
                                ProgressView().tint(RSMSTheme.background)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Submit Count")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RSMSTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vm.isSaving || vm.enteredCount.isEmpty || appVM.currentUser == nil)
                }
                .padding(20)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ENTER COUNT")
                        .font(.system(.caption, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { vm.itemToCount = nil }
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        CycleCountView()
    }
    .environment(AppViewModel())
}
