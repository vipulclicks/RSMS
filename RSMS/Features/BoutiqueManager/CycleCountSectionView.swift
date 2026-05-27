import SwiftUI

struct CycleCountSectionView: View {
    @Bindable var cycleCountVM: CycleCountViewModel
    @Environment(AppViewModel.self) private var appVM
    @State private var showCheckedItems = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cycle Counts")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Physical verification of stock levels")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()

                if cycleCountVM.openMismatches > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("\(cycleCountVM.openMismatches) Mismatch\(cycleCountVM.openMismatches == 1 ? "" : "es")")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(RSMSTheme.danger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(RSMSTheme.danger.opacity(0.1)))
                }
            }

            // KPI Cards Row
            cycleCountKPIRow

            // Pending Items
            if !cycleCountVM.pendingItems.isEmpty {
                cycleCountPendingList
            } else {
                cycleCountAllClear
            }

            // Verified / Checked toggle
            if !cycleCountVM.checkedItems.isEmpty {
                cycleCountCheckedSection
            }
        }
        .sheet(item: $cycleCountVM.itemToCount) { item in
            cycleCountSheet(for: item)
        }
    }

    // MARK: Cycle Count KPI Row
    private var cycleCountKPIRow: some View {
        let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]
        return LazyVGrid(columns: columns, spacing: 14) {
            cycleCountKPICard(
                icon: "shippingbox.fill",
                value: "\(cycleCountVM.totalInventory)",
                label: "Total Inventory",
                color: RSMSTheme.gold
            )
            cycleCountKPICard(
                icon: "clock.badge.exclamationmark.fill",
                value: "\(cycleCountVM.pendingItems.count)",
                label: "Pending Checks",
                color: RSMSTheme.warning
            )
            cycleCountKPICard(
                icon: "exclamationmark.triangle.fill",
                value: "\(cycleCountVM.openMismatches)",
                label: "Mismatches",
                color: cycleCountVM.openMismatches > 0 ? RSMSTheme.danger : RSMSTheme.success
            )
        }
    }

    private func cycleCountKPICard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: Cycle Count Pending List
    private var cycleCountPendingList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PENDING VERIFICATION")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(cycleCountVM.pendingItems.count) items")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(cycleCountVM.pendingItems.prefix(6).enumerated()), id: \.element.id) { index, item in
                    Button {
                        cycleCountVM.enteredCount = "\(item.expectedQty)"
                        cycleCountVM.itemToCount = item
                    } label: {
                        cycleCountPendingRow(item)
                    }
                    .buttonStyle(.plain)

                    if index < min(cycleCountVM.pendingItems.count, 6) - 1 {
                        Rectangle()
                            .fill(RSMSTheme.divider)
                            .frame(height: 0.5)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(RSMSTheme.surfacePrimary)
                    .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(RSMSTheme.warning.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func cycleCountPendingRow(_ item: CycleCountItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.warning.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 17))
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

    // MARK: Cycle Count All Clear
    private var cycleCountAllClear: some View {
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(RSMSTheme.success.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: Cycle Count Checked Section
    private var cycleCountCheckedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showCheckedItems.toggle()
                }
            } label: {
                HStack {
                    Text("VERIFIED THIS PERIOD")
                        .font(.caption.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(RSMSTheme.gold)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(cycleCountVM.checkedItems.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.success)
                        Image(systemName: showCheckedItems ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)

            if showCheckedItems {
                VStack(spacing: 0) {
                    ForEach(Array(cycleCountVM.checkedItems.prefix(10).enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(RSMSTheme.success.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 17))
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

                        if index < min(cycleCountVM.checkedItems.count, 10) - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(RSMSTheme.surfacePrimary)
                        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(RSMSTheme.success.opacity(0.2), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: Cycle Count Sheet
    private func cycleCountSheet(for item: CycleCountItem) -> some View {
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
                            TextField("0", text: $cycleCountVM.enteredCount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.title3.bold())
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))

                    // Variance preview
                    if let actual = Int(cycleCountVM.enteredCount), actual != item.expectedQty {
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
                            await cycleCountVM.submitCount(
                                for: item,
                                dataStore: appVM.dataStore,
                                user: user
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if cycleCountVM.isSaving {
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
                    .disabled(cycleCountVM.isSaving || cycleCountVM.enteredCount.isEmpty || appVM.currentUser == nil)
                }
                .padding(20)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ENTER COUNT")
                        .font(.system(.caption, design: .serif, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { cycleCountVM.itemToCount = nil }
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
