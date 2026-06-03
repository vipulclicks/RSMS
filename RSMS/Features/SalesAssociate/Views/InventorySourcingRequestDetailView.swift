//
//  InventorySourcingRequestDetailView.swift
//  RSMS
//

import SwiftUI

struct InventorySourcingRequestDetailView: View {
    let request: InventorySourcingRequest
    @Bindable var sourcingVM: InventorySourcingViewModel
    
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSourceStore: Store?
    @State private var showingCancelAlert = false
    @State private var isFetchingStock = false
    
    var currentRequest: InventorySourcingRequest {
        sourcingVM.requests.first(where: { $0.id == request.id }) ?? request
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Status Header Card
                    statusHeaderCard
                    
                    // Request Details
                    detailsCard
                    
                    // Role-Specific Action Workflow Panels
                    let role = appViewModel.currentUser?.role ?? .salesAssociate
                    
                    if role == .inventoryController {
                        if currentRequest.status == .requested || currentRequest.status == .searching || currentRequest.status == .stockFound {
                            inventorySourcingActionPanel
                        } else if currentRequest.status == .transferInitiated || currentRequest.status == .inTransit || currentRequest.status == .received {
                            inventoryControllerProgressPanel
                        }
                    } else if role == .salesAssociate {
                        if currentRequest.status == .available {
                            salesAssociateResolutionPanel
                        }
                    }
                    
                    // Cancel Sourcing Request (for Associate/Manager if pending)
                    if canCancel {
                        Button {
                            showingCancelAlert = true
                        } label: {
                            Text("Cancel Sourcing Request")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.danger)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(RSMSTheme.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.danger.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Sourcing Request Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancel Sourcing Request", isPresented: $showingCancelAlert) {
            Button("Cancel Request", role: .destructive) {
                Task {
                    await sourcingVM.updateRequestStatus(dataStore: appViewModel.dataStore, request: currentRequest, status: .cancelled)
                    dismiss()
                }
            }
            Button("Keep Request", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this sourcing request? This action cannot be undone.")
        }
        .task {
            isFetchingStock = true
            try? await appViewModel.dataStore.fetchStores()
            try? await appViewModel.dataStore.fetchStockItems()
            isFetchingStock = false
            
            // Automatically transition Requested to Searching if Inventory Controller opens it
            if appViewModel.currentUser?.role == .inventoryController && currentRequest.status == .requested {
                await sourcingVM.updateRequestStatus(dataStore: appViewModel.dataStore, request: currentRequest, status: .searching)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var statusHeaderCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Sourcing Lifecycle")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle().fill(currentRequest.status.color).frame(width: 8, height: 8)
                    Text(currentRequest.status.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(currentRequest.status.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(currentRequest.status.color.opacity(0.1)))
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            // Vertical stepper steps definition
            let steps: [(status: InventorySourcingStatus, title: String, subtitle: String)] = [
                (.requested, "Request Created", "Sales associate requested the product"),
                (.searching, "Locating Stock", "Checking stock availability in nearby boutiques"),
                (.stockFound, "Stock Located", "Available stock has been identified"),
                (.transferInitiated, "Transfer Initiated", "Inventory controller initiated transfer"),
                (.inTransit, "Shipped & In Transit", "Item is on its way to your boutique"),
                (.received, "Received at Boutique", "Shipment received and being verified"),
                (.available, "Available in Catalog", "Product back in catalog and ready for client checkout")
            ]
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { idx in
                    let step = steps[idx]
                    
                    // Determine status of this step relative to current status
                    let isCompleted = isStepCompleted(stepStatus: step.status, currentStatus: currentRequest.status)
                    let isCurrent = currentRequest.status == step.status
                    
                    HStack(alignment: .top, spacing: 16) {
                        // Vertical Indicator Line & Bullet
                        VStack(spacing: 0) {
                            if isCompleted {
                                Circle()
                                    .fill(RSMSTheme.success)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(Color.white)
                                    )
                            } else if isCurrent {
                                Circle()
                                    .fill(currentRequest.status.color)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 8, height: 8)
                                    )
                            } else {
                                Circle()
                                    .stroke(RSMSTheme.border, lineWidth: 2)
                                    .background(Circle().fill(RSMSTheme.surfaceSecondary))
                                    .frame(width: 22, height: 22)
                            }
                            
                            // Line connecting to next bullet (except last)
                            if idx < steps.count - 1 {
                                Rectangle()
                                    .fill(isCompleted ? RSMSTheme.success : RSMSTheme.border)
                                    .frame(width: 2, height: 32)
                            }
                        }
                        
                        // Text Details
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.system(size: 14, weight: isCurrent ? .semibold : .medium))
                                .foregroundStyle(isCurrent ? currentRequest.status.color : (isCompleted ? RSMSTheme.textPrimary : RSMSTheme.textTertiary))
                            
                            Text(step.subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(isCurrent ? RSMSTheme.textSecondary : RSMSTheme.textTertiary)
                        }
                        .padding(.top, 2)
                        
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    private func isStepCompleted(stepStatus: InventorySourcingStatus, currentStatus: InventorySourcingStatus) -> Bool {
        // Special case: cancelled requests have no completed status sequence
        if currentStatus == .cancelled { return false }
        
        let statusOrder: [InventorySourcingStatus] = [
            .requested,
            .searching,
            .stockFound,
            .transferInitiated,
            .inTransit,
            .received,
            .available,
            .completed
        ]
        
        guard let stepIdx = statusOrder.firstIndex(of: stepStatus),
              let currentIdx = statusOrder.firstIndex(of: currentStatus) else {
            return false
        }
        
        return stepIdx < currentIdx
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sourcing Product Information")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RSMSTheme.surfaceSecondary)
                        .frame(width: 56, height: 56)
                    Image(systemName: "shippingbox.fill")
                        .font(.title3)
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentRequest.productName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    if let product = appViewModel.dataStore.products.first(where: { $0.id == currentRequest.productId }) {
                        Text("SKU: \(product.sku)")
                            .font(.caption.monospaced())
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text(product.brand)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            VStack(spacing: 12) {
                detailRow(label: "Requested Quantity", value: "\(currentRequest.requestedQuantity) unit\(currentRequest.requestedQuantity == 1 ? "" : "s")")
                detailRow(label: "Destination Store", value: appViewModel.dataStore.storeName(for: currentRequest.requestingStoreId))
                detailRow(label: "Requested By", value: appViewModel.dataStore.userName(for: currentRequest.salesAssociateId))
                detailRow(label: "Request Date", value: currentRequest.createdAt.formatted(date: .long, time: .shortened))
                
                if let sourceStoreId = currentRequest.sourceStoreId {
                    detailRow(label: "Sourced From Store", value: appViewModel.dataStore.storeName(for: sourceStoreId))
                }
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    // MARK: - Inventory Controller workflow panel
    
    private var inventorySourcingActionPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Locate Stock Availability")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            
            Text("Select a source store that has available stock to initiate the inventory transfer.")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            Divider().overlay(RSMSTheme.divider)
            
            // Render store stock levels
            let stockList = storesStockAvailability
            
            if isFetchingStock {
                HStack {
                    Spacer()
                    ProgressView("Locating stock...")
                        .tint(RSMSTheme.primary)
                    Spacer()
                }
                .padding()
            } else if stockList.isEmpty {
                Text("No available stock found in other boutiques.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(stockList, id: \.store.id) { stock in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stock.store.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text("\(stock.quantity) unit\(stock.quantity == 1 ? "" : "s") available")
                                    .font(.caption)
                                    .foregroundStyle(stock.quantity > 0 ? RSMSTheme.success : RSMSTheme.textTertiary)
                            }
                            
                            Spacer()
                            
                            Button {
                                selectedSourceStore = stock.store
                                Task {
                                    await sourcingVM.updateRequestStatus(dataStore: appViewModel.dataStore, request: currentRequest, status: .stockFound)
                                }
                            } label: {
                                Text(selectedSourceStore?.id == stock.store.id ? "Selected" : "Select")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(selectedSourceStore?.id == stock.store.id ? RSMSTheme.cream : RSMSTheme.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedSourceStore?.id == stock.store.id ? AnyShapeStyle(RSMSTheme.primary) : AnyShapeStyle(Color.clear))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(RSMSTheme.primary, lineWidth: 1))
                            }
                        }
                        .padding(12)
                        .background(RSMSTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedSourceStore?.id == stock.store.id ? RSMSTheme.primary : Color.clear, lineWidth: 1.5))
                    }
                }
            }
            
            if let srcStore = selectedSourceStore {
                Button {
                    Task {
                        guard let controllerId = appViewModel.currentUser?.id else { return }
                        await sourcingVM.initiateTransfer(
                            dataStore: appViewModel.dataStore,
                            request: currentRequest,
                            sourceStoreId: srcStore.id,
                            controllerId: controllerId
                        )
                    }
                } label: {
                    HStack {
                        if sourcingVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Initiate Inventory Transfer")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RSMSTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(sourcingVM.isLoading)
                .padding(.top, 8)
                
                if let error = sourcingVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    private var inventoryControllerProgressPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Sourcing Fulfillment")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            
            Text("Follow the stock shipment progress and complete the transfer on delivery.")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            Divider().overlay(RSMSTheme.divider)
            
            VStack(spacing: 12) {
                if currentRequest.status == .transferInitiated {
                    Button {
                        Task {
                            await sourcingVM.updateRequestStatus(dataStore: appViewModel.dataStore, request: currentRequest, status: .inTransit)
                        }
                    } label: {
                        Text("Mark Shipped (In Transit)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RSMSTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if currentRequest.status == .inTransit {
                    Button {
                        Task {
                            await sourcingVM.updateRequestStatus(dataStore: appViewModel.dataStore, request: currentRequest, status: .received)
                        }
                    } label: {
                        Text("Mark Received at Boutique")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RSMSTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if currentRequest.status == .received {
                    Button {
                        Task {
                            await sourcingVM.markTransferCompletedAndAvailable(dataStore: appViewModel.dataStore, request: currentRequest)
                        }
                    } label: {
                        HStack {
                            if sourcingVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Complete Transfer & Mark Available")
                            }
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RSMSTheme.success)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(sourcingVM.isLoading)
                }
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    // MARK: - Sales Associate workflow panel
    
    private var salesAssociateResolutionPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(RSMSTheme.primary)
                Text("Item Available in Stock")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            
            Text("The sourcing transfer has completed successfully! Please hand the product to the client or allocate it to their order, then mark this request as completed.")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            Divider().overlay(RSMSTheme.divider)
            
            Button {
                Task {
                    await sourcingVM.updateRequestStatus(dataStore: appViewModel.dataStore, request: currentRequest, status: .completed)
                }
            } label: {
                Text("Mark Sourcing Completed")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RSMSTheme.success)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.success.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Helpers
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
    }
    
    private var progressFraction: Double {
        switch currentRequest.status {
        case .requested: return 0.12
        case .searching: return 0.25
        case .stockFound: return 0.38
        case .transferInitiated: return 0.50
        case .inTransit: return 0.63
        case .received: return 0.75
        case .available: return 0.88
        case .completed: return 1.0
        case .cancelled: return 0.0
        }
    }
    
    private var isInTransfer: Bool {
        currentRequest.status == .transferInitiated || currentRequest.status == .inTransit || currentRequest.status == .received
    }
    
    private var canCancel: Bool {
        let isPending = currentRequest.status == .requested || currentRequest.status == .searching || currentRequest.status == .stockFound
        let isAssociateOrManager = appViewModel.currentUser?.role == .salesAssociate || appViewModel.currentUser?.role == .boutiqueManager
        return isPending && isAssociateOrManager
    }
    
    struct StoreStock: Hashable {
        let store: Store
        let quantity: Int
    }
    
    private var storesStockAvailability: [StoreStock] {
        let stores = appViewModel.dataStore.stores.filter { $0.id != currentRequest.requestingStoreId }
        return stores.compactMap { store in
            let qty = appViewModel.dataStore.stockItems
                .filter { $0.productId == currentRequest.productId && $0.storeId == store.id && $0.status == .available }
                .reduce(0) { $0 + $1.quantity }
            
            // Only list stores that actually have stock
            guard qty > 0 else { return nil }
            return StoreStock(store: store, quantity: qty)
        }
    }
}
