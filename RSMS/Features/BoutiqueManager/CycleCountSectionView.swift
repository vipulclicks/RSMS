import SwiftUI

struct CycleCountSectionView: View {
    @Bindable var cycleCountVM: CycleCountViewModel
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var showCheckedItems = false
    @State private var showDiscrepancySheet = false
    @State private var showInventorySheet = false
    @State private var showPendingSheet = false
    @State private var showMismatchesSheet = false
    @State private var selectedProductToView: Product? = nil

    private var columns: [GridItem] {
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
            }

            // KPI Cards Row
            cycleCountKPIRow

            // Verified / Checked toggle
            if !cycleCountVM.checkedItems.isEmpty {
                cycleCountCheckedSection
            }
        }
        .sheet(item: $cycleCountVM.itemToCount) { item in
            cycleCountSheet(for: item)
        }
        .sheet(isPresented: $showMismatchesSheet) {
            mismatchesListSheet
        }
        .sheet(isPresented: $showInventorySheet) {
            inventoryListSheet
        }
        .sheet(isPresented: $showPendingSheet) {
            pendingChecksSheet
        }
        .fullScreenCover(item: $selectedProductToView) { product in
            ProductDetailSheet(
                product: product,
                stockItem: stockItem(for: product)
            )
        }
    }

    // MARK: Cycle Count KPI Row
    private var cycleCountKPIRow: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            // Total Inventory — tappable
            Button {
                showInventorySheet = true
            } label: {
                tappableKPICard(
                    icon: "shippingbox.fill",
                    value: "\(cycleCountVM.totalInventory)",
                    label: "Total Inventory",
                    color: RSMSTheme.gold
                )
            }
            .buttonStyle(.plain)
            
            // Pending Checks — tappable
            Button {
                showPendingSheet = true
            } label: {
                tappableKPICard(
                    icon: "clock.badge.exclamationmark.fill",
                    value: "\(cycleCountVM.pendingItems.count)",
                    label: "Pending Checks",
                    color: RSMSTheme.warning
                )
            }
            .buttonStyle(.plain)
            
            // Mismatches — tappable
            Button {
                showMismatchesSheet = true
            } label: {
                tappableKPICard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(cycleCountVM.openMismatches)",
                    label: "Mismatches",
                    color: cycleCountVM.openMismatches > 0 ? RSMSTheme.danger : RSMSTheme.success
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tappable KPI Card
    private func tappableKPICard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Spacer(minLength: 0)
            
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 128)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(RSMSTheme.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 6)
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
            HStack {
                Text("Verified this period")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(cycleCountVM.checkedItems.count) items")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            VStack(spacing: 0) {
                let limit = showCheckedItems ? cycleCountVM.checkedItems.count : 2
                let visibleItems = Array(cycleCountVM.checkedItems.prefix(limit).enumerated())

                ForEach(visibleItems, id: \.element.id) { index, item in
                    Button {
                        selectedProductToView = item.product
                    } label: {
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
                    }
                    .buttonStyle(.plain)

                    // Divider after every item except the last one (if not showing 'View more' button)
                    if index < visibleItems.count - 1 || (!showCheckedItems && cycleCountVM.checkedItems.count > 2) {
                        Rectangle()
                            .fill(RSMSTheme.divider)
                            .frame(height: 0.5)
                            .padding(.horizontal, 16)
                    }
                }

                if !showCheckedItems && cycleCountVM.checkedItems.count > 2 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showCheckedItems = true
                        }
                    } label: {
                        Text("View all")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.gold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                } else if showCheckedItems && cycleCountVM.checkedItems.count > 2 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showCheckedItems = false
                        }
                    } label: {
                        Text("Show less")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
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

                    // Serial Code Entry
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SERIAL CODE")
                            .font(.caption.weight(.semibold))
                            .tracking(1.5)
                            .foregroundStyle(RSMSTheme.gold)
                        
                        HStack(spacing: 10) {
                            Image(systemName: "number")
                                .font(.body.weight(.medium))
                                .foregroundStyle(RSMSTheme.textTertiary)
                            TextField("Enter serial or barcode number", text: $cycleCountVM.serialCode)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                        }
                        .padding(14)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSTheme.border, lineWidth: 1)
                        )
                    }

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
            .navigationTitle("Enter Count")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { cycleCountVM.itemToCount = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - Total Inventory Sheet
    // ═══════════════════════════════════════════════════════════
    
    private var inventoryListSheet: some View {
        NavigationStack {
            let allItems = cycleCountVM.pendingItems + cycleCountVM.checkedItems
            
            Group {
                if allItems.isEmpty {
                    ContentUnavailableView(
                        "No Inventory",
                        systemImage: "shippingbox",
                        description: Text("No stock items found for this store.")
                    )
                } else {
                    List {
                        ForEach(allItems) { item in
                            Button {
                                selectedProductToView = item.product
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(RSMSTheme.gold.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "shippingbox.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(RSMSTheme.gold)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.product.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                            .lineLimit(1)
                                        Text(item.product.sku)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text("\(item.expectedQty)")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Text("units")
                                            .font(.caption2)
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                        .padding(.leading, 4)
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(RSMSTheme.surfacePrimary)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Total Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { showInventorySheet = false }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .fullScreenCover(item: $selectedProductToView) { product in
            ProductDetailSheet(
                product: product,
                stockItem: stockItem(for: product)
            )
        }
    }

    private func stockItem(for product: Product) -> StockItem? {
        appVM.dataStore.stockItems.first {
            $0.productId == product.id && $0.storeId == appVM.currentStoreId
        }
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - Pending Checks Sheet
    // ═══════════════════════════════════════════════════════════
    
    private var pendingChecksSheet: some View {
        NavigationStack {
            Group {
                if cycleCountVM.pendingItems.isEmpty {
                    ContentUnavailableView(
                        "All Clear",
                        systemImage: "checkmark.seal.fill",
                        description: Text("No pending verification items.")
                    )
                } else {
                    List {
                        ForEach(cycleCountVM.pendingItems) { item in
                            Button {
                                showPendingSheet = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    cycleCountVM.enteredCount = "\(item.expectedQty)"
                                    cycleCountVM.itemToCount = item
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(RSMSTheme.warning.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "clock.badge.exclamationmark.fill")
                                            .font(.system(size: 15))
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
                                            Text("Qty: \(item.expectedQty)")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.textTertiary)
                                        }
                                        if let last = item.lastChecked {
                                            Text("Last: \(last.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption2)
                                                .foregroundStyle(RSMSTheme.warning.opacity(0.8))
                                        } else {
                                            Text("Never verified")
                                                .font(.caption2)
                                                .foregroundStyle(RSMSTheme.danger.opacity(0.8))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                            }
                            .listRowBackground(RSMSTheme.surfacePrimary)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Pending Checks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { showPendingSheet = false }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - Mismatches List Sheet
    // ═══════════════════════════════════════════════════════════
    
    private var mismatchesListSheet: some View {
        NavigationStack {
            Group {
                if cycleCountVM.openVarianceItems.isEmpty {
                    ContentUnavailableView(
                        "No Mismatches",
                        systemImage: "checkmark.circle.fill",
                        description: Text("All stock levels match the system records.")
                    )
                } else {
                    List {
                        ForEach(cycleCountVM.openVarianceItems) { variance in
                            Button {
                                if let product = appVM.dataStore.products.first(where: { $0.id == variance.productId }) {
                                    selectedProductToView = product
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(RSMSTheme.danger.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(RSMSTheme.danger)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        if let product = appVM.dataStore.products.first(where: { $0.id == variance.productId }) {
                                            Text(product.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(RSMSTheme.textPrimary)
                                                .lineLimit(1)
                                            HStack(spacing: 6) {
                                                Text(product.sku)
                                                    .font(.caption.monospaced())
                                                    .foregroundStyle(RSMSTheme.textTertiary)
                                            }
                                        } else {
                                            Text("Unknown Product")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(RSMSTheme.textPrimary)
                                        }
                                        
                                        Text("Reported: \(variance.reportedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption2)
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 3) {
                                        let diff = variance.actualQty - variance.expectedQty
                                        let isExcess = diff > 0
                                        Text("\(isExcess ? "+" : "")\(diff)")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(isExcess ? RSMSTheme.warning : RSMSTheme.danger)
                                        
                                        Text("Variance")
                                            .font(.caption2)
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                        .padding(.leading, 4)
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(RSMSTheme.surfacePrimary)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Mismatches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { showMismatchesSheet = false }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .fullScreenCover(item: $selectedProductToView) { product in
            ProductDetailSheet(
                product: product,
                stockItem: stockItem(for: product)
            )
        }
    }
}
