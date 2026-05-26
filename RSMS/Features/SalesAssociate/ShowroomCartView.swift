//
//  ShowroomCartView.swift
//  RSMS
//
//  A dedicated full-screen screen to view, customize, and checkout the curated cart.
//

import SwiftUI

enum ShowroomCartMode {
    case activeSession(viewModel: DigitalShowroomViewModel)
    case savedCart(cart: CuratedCart, dataStore: DataStore)
}

struct ShowroomCartView: View {
    let mode: ShowroomCartMode
    
    @Environment(\.dismiss) private var dismiss
    @State private var showShareToast = false
    @State private var navigateToCheckout = false
    
    // States for saved cart mode
    @State private var isSharing = false
    @State private var shareSuccess = false
    @State private var currentStatus: CartStatus = .active
    
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
                        // Header section
                        VStack(spacing: 8) {
                            Text(isEditMode ? "Current Edit for" : "Curated Cart for")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.textTertiary)
                                .textCase(.uppercase)
                                .tracking(1.5)
                            
                            Text(clientName)
                                .font(.system(size: 28, weight: .light, design: .serif))
                                .foregroundStyle(RSMSTheme.textPrimary)
                                
                            if case let .savedCart(cart, ds) = mode {
                                HStack(spacing: 6) {
                                    Text("Status:")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Text(currentStatus.rawValue.uppercased())
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(statusColor.opacity(0.15), in: Capsule())
                                        .foregroundStyle(statusColor)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal)
                        
                        // Main items & Layout
                        if isEmpty {
                            emptyView
                        } else {
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                // iPad Side-by-Side layout
                                HStack(alignment: .top, spacing: 24) {
                                    itemsSection
                                        .frame(maxWidth: .infinity)
                                    
                                    amountSummarySection
                                        .frame(width: 320)
                                }
                                .padding(.horizontal, 24)
                            } else {
                                // iPhone vertical stack layout
                                VStack(spacing: 24) {
                                    itemsSection
                                    
                                    amountSummarySection
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
        .navigationTitle("Curation Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.surfacePrimary, for: .navigationBar)
        .onAppear {
            if case let .savedCart(cart, ds) = mode {
                if let dbCart = ds.universalCarts.first(where: { $0.id == cart.id }) {
                    currentStatus = dbCart.status
                }
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
            POSCheckoutView()
        }
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
    private func activeSessionItemsList(vm: DigitalShowroomViewModel) -> some View {
        @Bindable var viewModel = vm
        ForEach($viewModel.cartItems) { $item in
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    // Product image
                    productImageView(imageURL: item.product.imageURL, categoryIconName: item.product.categoryIconName)
                    
                    // Product Info & Quantity / Note controls
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.product.name)
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                withAnimation {
                                    viewModel.toggleCartItem(item.product)
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
                        
                        // Client Reaction Selector & Quantity Selector
                        HStack {
                            HStack(spacing: 8) {
                                Text("Reaction:")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                
                                Picker("Reaction", selection: $item.reaction) {
                                    Text("Select").tag(ClientReaction?.none)
                                    ForEach(ClientReaction.allCases) { reaction in
                                        Text(reaction.rawValue).tag(ClientReaction?.some(reaction))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(item.reaction?.color ?? RSMSTheme.textSecondary)
                                .scaleEffect(0.9)
                                .padding(.horizontal, -8)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button {
                                    if item.quantity > 1 {
                                        item.quantity -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .font(.title3)
                                        .foregroundStyle(RSMSTheme.primary)
                                }
                                
                                Text("\(item.quantity)")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .frame(minWidth: 24, alignment: .center)
                                
                                Button {
                                    item.quantity += 1
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
                
                // Styling/SA Note Textfield
                TextField("Add styling note / feedback...", text: $item.saNote)
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
                            HStack(spacing: 8) {
                                Text("Reaction:")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                
                                Picker("Reaction", selection: Binding<ClientReaction?>(
                                    get: {
                                        ClientReaction(rawValue: currentNote)
                                    },
                                    set: { newRx in
                                        let updated = UniversalCartItem(
                                            id: item.id,
                                            cartId: item.cartId,
                                            productId: item.productId,
                                            quantity: currentQty,
                                            unitPrice: item.unitPrice,
                                            discountApplied: item.discountApplied,
                                            note: newRx?.rawValue ?? ""
                                        )
                                        Task {
                                            try? await ds.updateUniversalCartItem(updated)
                                        }
                                    }
                                )) {
                                    Text("Select").tag(ClientReaction?.none)
                                    ForEach(ClientReaction.allCases) { reaction in
                                        Text(reaction.rawValue).tag(ClientReaction?.some(reaction))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(ClientReaction(rawValue: currentNote)?.color ?? RSMSTheme.textSecondary)
                                .scaleEffect(0.9)
                                .padding(.horizontal, -8)
                            }
                            
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
                                        .foregroundStyle(RSMSTheme.primary)
                                }
                                
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
            Text("Amount Summary")
                .font(.title3.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            VStack(alignment: .leading, spacing: 16) {
                let subtotal = subtotalAmount
                let tax = subtotal * 0.20
                let total = subtotal + tax
                
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                    Text("₹\(Int(subtotal).formatted())")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
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
    
    // MARK: - Bottom Action Bar
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
                            ProgressView()
                                .tint(RSMSTheme.cream)
                        }
                        Text(isSavingText)
                            .font(.headline)
                    }
                    .foregroundStyle(RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isEmpty || isSavingFromViewModel ? AnyShapeStyle(RSMSTheme.surfaceSecondary) : AnyShapeStyle(RSMSTheme.primaryGradient))
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
                            ProgressView().tint(RSMSTheme.primary)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(isEmpty || isSharing ? RSMSTheme.textTertiary : RSMSTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isEmpty || isSharing ? RSMSTheme.border : RSMSTheme.primary, lineWidth: 1)
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
                        .foregroundStyle(RSMSTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSTheme.primary, lineWidth: 1)
                        )
                }
                
                // Proceed to Checkout
                Button {
                    navigateToCheckout = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                        Text("Checkout")
                    }
                    .font(.headline)
                    .foregroundStyle(isEmpty ? RSMSTheme.textTertiary : RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isEmpty ? AnyShapeStyle(RSMSTheme.surfaceSecondary) : AnyShapeStyle(RSMSTheme.primaryGradient))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isEmpty)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 12)
        .background(RSMSTheme.surfacePrimary)
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
