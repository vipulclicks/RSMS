//
//  ShowroomCartView.swift
//  RSMS
//
//  A dedicated full-screen screen to view, customize, and checkout the curated cart.
//

import SwiftUI

enum ShowroomCartMode {
    case activeSession(viewModel: ProductCatalogViewModel)
    case savedCart(cart: CuratedCart, dataStore: DataStore)
}

struct ShowroomCartView: View {
    let mode: ShowroomCartMode
    
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    @State private var showShareToast = false
    @State private var navigateToCheckout = false
    
    // States for saved cart mode
    @State private var isSharing = false
    @State private var shareSuccess = false
    @State private var currentStatus: CartStatus = .active
    
    // Discount State
    @State private var showDiscountSheet = false
    
    // Compute or check mode
    private var isEditMode: Bool {
        if case .activeSession = mode { return true }
        return false
    }
    
    private var clientName: String {
        switch mode {
        case .activeSession(let vm):
            return vm.client.fullName
        case .savedCart(let cart, let ds):
            if let dbCart = ds.universalCarts.first(where: { $0.id == cart.id }),
               let clientId = dbCart.clientId {
                return ds.clients.first(where: { $0.id == clientId })?.fullName ?? "Client"
            }
            return "Client"
        }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Main items & Layout
                        if isEmpty {
                            emptyView
                        } else {
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                // iPad Side-by-Side layout
                                HStack(alignment: .top, spacing: 24) {
                                    itemsSection
                                        .frame(maxWidth: .infinity)
                                    
                                    VStack(spacing: 16) {
                                        amountSummarySection
                                        
                                        // Approval Request Banner — driven by DB record, not cart note
                                        if let req = activeApprovalRequest, req.status != .approved {
                                            approvalStatusBanner(status: req.status, managerNotes: req.managerNotes)
                                        }
                                    }
                                    .frame(width: 320)
                                }
                                .padding(.horizontal, 24)
                            } else {
                                // iPhone vertical stack layout
                                VStack(spacing: 24) {
                                    itemsSection
                                    
                                    amountSummarySection
                                    
                                    // Approval Request Banner — driven by DB record, not cart note
                                    if let req = activeApprovalRequest, req.status != .approved {
                                        approvalStatusBanner(status: req.status, managerNotes: req.managerNotes)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // Bottom actions section
                bottomActionBar
            }
            
            // Share success notification toast
            if showShareToast || shareSuccess {
                VStack {
                    Spacer()
                    ToastView(message: "Shared curated link successfully!")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(), value: showShareToast || shareSuccess)
            }
        }
        .navigationTitle("Curated Cart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.surfacePrimary, for: .navigationBar)
        .onAppear {
            if case let .savedCart(cart, ds) = mode {
                if let dbCart = ds.universalCarts.first(where: { $0.id == cart.id }) {
                    currentStatus = dbCart.status
                }
            }
        }
        .task {
            // Always re-fetch approval requests from DB so we see the latest manager decisions
            try? await appVM.dataStore.fetchDiscountApprovalRequests()
            // Also re-fetch carts so the discount note field is current
            if let associateId = appVM.currentUser?.id {
                try? await appVM.dataStore.fetchUniversalCarts(associateId: associateId, type: .curated)
            }
        }
        .alert("Saved", isPresented: isEditModeSuccessPresented) {
            Button("Done") { dismiss() }
        } message: {
            if case let .activeSession(vm) = mode {
                Text("Your Curated Edit has been saved for \(vm.client.fullName).")
            } else {
                Text("Your changes have been saved.")
            }
        }
        .navigationDestination(isPresented: $navigateToCheckout) {
            if let cart = currentCart {
                let checkoutVM = POSCheckoutViewModel(
                    dataStore: appVM.dataStore,
                    associateId: getAssociateId(),
                    storeId: appVM.currentStoreId ?? UUID()
                )
                PaymentSummaryView(cart: cart, checkoutVM: checkoutVM)
            } else {
                Text("Error: Cart unavailable")
            }
        }
        .sheet(isPresented: $showDiscountSheet) {
            CartDiscountSheet(
                cartId: currentCart?.id ?? UUID(),
                clientId: currentCart?.clientId ?? UUID(),
                cartSubtotal: subtotalAmount,
                associateId: getAssociateId(),
                appliedDiscount: Binding(
                    get: { currentCart?.appliedDiscount },
                    set: { newDiscount in
                        updateDiscount(newDiscount)
                    }
                )
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Cart & Discount Helpers
    
    private var activeApprovalRequest: DiscountApprovalRequest? {
        guard let cartId = currentCart?.id else { return nil }
        return appVM.dataStore.discountApprovalRequests
            .filter { $0.cartId == cartId }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    // MARK: - Helpers for Mode Checks
    private var isEmpty: Bool {
        switch mode {
        case .activeSession(let vm):
            return vm.cartItems.isEmpty
        case .savedCart(let cart, let ds):
            return ds.universalCartItems.filter { $0.cartId == cart.id }.isEmpty
        }
    }
    
    private var isEditModeSuccessPresented: Binding<Bool> {
        Binding<Bool>(
            get: {
                if case let .activeSession(vm) = mode {
                    return vm.showSuccess
                }
                return false
            },
            set: { newValue in
                if case let .activeSession(vm) = mode {
                    vm.showSuccess = newValue
                }
            }
        )
    }
    
    // MARK: - Empty State
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(RSMSTheme.textTertiary)
                .padding(.top, 60)
            
            Text("No Selected Items")
                .font(.title3.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            Text(isEditMode ? "Browse the catalog and add products to show the client." : "This cart is empty.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Selected Items List
    @ViewBuilder
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Selected Pieces")
                .font(.title3.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            switch mode {
            case .activeSession(let vm):
                activeSessionItemsList(vm: vm)
            case .savedCart(let cart, let ds):
                savedCartItemsList(cart: cart, ds: ds)
            }
        }
    }
    
    @ViewBuilder
    private func activeSessionItemsList(vm: ProductCatalogViewModel) -> some View {
        ForEach(vm.cartItems) { item in
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    // Product image
                    productImageView(imageURL: item.product.imageURL, categoryIconName: item.product.categoryIconName)
                    
                    // Product Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.product.name)
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                withAnimation {
                                    vm.toggleCartItem(item.product)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.danger)
                            }
                        }
                        
                        if let col = item.product.collection {
                            Text(col)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        
                        Text(item.product.formattedPrice)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.primary)
                            .padding(.vertical, 2)
                        
                        Text(item.product.brand.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1.0)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            .padding()
            .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
    }
    
    @ViewBuilder
    private func savedCartItemsList(cart: CuratedCart, ds: DataStore) -> some View {
        let activeItems = ds.universalCartItems.filter { $0.cartId == cart.id }
        ForEach(activeItems) { item in
            let product = ds.products.first(where: { $0.id == item.productId })
            let currentQty = item.quantity
            let currentNote = item.note ?? ""
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    productImageView(imageURL: product?.imageURL, categoryIconName: product?.categoryIconName ?? "gift.fill")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(product?.name ?? "Unknown Product")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                Task {
                                    try? await ds.deleteUniversalCartItem(id: item.id)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.danger)
                            }
                        }
                        
                        if let col = product?.collection {
                            Text(col)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        
                        Text("₹\(Int(product?.price ?? 0).formatted())")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.primary)
                            .padding(.vertical, 2)
                        
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button {
                                    if currentQty > 1 {
                                        let updated = UniversalCartItem(
                                            id: item.id,
                                            cartId: item.cartId,
                                            productId: item.productId,
                                            quantity: currentQty - 1,
                                            unitPrice: item.unitPrice,
                                            discountApplied: item.discountApplied,
                                            note: item.note
                                        )
                                        Task {
                                            try? await ds.updateUniversalCartItem(updated)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .font(.title3)
                                        .foregroundStyle(currentQty > 1 ? RSMSTheme.primary : RSMSTheme.textTertiary)
                                }
                                .disabled(currentQty <= 1)
                                
                                Text("\(currentQty)")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .frame(minWidth: 24, alignment: .center)
                                
                                Button {
                                    let updated = UniversalCartItem(
                                        id: item.id,
                                        cartId: item.cartId,
                                        productId: item.productId,
                                        quantity: currentQty + 1,
                                        unitPrice: item.unitPrice,
                                        discountApplied: item.discountApplied,
                                        note: item.note
                                    )
                                    Task {
                                        try? await ds.updateUniversalCartItem(updated)
                                    }
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .font(.title3)
                                        .foregroundStyle(RSMSTheme.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                TextField("Add styling note / feedback...", text: Binding<String>(
                    get: { currentNote },
                    set: { newNote in
                        let updated = UniversalCartItem(
                            id: item.id,
                            cartId: item.cartId,
                            productId: item.productId,
                            quantity: currentQty,
                            unitPrice: item.unitPrice,
                            discountApplied: item.discountApplied,
                            note: newNote
                        )
                        Task {
                            try? await ds.updateUniversalCartItem(updated)
                        }
                    }
                ))
                .font(.subheadline)
                .padding(10)
                .background(RSMSTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
                .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding()
            .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
    }
    
    @ViewBuilder
    private func productImageView(imageURL: String?, categoryIconName: String) -> some View {
        if let urlString = imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(RSMSTheme.surfaceSecondary)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: categoryIconName)
                        .font(.title)
                        .foregroundStyle(RSMSTheme.textTertiary.opacity(0.6))
                )
        }
    }
    
    // MARK: - Amount Summary Section
    private var amountSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Amount Summary")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                if currentCartDiscount == nil {
                    Button {
                        showDiscountSheet = true
                    } label: {
                        Text("Apply Discount")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RSMSTheme.primary.opacity(0.1), in: Capsule())
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                let subtotal = subtotalAmount
                
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                    Text("₹\(Int(subtotal).formatted())")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                if let discount = currentCartDiscount {
                    let effectiveStatus = activeApprovalRequest?.status ?? .approved
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Discount (\(discount.type.rawValue.capitalized))")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.danger)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(effectiveStatus == .approved ? RSMSTheme.success : (effectiveStatus == .rejected ? RSMSTheme.danger : .orange))
                                    .frame(width: 6, height: 6)
                                Text(effectiveStatus.rawValue.capitalized)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("- ₹\(Int(calculatedDiscountValue(discount)).formatted())")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.danger)
                            
                            Button("Edit") {
                                showDiscountSheet = true
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(RSMSTheme.primary)
                        }
                    }
                }
                
                let postDiscountSubtotal = max(0, subtotal - (currentCartDiscount.map { calculatedDiscountValue($0) } ?? 0))
                let tax = postDiscountSubtotal * 0.20
                let total = postDiscountSubtotal + tax
                
                HStack {
                    Text("Tax (20%)")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                    Text("₹\(Int(tax).formatted())")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Divider().overlay(RSMSTheme.divider)
                
                HStack {
                    Text("Total Estimated")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    Text("₹\(Int(total).formatted())")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RSMSTheme.primary)
                }
            }
            .padding()
            .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
    }
    
    private var subtotalAmount: Double {
        switch mode {
        case .activeSession(let vm):
            return vm.totalValue
        case .savedCart(let cart, let ds):
            let activeItems = ds.universalCartItems.filter { $0.cartId == cart.id }
            return activeItems.reduce(0) { total, item in
                let price = ds.products.first(where: { $0.id == item.productId })?.price ?? 0.0
                return total + (price * Double(item.quantity))
            }
        }
    }
    
    // MARK: - Discount Status Banner
    
    @ViewBuilder
    private func approvalStatusBanner(status: DiscountApprovalStatus, managerNotes: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status == .pending ? "clock.fill" : (status == .approved ? "checkmark.seal.fill" : "xmark.octagon.fill"))
                .font(.system(size: 20))
                .foregroundStyle(status == .pending ? .orange : (status == .approved ? RSMSTheme.success : RSMSTheme.danger))
                
            VStack(alignment: .leading, spacing: 4) {
                Text("Discount \(status.rawValue.capitalized)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                if status == .pending {
                    Text("Awaiting Boutique Manager approval before checkout can proceed.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                } else if status == .rejected, let notes = managerNotes {
                    Text("Reason: \(notes)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            Spacer()
        }
        .padding()
        .background((status == .pending ? Color.orange : (status == .approved ? RSMSTheme.success : RSMSTheme.danger)).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
    
    // MARK: - Bottom Actions Bar
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            Divider().overlay(RSMSTheme.divider)
            
            HStack(spacing: 16) {
                // Save Cart
                Button {
                    switch mode {
                    case .activeSession(let vm):
                        vm.isSaving = true
                        Task { await vm.saveShowroom() }
                    case .savedCart:
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSavingFromViewModel {
                            ProgressView().tint(RSMSTheme.cream)
                        }
                        Text(isSavingText)
                    }
                    .font(.headline)
                    .foregroundStyle((isEmpty || isSavingFromViewModel) ? RSMSTheme.textTertiary : RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background((isEmpty || isSavingFromViewModel) ? RSMSTheme.surfaceTertiary : RSMSTheme.primaryDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isEmpty || isSavingFromViewModel)
                
                // Share Cart
                Button {
                    switch mode {
                    case .activeSession:
                        triggerShare()
                    case .savedCart(let cart, let ds):
                        shareCart(cart: cart, ds: ds)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSharing {
                            ProgressView().tint(RSMSTheme.primaryDark)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle((isEmpty || isSharing) ? RSMSTheme.textTertiary : RSMSTheme.primaryDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke((isEmpty || isSharing) ? RSMSTheme.border : RSMSTheme.primaryDark, lineWidth: 1)
                    )
                }
                .disabled(isEmpty || isSharing)
            }
            
            HStack(spacing: 16) {
                // Continue Browsing
                Button {
                    dismiss()
                } label: {
                    Text("Continue Browsing")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.primaryDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSTheme.primaryDark, lineWidth: 1)
                        )
                }
                
                // Proceed to Checkout — blocked only if a real DB approval request is pending or rejected
                let isCheckoutBlocked = (activeApprovalRequest?.status == .pending) || (activeApprovalRequest?.status == .rejected)
                
                Button {
                    navigateToCheckout = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCheckoutBlocked ? "lock.fill" : "creditcard.fill")
                        Text(isCheckoutBlocked ? "Checkout Locked" : "Checkout")
                    }
                    .font(.headline)
                    .foregroundStyle((isEmpty || isCheckoutBlocked) ? RSMSTheme.textTertiary : RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background((isEmpty || isCheckoutBlocked) ? RSMSTheme.surfaceTertiary : RSMSTheme.primaryDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isEmpty || isCheckoutBlocked)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 12)
        .background(RSMSTheme.surfacePrimary)
    }
    
    // MARK: - Discount Logic
    
    private var currentCartDiscount: CartDiscount? {
        currentCart?.appliedDiscount
    }
    
    private var currentCart: UniversalCart? {
        switch mode {
        case .activeSession(let vm):
            return vm.activeUniversalCart
        case .savedCart(let cart, let ds):
            return ds.universalCarts.first(where: { $0.id == cart.id })
        }
    }
    
    private func getAssociateId() -> UUID {
        switch mode {
        case .activeSession(let vm):
            return vm.associateId ?? UUID()
        case .savedCart(let cart, let ds):
            return ds.universalCarts.first(where: { $0.id == cart.id })?.associateId ?? UUID()
        }
    }
    
    private func updateDiscount(_ discount: CartDiscount?) {
        switch mode {
        case .activeSession(let vm):
            Task { await vm.updateCartDiscount(discount) }
        case .savedCart(let cart, let ds):
            guard let dbCart = ds.universalCarts.first(where: { $0.id == cart.id }) else { return }
            let updated = dbCart.applyingDiscount(discount)
            Task { try? await ds.updateUniversalCart(updated) }
        }
    }
    
    private func calculatedDiscountValue(_ discount: CartDiscount) -> Double {
        switch discount.type {
        case .percentage, .vip:
            return subtotalAmount * (discount.value / 100.0)
        case .promotional:
            return discount.value
        }
    }
    
    private var isSavingFromViewModel: Bool {
        if case let .activeSession(vm) = mode {
            return vm.isSaving
        }
        return false
    }
    
    private var isSavingText: String {
        switch mode {
        case .activeSession(let vm):
            return vm.isSaving ? "Saving..." : "Save Cart"
        case .savedCart:
            return "Save Cart"
        }
    }
    
    private var statusColor: Color {
        switch currentStatus {
        case .active, .draft:
            return .orange
        case .shared, .viewed:
            return RSMSTheme.success
        case .completed, .converted:
            return RSMSTheme.info
        default:
            return RSMSTheme.textSecondary
        }
    }
    
    private func triggerShare() {
        showShareToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showShareToast = false
        }
    }
    
    private func shareCart(cart: CuratedCart, ds: DataStore) {
        guard let dbCart = ds.universalCarts.first(where: { $0.id == cart.id }) else { return }
        isSharing = true
        Task {
            do {
                let updated = UniversalCart(
                    id: dbCart.id,
                    type: dbCart.type,
                    associateId: dbCart.associateId,
                    clientId: dbCart.clientId,
                    storeId: dbCart.storeId,
                    status: .shared,
                    note: dbCart.note,
                    createdAt: dbCart.createdAt,
                    updatedAt: Date()
                )
                try await ds.updateUniversalCart(updated)
                await MainActor.run {
                    currentStatus = .shared
                    isSharing = false
                    withAnimation {
                        shareSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            shareSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isSharing = false
                }
            }
        }
    }
}

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8), in: Capsule())
            .padding(.bottom, 50)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
