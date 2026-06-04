import SwiftUI

struct StockTransfersView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel = StockTransfersViewModel()
    @State private var selectedTab: TransferTab = .inbound
    
    enum TransferTab: String, CaseIterable {
        case inbound = "Incoming"
        case outbound = "Outgoing"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Control
                    Picker("Transfer Type", selection: $selectedTab) {
                        ForEach(TransferTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading Transfers...")
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                let transfers = currentTransfers
                                
                                if transfers.isEmpty {
                                    emptyState(for: selectedTab)
                                        .padding(.top, 40)
                                } else {
                                    ForEach(transfers) { transfer in
                                        NavigationLink(value: transfer) {
                                            transferCard(transfer)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(24)
                        }
                    }
                }
            }
            .navigationTitle("Stock Transfers")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: InventoryMovement.self) { transfer in
                TransferDetailView(transfer: transfer, viewModel: viewModel)
            }
            .task {
                await viewModel.load(dataStore: appVM.dataStore)
            }
            .refreshable {
                await viewModel.load(dataStore: appVM.dataStore)
            }
        }
    }
    
    private var currentTransfers: [InventoryMovement] {
        guard let storeId = appVM.currentStoreId else { return [] }
        switch selectedTab {
        case .inbound:
            return viewModel.inboundTransfers(for: storeId)
        case .outbound:
            return viewModel.outboundTransfers(for: storeId)
        }
    }
    
    private func emptyState(for tab: TransferTab) -> some View {
        VStack(spacing: 16) {
            Image(systemName: tab == .inbound ? "tray.and.arrow.down.fill" : "tray.and.arrow.up.fill")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.textTertiary)
            
            Text("No \(tab.rawValue)")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            
            Text(tab == .inbound ? "There are no incoming transfers to this store." : "There are no outgoing transfers from this store.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfacePrimary)
        )
    }
    
    private func transferCard(_ transfer: InventoryMovement) -> some View {
        let statusColor: Color = {
            switch transfer.status {
            case .completed, .received: return RSMSTheme.success
            case .inTransit: return RSMSTheme.warning
            case .requested, .approved: return RSMSTheme.info
            case .cancelled, .exception: return RSMSTheme.danger
            default: return RSMSTheme.textSecondary
            }
        }()
        
        let targetStoreId = selectedTab == .inbound ? transfer.sourceId : transfer.destinationId
        let targetStoreName = viewModel.storeName(for: targetStoreId, dataStore: appVM.dataStore)
        let directionLabel = selectedTab == .inbound ? "From:" : "To:"
        let directionIcon = selectedTab == .inbound ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill"
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: directionIcon)
                        .foregroundStyle(selectedTab == .inbound ? RSMSTheme.info : RSMSTheme.primary)
                    Text("\(directionLabel) \(targetStoreName)")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle().fill(statusColor).frame(width: 8, height: 8)
                    Text(transfer.status.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(statusColor.opacity(0.1)))
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Items Expected")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("\(transfer.itemsExpected ?? 0)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    if let date = transfer.requestedAt {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.textPrimary)
                    } else {
                        Text("--")
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}
