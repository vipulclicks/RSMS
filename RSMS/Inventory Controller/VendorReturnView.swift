//
//  VendorReturnView.swift
//  RSMS
//
//  Premium Vendor Returns screen for the Inventory Controller module.
//  Manages vendor return requests for defective, damaged, incorrect,
//  excess, and expired inventory items.
//  Follows the luxury beige-maroon RSMSTheme design language.
//

import SwiftUI

struct VendorReturnView: View {

    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var vm = VendorReturnViewModel()
    @State private var appeared = false
    @State private var showRecentFeed = true
    @State private var selectedStatusFilter: VendorReturnStatus? = nil

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            if vm.isLoading && vm.movements.isEmpty {
                loadingView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        headerSection
                        pipelineSection
                        actionSection
                        returnsListSection
                    }
                    .padding(24)
                    .padding(.bottom, 24)
                }
            }

            // Success overlay
            if vm.showSuccess {
                successOverlay
            }
        }
        .navigationTitle("Vendor Returns")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.resetForm()
                    vm.showCreateSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "shippingbox.and.arrow.backward.fill")
                        Text("New Return")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.gold)
                    .clipShape(Capsule())
                }
            }
        }
        .sheet(isPresented: $vm.showCreateSheet) {
            createReturnSheet
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
            Text("Loading vendor returns…")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Vendor Returns")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Manage outgoing inventory pipeline and supplier reconciliation.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Pipeline Section (New UI Approach)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var pipelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RETURN PIPELINE")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.gold)

            HStack(spacing: 0) {
                pipelineNode(
                    title: "Pending",
                    count: vm.pendingCount,
                    status: .pending,
                    color: RSMSTheme.warning,
                    isFirst: true
                )
                pipelineDivider()
                pipelineNode(
                    title: "Approved",
                    count: vm.approvedCount,
                    status: .approved,
                    color: RSMSTheme.info
                )
                pipelineDivider()
                pipelineNode(
                    title: "Completed",
                    count: vm.completedCount,
                    status: .completed,
                    color: RSMSTheme.success,
                    isLast: true
                )
            }
            .padding(24)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }

    private func pipelineNode(title: String, count: Int, status: VendorReturnStatus, color: Color, isFirst: Bool = false, isLast: Bool = false) -> some View {
        Button {
            withAnimation(.spring()) {
                if selectedStatusFilter == status {
                    selectedStatusFilter = nil
                } else {
                    selectedStatusFilter = status
                }
            }
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            selectedStatusFilter == status ? color : color.opacity(0.3),
                            lineWidth: selectedStatusFilter == status ? 3 : 1
                        )
                        .background(
                            Circle().fill(selectedStatusFilter == status ? color.opacity(0.1) : RSMSTheme.background)
                        )
                        .frame(width: 60, height: 60)
                    
                    Text("\(count)")
                        .font(.title2.bold())
                        .foregroundStyle(selectedStatusFilter == status ? color : RSMSTheme.textPrimary)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if status == .pending && count > 0 {
                        Text("Requires Action")
                            .font(.system(size: 9))
                            .foregroundStyle(RSMSTheme.warning)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(selectedStatusFilter == status ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func pipelineDivider() -> some View {
        Rectangle()
            .fill(RSMSTheme.divider)
            .frame(height: 2)
            .padding(.horizontal, 4)
            .offset(y: -20)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Action Section
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var actionSection: some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Activity")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("\(vm.todayReturns) returns initiated today")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    
                    Button {
                        vm.resetForm()
                        vm.showCreateSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Initiate Return")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RSMSTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Activity")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("\(vm.todayReturns) returns initiated today")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        vm.resetForm()
                        vm.showCreateSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Initiate Return")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RSMSTheme.background)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(RSMSTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.gold.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.gold.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
        )
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Returns List Section
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var filteredReturns: [InventoryMovement] {
        if let filter = selectedStatusFilter {
            return vm.recentReturns.filter { VendorReturnStatus.from($0.status) == filter }
        }
        return vm.recentReturns
    }

    private var returnsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(selectedStatusFilter == nil ? "ALL RETURNS" : "\(selectedStatusFilter!.rawValue.uppercased()) RETURNS")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.textTertiary)
                
                Spacer()
                
                if selectedStatusFilter != nil {
                    Button {
                        withAnimation { selectedStatusFilter = nil }
                    } label: {
                        Text("Clear Filter")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RSMSTheme.info)
                    }
                }
            }

            if filteredReturns.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(RSMSTheme.textTertiary.opacity(0.5))
                    Text("No returns found")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredReturns) { ret in
                        returnListItem(ret)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
    }

    private func returnListItem(_ ret: InventoryMovement) -> some View {
        let status = VendorReturnStatus.from(ret.status)
        
        return HStack(spacing: 16) {
            // Status Indicator Line
            Rectangle()
                .fill(status.color)
                .frame(width: 4)
                .clipShape(Capsule())
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.vendorName(for: ret))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        Text(vm.returnReason(for: ret))
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(status.rawValue)
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .foregroundStyle(status.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.color.opacity(0.1))
                            .clipShape(Capsule())
                        
                        if let date = ret.requestedAt {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox")
                        Text("\(ret.itemsExpected ?? 0) units")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    
                    if let asn = ret.asnNumber {
                        Text("•")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                            Text("PO: \(asn)")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        // Action menu
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .padding(8)
                            .background(RSMSTheme.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Create Return Sheet (Redesigned)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var createReturnSheet: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                RSMSTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header info
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Return ID")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Text(vm.returnId)
                                    .font(.subheadline.weight(.bold).monospaced())
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Text(Date().formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Section 1: Supplier Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("1. Supplier Details")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.gold)
                            
                            VStack(spacing: 0) {
                                Menu {
                                    ForEach(vm.vendors) { vendor in
                                        Button(vendor.name) {
                                            vm.selectedVendor = vendor
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(vm.selectedVendor?.name ?? "Select Supplier")
                                            .foregroundStyle(vm.selectedVendor != nil ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                    }
                                    .padding()
                                    .background(RSMSTheme.surfacePrimary)
                                }
                                
                                Divider().padding(.leading)
                                
                                TextField("Purchase Order Reference (Required)", text: $vm.purchaseOrderNumber)
                                    .padding()
                                    .background(RSMSTheme.surfacePrimary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                        }
                        
                        // Section 2: Items
                        VStack(alignment: .leading, spacing: 16) {
                            Text("2. Return Items")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.gold)
                            
                            // Product Search
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "magnifyingglass").foregroundStyle(RSMSTheme.textTertiary)
                                    TextField("Search product by SKU or name...", text: $vm.productSearchText)
                                }
                                .padding()
                                .background(RSMSTheme.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                                
                                if !vm.searchResults.isEmpty && vm.selectedProduct == nil {
                                    VStack(spacing: 0) {
                                        ForEach(vm.searchResults) { product in
                                            Button {
                                                withAnimation {
                                                    vm.selectedProduct = product
                                                    vm.productSearchText = ""
                                                }
                                            } label: {
                                                HStack {
                                                    Text(product.name)
                                                        .foregroundStyle(RSMSTheme.textPrimary)
                                                    Spacer()
                                                    Text(product.sku)
                                                        .font(.caption.monospaced())
                                                        .foregroundStyle(RSMSTheme.textTertiary)
                                                }
                                                .padding()
                                            }
                                            if product.id != vm.searchResults.last?.id { Divider() }
                                        }
                                    }
                                    .background(RSMSTheme.surfacePrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                                }
                                
                                // Selected Product configuration
                                if let p = vm.selectedProduct {
                                    VStack(spacing: 16) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(p.name).font(.headline).foregroundStyle(RSMSTheme.textPrimary)
                                                Text(p.sku).font(.caption.monospaced()).foregroundStyle(RSMSTheme.textSecondary)
                                            }
                                            Spacer()
                                            Button { vm.selectedProduct = nil } label: {
                                                Image(systemName: "xmark.circle.fill").foregroundStyle(RSMSTheme.textTertiary)
                                            }
                                        }
                                        
                                        HStack {
                                            Text("Quantity").foregroundStyle(RSMSTheme.textSecondary)
                                            Spacer()
                                            Stepper("\(vm.quantity)", value: $vm.quantity, in: 1...vm.availableStock)
                                                .fixedSize()
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Reason").foregroundStyle(RSMSTheme.textSecondary)
                                            Picker("Reason", selection: $vm.selectedReason) {
                                                ForEach(ReturnReason.allCases) { reason in
                                                    Text(reason.rawValue).tag(reason)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                        }
                                        
                                        Button {
                                            withAnimation(.spring()) {
                                                if let index = vm.returnCart.firstIndex(where: { $0.product.id == p.id }) {
                                                    vm.returnCart[index].quantity += vm.quantity
                                                } else {
                                                    vm.returnCart.append(ReturnItem(product: p, quantity: vm.quantity, reason: vm.selectedReason))
                                                }
                                                vm.selectedProduct = nil
                                                vm.quantity = 1
                                            }
                                        } label: {
                                            Text("Add to Cart")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(RSMSTheme.gold.opacity(0.1))
                                                .foregroundStyle(RSMSTheme.gold)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                    .padding()
                                    .background(RSMSTheme.surfaceSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            
                            // Cart Preview
                            if !vm.returnCart.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(vm.returnCart) { item in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(item.product.name).font(.subheadline.weight(.semibold))
                                                Text(item.reason.rawValue).font(.caption).foregroundStyle(item.reason.color)
                                            }
                                            Spacer()
                                            Text("\(item.quantity)").font(.headline)
                                            Button {
                                                withAnimation { vm.returnCart.removeAll { $0.id == item.id } }
                                            } label: {
                                                Image(systemName: "minus.circle.fill").foregroundStyle(RSMSTheme.danger).padding(.leading, 8)
                                            }
                                        }
                                        .padding()
                                        if item.id != vm.returnCart.last?.id { Divider() }
                                    }
                                }
                                .background(RSMSTheme.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                            }
                        }
                        
                        // Section 3: Logistics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("3. Logistics & Notes")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.gold)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Return Method").foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Picker("Method", selection: $vm.returnMethod) {
                                        Text("Vendor Pickup").tag("Vendor Pickup")
                                        Text("Courier").tag("Courier")
                                        Text("Self Drop-off").tag("Self Drop-off")
                                    }
                                    .tint(RSMSTheme.gold)
                                }
                                .padding()
                                
                                Divider().padding(.leading)
                                
                                DatePicker("Expected Date", selection: $vm.expectedPickupDate, displayedComponents: .date)
                                    .padding()
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .tint(RSMSTheme.gold)
                                
                                Divider().padding(.leading)
                                
                                VStack(alignment: .leading) {
                                    Text("Remarks")
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .padding(.horizontal)
                                        .padding(.top)
                                    TextEditor(text: $vm.returnNotes)
                                        .frame(height: 80)
                                        .padding(.horizontal)
                                        .scrollContentBackground(.hidden)
                                }
                            }
                            .background(RSMSTheme.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                        }
                        
                        // Bottom Padding for submit button
                        Spacer().frame(height: 100)
                    }
                    .padding(24)
                }
                
                // Sticky Submit Button
                VStack {
                    Divider()
                    Button {
                        Task {
                            await vm.submitReturn(
                                dataStore: appVM.dataStore,
                                requestedBy: appVM.currentUser?.id,
                                storeId: appVM.currentStoreId
                            )
                        }
                    } label: {
                        HStack {
                            if vm.isSubmitting {
                                ProgressView().tint(RSMSTheme.background)
                            } else {
                                Text("Submit Return")
                                    .font(.headline.weight(.bold))
                            }
                        }
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vm.isSubmitting || vm.selectedVendor == nil || vm.returnCart.isEmpty || vm.purchaseOrderNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((vm.selectedVendor == nil || vm.returnCart.isEmpty || vm.purchaseOrderNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(RSMSTheme.background.opacity(0.95))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("INITIATE RETURN")
                        .font(.system(.headline, design: .serif, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { vm.showCreateSheet = false }
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Success Overlay
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.spring()) { vm.showSuccess = false }
                }

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.success.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(RSMSTheme.success)
                }

                VStack(spacing: 8) {
                    Text("Return Initiated")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Return ID: \(vm.returnId)")
                        .font(.subheadline.monospaced())
                        .foregroundStyle(RSMSTheme.textSecondary)
                }

                Button {
                    withAnimation(.spring()) { vm.showSuccess = false }
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(32)
            .frame(width: 320)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VendorReturnView()
    }
    .environment(AppViewModel())
}
