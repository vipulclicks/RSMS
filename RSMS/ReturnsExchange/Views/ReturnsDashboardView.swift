//
//  ReturnsDashboardView.swift
//  RSMS
//

import SwiftUI

struct ReturnsDashboardView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var returnVM: POSReturnViewModel
    @State private var exchangeVM: POSExchangeViewModel
    @State private var isSyncing = false
    @State private var activeOrderRoute: Order?
    @State private var activeReturnRoute: POSReturnRequest?
    @State private var activeExchangeRoute: POSExchangeRequest?
    
    init(dataStore: DataStore) {
        _returnVM = State(wrappedValue: POSReturnViewModel(dataStore: dataStore))
        _exchangeVM = State(wrappedValue: POSExchangeViewModel(dataStore: dataStore))
    }
    
    var body: some View {
        List {
            // Search Results Section
            if !returnVM.searchText.isEmpty {
                Section("Search Results") {
                    if returnVM.searchedOrders.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text("No matching order found")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("Try searching by order ID or customer name.")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(returnVM.searchedOrders) { order in
                            Button {
                                activeOrderRoute = order
                            } label: {
                                OrderRowView(order: order, dataStore: appVM.dataStore)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(RSMSTheme.surfacePrimary)
                        }
                    }
                }
            }
            
            // Recent Returns Section
            Section("Recent Returns") {
                let returns = appVM.dataStore.posReturnRequests.filter { req in
                    if let order = appVM.dataStore.orders.first(where: { $0.id == req.orderId }) {
                        return appVM.dataStore.client(by: order.clientId) != nil
                    }
                    return false
                }
                if returns.isEmpty {
                    Text("No Return Requests")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .padding(.vertical, 8)
                        .listRowBackground(RSMSTheme.surfacePrimary)
                } else {
                    ForEach(returns.sorted(by: { $0.createdAt > $1.createdAt })) { req in
                        Button {
                            activeReturnRoute = req
                        } label: {
                            ReturnRequestRow(request: req, dataStore: appVM.dataStore)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(RSMSTheme.surfacePrimary)
                    }
                    .onDelete { indexSet in
                        let sortedReturns = returns.sorted(by: { $0.createdAt > $1.createdAt })
                        for index in indexSet {
                            let requestToDelete = sortedReturns[index]
                            Task {
                                try? await appVM.dataStore.deletePOSReturnRequest(id: requestToDelete.id)
                            }
                        }
                    }
                }
            }
            
            // Recent Exchanges Section
            Section("Recent Exchanges") {
                let exchanges = appVM.dataStore.posExchangeRequests.filter { req in
                    if let order = appVM.dataStore.orders.first(where: { $0.id == req.orderId }) {
                        return appVM.dataStore.client(by: order.clientId) != nil
                    }
                    return false
                }
                if exchanges.isEmpty {
                    Text("No Exchange Requests")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .padding(.vertical, 8)
                        .listRowBackground(RSMSTheme.surfacePrimary)
                } else {
                    ForEach(exchanges.sorted(by: { $0.createdAt > $1.createdAt })) { req in
                        Button {
                            activeExchangeRoute = req
                        } label: {
                            ExchangeRequestRow(request: req, dataStore: appVM.dataStore)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(RSMSTheme.surfacePrimary)
                    }
                    .onDelete { indexSet in
                        let sortedExchanges = exchanges.sorted(by: { $0.createdAt > $1.createdAt })
                        for index in indexSet {
                            let requestToDelete = sortedExchanges[index]
                            Task {
                                try? await appVM.dataStore.deletePOSExchangeRequest(id: requestToDelete.id)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $returnVM.searchText, prompt: "Search orders...")
        .navigationTitle("Returns & Exchanges")
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        isSyncing = true
                        await appVM.dataStore.fetchPOSReturnsExchanges()
                        isSyncing = false
                    }
                } label: {
                    if isSyncing {
                        ProgressView()
                            .tint(RSMSTheme.primary)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(RSMSTheme.primary)
                    }
                }
                .disabled(isSyncing)
            }
        }
        .task {
            // Fetch everything needed for lookups and search
            try? await appVM.dataStore.fetchProducts()
            try? await appVM.dataStore.fetchClients()
            try? await appVM.dataStore.fetchOrders()
            for order in appVM.dataStore.orders {
                try? await appVM.dataStore.fetchUniversalCartItems(cartId: order.cartId)
            }
            await appVM.dataStore.fetchPOSReturnsExchanges()
        }
        .navigationDestination(item: $activeOrderRoute) { order in
            OrderOptionsView(order: order, returnVM: returnVM, exchangeVM: exchangeVM)
        }
        .navigationDestination(item: $activeReturnRoute) { req in
            ReturnRequestDetailView(request: req, dataStore: appVM.dataStore)
        }
        .navigationDestination(item: $activeExchangeRoute) { req in
            ExchangeRequestDetailView(request: req, dataStore: appVM.dataStore)
        }
    }
}

// MARK: - Subviews

struct OrderRowView: View {
    let order: Order
    let dataStore: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Order #\(order.id.uuidString.prefix(8).uppercased())")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                Text(order.finalAmount, format: .currency(code: "INR"))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            
            HStack {
                Text(dataStore.clientName(for: order.clientId))
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text(order.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ReturnRequestRow: View {
    let request: POSReturnRequest
    let dataStore: DataStore
    
    private var clientAndOrderDetails: (clientName: String, orderIdString: String) {
        if let order = dataStore.orders.first(where: { $0.id == request.orderId }) {
            let clientName = dataStore.clientName(for: order.clientId)
            let orderIdString = "Order: #\(order.id.uuidString.prefix(8).uppercased())"
            return (clientName, orderIdString)
        }
        return ("Unknown Client", "Order: #Unknown")
    }
    
    private var displayNote: String {
        let trimmedReason = request.reason.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedReason.isEmpty {
            return trimmedReason
        }
        if let inspectionNotes = request.inspectionNotes, !inspectionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return inspectionNotes
        }
        return "No notes"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let product = dataStore.product(by: request.productId) {
                ProductRowImageView(product: product)
            } else {
                FallbackProductImageView(systemImage: "arrow.uturn.backward", statusColor: statusColor(request.status))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                let details = clientAndOrderDetails
                HStack(spacing: 8) {
                    Text(details.clientName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.primary)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(details.orderIdString)
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                
                Text(dataStore.productName(for: request.productId))
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("Qty: \(request.quantity)")
                    Text("•")
                    Text(displayNote)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(request.originalPaidAmount, format: .currency(code: "INR"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text(request.status.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(request.status).opacity(0.12), in: Capsule())
                    .foregroundStyle(statusColor(request.status))
            }
        }
        .padding(.vertical, 6)
    }
    
    private func statusColor(_ status: POSReturnStatus) -> Color {
        switch status {
        case .requested: return RSMSTheme.info
        case .inspectionPending: return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .rejected: return RSMSTheme.danger
        case .refunded: return RSMSTheme.primary
        }
    }
}

struct ExchangeRequestRow: View {
    let request: POSExchangeRequest
    let dataStore: DataStore
    
    private var clientAndOrderDetails: (clientName: String, orderIdString: String) {
        if let order = dataStore.orders.first(where: { $0.id == request.orderId }) {
            let clientName = dataStore.clientName(for: order.clientId)
            let orderIdString = "Order: #\(order.id.uuidString.prefix(8).uppercased())"
            return (clientName, orderIdString)
        }
        return ("Unknown Client", "Order: #Unknown")
    }
    
    private var displayNote: String {
        let trimmedReason = request.reason.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedReason.isEmpty {
            return trimmedReason
        }
        if let inspectionNotes = request.inspectionNotes, !inspectionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return inspectionNotes
        }
        return "No notes"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let product = dataStore.product(by: request.originalProductId) {
                ProductRowImageView(product: product)
            } else {
                FallbackProductImageView(systemImage: "arrow.triangle.2.circlepath", statusColor: statusColor(request.status))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                let details = clientAndOrderDetails
                HStack(spacing: 8) {
                    Text(details.clientName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.primary)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(details.orderIdString)
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                
                HStack(spacing: 6) {
                    Text(dataStore.productName(for: request.originalProductId))
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text(dataStore.productName(for: request.replacementProductId))
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Text("Qty: \(request.quantity)")
                    Text("•")
                    Text(displayNote)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                let diff = request.differenceAmount
                Text(abs(diff), format: .currency(code: "INR"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(diff >= 0 ? RSMSTheme.danger : RSMSTheme.success)
                
                Text(request.status.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(request.status).opacity(0.12), in: Capsule())
                    .foregroundStyle(statusColor(request.status))
            }
        }
        .padding(.vertical, 6)
    }
    
    private func statusColor(_ status: POSExchangeStatus) -> Color {
        switch status {
        case .requested: return RSMSTheme.info
        case .inspectionPending: return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .paymentPending: return RSMSTheme.warning
        case .completed: return RSMSTheme.primary
        case .rejected: return RSMSTheme.danger
        }
    }
}
