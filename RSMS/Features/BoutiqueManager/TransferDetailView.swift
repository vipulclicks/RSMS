import SwiftUI

struct TransferDetailView: View {
    let transfer: InventoryMovement
    @Bindable var viewModel: StockTransfersViewModel
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                headerCard
                
                // Items List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Transferred Items")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .padding(.horizontal, 4)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if viewModel.currentMovementItems.isEmpty {
                        Text("No items found for this transfer.")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(viewModel.currentMovementItems) { item in
                            itemCard(item)
                        }
                    }
                }
                
                // Action Buttons
                let isDestination = appVM.currentStoreId?.uuidString.lowercased() == transfer.destinationId.lowercased()
                let isSource = appVM.currentStoreId?.uuidString.lowercased() == transfer.sourceId.lowercased()
                let canReceive = (transfer.status == .inTransit || transfer.status == .approved) && isDestination
                let canApprove = transfer.status == .requested && isSource
                
                if canApprove {
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                if let user = appVM.currentUser {
                                    await viewModel.rejectTransfer(movement: transfer, dataStore: appVM.dataStore, user: user)
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isReceiving {
                                    ProgressView().tint(RSMSTheme.danger)
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Reject")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.danger.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(viewModel.isReceiving)

                        Button {
                            Task {
                                if let user = appVM.currentUser {
                                    await viewModel.approveTransfer(movement: transfer, dataStore: appVM.dataStore, user: user)
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isReceiving {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Approve")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.success)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: RSMSTheme.success.opacity(0.3), radius: 10, y: 4)
                        }
                        .disabled(viewModel.isReceiving)
                    }
                } else if canReceive {
                    Button {
                        Task {
                            await viewModel.receiveTransfer(movement: transfer, dataStore: appVM.dataStore)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if viewModel.isReceiving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "tray.and.arrow.down.fill")
                                Text("Receive Transfer")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.success)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: RSMSTheme.success.opacity(0.3), radius: 10, y: 4)
                    }
                    .disabled(viewModel.isReceiving)
                }
            }
            .padding(24)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Transfer Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetails(for: transfer, dataStore: appVM.dataStore)
        }
    }
    
    private var headerCard: some View {
        let sourceName = viewModel.storeName(for: transfer.sourceId, dataStore: appVM.dataStore)
        let destName = viewModel.storeName(for: transfer.destinationId, dataStore: appVM.dataStore)
        
        let statusColor: Color = {
            switch transfer.status {
            case .completed, .received: return RSMSTheme.success
            case .inTransit: return RSMSTheme.warning
            case .requested, .approved: return RSMSTheme.info
            case .cancelled, .exception: return RSMSTheme.danger
            default: return RSMSTheme.textSecondary
            }
        }()
        
        return VStack(spacing: 20) {
            HStack {
                Text("Transfer Status")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
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
            
            if horizontalSizeClass == .compact {
                VStack(spacing: 16) {
                    // Source
                    VStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text("From")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text(sourceName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Arrow
                    Image(systemName: "arrow.down")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.gold)
                    
                    // Destination
                    VStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.primary)
                        Text("To")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text(destName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: 0) {
                    // Source
                    VStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text("From")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text(sourceName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Arrow
                    VStack {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.gold)
                    }
                    .frame(width: 40)
                    
                    // Destination
                    VStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.primary)
                        Text("To")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text(destName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            if let date = transfer.requestedAt {
                Divider()
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("Requested on \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
    }
    
    private func itemCard(_ item: MovementItem) -> some View {
        let product = appVM.dataStore.products.first { $0.id == item.productId }
        
        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.surfaceTertiary)
                    .frame(width: 48, height: 48)
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product?.name ?? "Unknown Product")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("SKU: \(product?.sku ?? "---")")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.quantity)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Units")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
        )
    }
}
