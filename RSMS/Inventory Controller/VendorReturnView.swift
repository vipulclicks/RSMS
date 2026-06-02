//
//  VendorReturnView.swift
//  RSMS
//
//  Main dashboard for Vendor Returns.
//  Follows the premium RSMSTheme design language.
//

import SwiftUI

struct VendorReturnView: View {

    @Environment(AppViewModel.self) private var appVM
    @State private var vm = VendorReturnViewModel()
    @State private var appeared = false
    @State private var navigateToDetail = false

    private let kpiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                if vm.isLoading && vm.movements.isEmpty {
                    loadingView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            headerSection
                            heroKPICard
                            miniCardsSection
                            createReturnButton
                            activeReturnsSection
                            recentReturnsSection
                        }
                        .padding(24)
                        .padding(.bottom, 24)
                    }
                }

                if vm.showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Vendor Returns")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToDetail) {
                if let returnMovement = vm.selectedReturn {
                    VendorReturnDetailView(vm: vm, movement: returnMovement)
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
    }

    // MARK: - Loading & Success

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

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(RSMSTheme.success)
            Text("Return Requested")
                .font(.title3.bold())
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 20)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vendor Returns")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Process returns for defective, damaged, or overstock items")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    // MARK: - Hero KPI Card

    private var heroKPICard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL RETURNS")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(RSMSTheme.gold)

                    Text("\(vm.totalReturns)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.gold)
                }

                Spacer()

                Image(systemName: "shippingbox.and.arrow.forward.fill")
                    .font(.title)
                    .foregroundStyle(RSMSTheme.gold.opacity(0.4))
                    .padding(12)
                    .background(RSMSTheme.gold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Rectangle()
                .fill(RSMSTheme.divider)
                .frame(height: 1)

            HStack(spacing: 0) {
                heroStatColumn(value: "\(vm.pendingCount)", label: "PENDING", color: RSMSTheme.warning)
                Spacer()
                heroStatColumn(value: "\(vm.shippedCount)", label: "SHIPPED", color: RSMSTheme.info)
                Spacer()
                heroStatColumn(value: "\(vm.completedCount)", label: "COMPLETED", color: RSMSTheme.success)
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.gold.opacity(0.2), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(0.05), value: appeared)
    }

    private func heroStatColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Mini KPI Cards

    private var miniCardsSection: some View {
        LazyVGrid(columns: kpiColumns, spacing: 12) {
            miniCard(
                icon: "exclamationmark.triangle.fill",
                title: "Defective",
                value: "\(vm.movements.filter { $0.notes?.contains("[DEFECTIVE]") == true }.count)",
                color: RSMSTheme.danger
            )
            miniCard(
                icon: "shield.check.fill",
                title: "Warranty",
                value: "Active", // Placeholder
                color: RSMSTheme.info
            )
            miniCard(
                icon: "shippingbox.fill",
                title: "Overstock",
                value: "\(vm.movements.filter { $0.notes?.contains("[OVERSTOCK]") == true }.count)",
                color: RSMSTheme.warning
            )
            miniCard(
                icon: "dollarsign.circle.fill",
                title: "Value",
                value: "€--",
                color: RSMSTheme.success
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    private func miniCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Create Button

    private var createReturnButton: some View {
        Button {
            vm.resetForm()
            vm.showCreateSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Create Vendor Return")
                    .font(.headline.weight(.bold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.background.opacity(0.6))
            }
            .foregroundStyle(RSMSTheme.background)
            .padding(18)
            .background(Color(hue: 0.8, saturation: 0.6, brightness: 0.6)) // Distinguish visually from Transfers (gold)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }

    // MARK: - Active Returns

    private var activeReturnsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVE RETURNS")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(vm.activeReturns.count) ongoing")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            if vm.activeReturns.isEmpty {
                emptyActiveView
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.activeReturns) { ret in
                        returnCard(ret)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func returnCard(_ ret: InventoryMovement) -> some View {
        Button {
            Task {
                await vm.loadReturnDetail(movement: ret, dataStore: appVM.dataStore)
                navigateToDetail = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(ret.reason ?? "Vendor Return")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)

                        Text("To: \(ret.destinationId)")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    Spacer()

                    statusBadge(ret.status)
                }

                Rectangle()
                    .fill(RSMSTheme.divider)
                    .frame(height: 0.5)

                HStack(spacing: 20) {
                    infoChip(
                        label: "REQUESTED",
                        value: ret.requestedAt?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                    )

                    infoChip(
                        label: "ITEMS",
                        value: "\(ret.itemsExpected ?? 0)"
                    )

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            .padding(18)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func infoChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .lineLimit(1)
        }
    }

    private var emptyActiveView: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.success.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(RSMSTheme.success)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("No active returns")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("All returns have been processed.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.success.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Recent Returns Feed

    private var recentReturnsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT RETURNS")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(vm.recentReturns.count) completed")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            if vm.recentReturns.isEmpty {
                emptyRecentView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.recentReturns.prefix(5).enumerated()), id: \.element.id) { index, ret in
                        recentFeedRow(ret)

                        if index < min(vm.recentReturns.count, 5) - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
    }

    private func recentFeedRow(_ ret: InventoryMovement) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.success.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RSMSTheme.success)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(ret.reason ?? "Vendor Return")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)

                HStack(spacing: 8) {
                    Text("\(ret.itemsExpected ?? 0) items")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    
                    if let date = ret.receivedAt {
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            Spacer(minLength: 0)
            statusBadge(ret.status)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var emptyRecentView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "arrow.uturn.backward")
                    .font(.title2)
                    .foregroundStyle(RSMSTheme.gold)
            }
            Text("No recent history")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Completed returns will appear here.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Create Return Sheet

    private var createReturnSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    formRow(label: "RETURN ID") {
                        HStack {
                            Text(vm.returnId)
                                .font(.subheadline.weight(.bold).monospaced())
                                .foregroundStyle(RSMSTheme.gold)
                            Spacer()
                            Image(systemName: "barcode.viewfinder")
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }

                    formRow(label: "VENDOR") {
                        Menu {
                            ForEach(vm.vendors, id: \.self) { vendor in
                                Button(vendor) {
                                    vm.selectedVendor = vendor
                                }
                            }
                        } label: {
                            HStack {
                                Text(vm.selectedVendor)
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                    }

                    formRow(label: "ADD PRODUCT") {
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                    TextField("Search by name or SKU…", text: $vm.productSearchText)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .font(.subheadline)
                                }

                                if let p = vm.selectedProduct {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(RSMSTheme.success)
                                        Text(p.name)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Text(p.sku)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(RSMSTheme.gold)
                                        Spacer()
                                        Button {
                                            vm.selectedProduct = nil
                                            vm.productSearchText = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(RSMSTheme.textTertiary)
                                        }
                                    }
                                    .padding(10)
                                    .background(RSMSTheme.success.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                if !vm.searchResults.isEmpty && vm.selectedProduct == nil {
                                    VStack(spacing: 0) {
                                        ForEach(vm.searchResults) { product in
                                            Button {
                                                vm.selectedProduct = product
                                                vm.productSearchText = ""
                                                vm.quantity = 1
                                            } label: {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(product.name).font(.subheadline.weight(.semibold)).foregroundStyle(RSMSTheme.textPrimary)
                                                        Text(product.sku).font(.caption.monospaced()).foregroundStyle(RSMSTheme.textTertiary)
                                                    }
                                                    Spacer()
                                                    let stock = vm.stockForProduct(product)
                                                    Text("\(stock) in stock").font(.caption.weight(.medium)).foregroundStyle(stock > 0 ? RSMSTheme.success : RSMSTheme.danger)
                                                }
                                                .padding(12)
                                                .background(Color.white.opacity(0.001))
                                            }
                                            .buttonStyle(.plain)
                                            Divider()
                                        }
                                    }
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
                                }
                            }

                            if vm.selectedProduct != nil {
                                Divider()

                                HStack(spacing: 16) {
                                    Text("Quantity")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Spacer()
                                    
                                    Button {
                                        if vm.quantity > 1 { vm.quantity -= 1 }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(vm.availableStock == 0 ? RSMSTheme.textTertiary.opacity(0.5) : RSMSTheme.textSecondary)
                                    }
                                    .disabled(vm.availableStock == 0)

                                    Text("\(vm.quantity)")
                                        .font(.title2.bold())
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .frame(minWidth: 40, alignment: .center)

                                    Button {
                                        if vm.quantity < vm.availableStock {
                                            vm.quantity += 1
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(vm.availableStock == 0 ? RSMSTheme.textTertiary.opacity(0.5) : RSMSTheme.textSecondary)
                                    }
                                    .disabled(vm.availableStock == 0)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "shippingbox.fill")
                                        .font(.caption2)
                                    Text("\(vm.availableStock) available")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(vm.availableStock == 0 ? RSMSTheme.danger : RSMSTheme.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                
                                // Return Reason Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Reason")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Picker("Reason", selection: $vm.returnReasonType) {
                                        ForEach(ReturnReason.allCases) { reason in
                                            Text(reason.rawValue).tag(reason)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                Button {
                                    if let p = vm.selectedProduct, vm.quantity > 0, vm.quantity <= vm.availableStock {
                                        vm.returnCart.append(ReturnCartItem(product: p, quantity: vm.quantity, reason: vm.returnReasonType))
                                        vm.selectedProduct = nil
                                        vm.productSearchText = ""
                                        vm.quantity = 1
                                    }
                                } label: {
                                    Text("Add to Return")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(vm.availableStock > 0 ? RSMSTheme.gold : RSMSTheme.textTertiary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .disabled(vm.availableStock == 0)
                            }
                        }
                    }

                    if !vm.returnCart.isEmpty {
                        formRow(label: "ITEMS TO RETURN") {
                            VStack(spacing: 0) {
                                ForEach(Array(vm.returnCart.enumerated()), id: \.element.id) { index, item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.product.name).font(.subheadline.weight(.semibold)).foregroundStyle(RSMSTheme.textPrimary)
                                            Text("\(item.reason.rawValue) · \(item.quantity) units")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.textTertiary)
                                        }
                                        Spacer()
                                        Button {
                                            vm.returnCart.remove(at: index)
                                        } label: {
                                            Image(systemName: "trash.fill").foregroundStyle(RSMSTheme.danger)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    if index < vm.returnCart.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    formRow(label: "NOTES") {
                        TextEditor(text: $vm.returnNotes)
                            .frame(height: 80)
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                    }

                    Button {
                        Task { await vm.submitReturn(dataStore: appVM.dataStore, requestedBy: appVM.currentUser?.id) }
                    } label: {
                        HStack(spacing: 8) {
                            if vm.isSubmitting {
                                ProgressView().tint(.white)
                            }
                            Text("Submit Return").font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(vm.returnCart.isEmpty ? RSMSTheme.textTertiary : Color(hue: 0.8, saturation: 0.6, brightness: 0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vm.returnCart.isEmpty || vm.isSubmitting)
                    .padding(.top, 10)

                }
                .padding(24)
            }
            .navigationTitle("New Vendor Return")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { vm.showCreateSheet = false }
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
    }

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.textTertiary)
            content()
                .padding(14)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private func statusBadge(_ status: MovementStatus) -> some View {
        let (text, color) = statusDisplay(status)
        return Text(text)
            .font(.caption2.weight(.bold))
            .tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func statusDisplay(_ status: MovementStatus) -> (String, Color) {
        switch status {
        case .requested:  return ("REQUESTED", RSMSTheme.textTertiary)
        case .approved:   return ("APPROVED", RSMSTheme.info)
        case .inTransit:  return ("SHIPPED", RSMSTheme.warning) // Contextually 'shipped' for returns
        case .received:   return ("RECEIVED", RSMSTheme.success)
        case .completed:  return ("COMPLETED", RSMSTheme.success)
        case .cancelled:  return ("CANCELLED", RSMSTheme.textTertiary)
        case .partial:    return ("PARTIAL", RSMSTheme.danger)
        case .exception:  return ("EXCEPTION", RSMSTheme.danger)
        }
    }
}
