// CuratedCartDetailView.swift
import SwiftUI

struct CuratedCartDetailView: View {
    let cart: CuratedCart
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var isSharing = false
    @State private var shareSuccess = false
    @State private var currentStatus: CartStatus
    
    init(cart: CuratedCart, dataStore: DataStore) {
        self.cart = cart
        self.dataStore = dataStore
        // Find the initial status of the cart from dataStore
        let initialStatus = dataStore.universalCarts.first(where: { $0.id == cart.id })?.status ?? .active
        self._currentStatus = State(initialValue: initialStatus)
    }
    
    var totalAmount: Double {
        cart.items.reduce(0) { total, item in
            let price = dataStore.products.first(where: { $0.id == item.productId })?.price ?? 0.0
            return total + (price * Double(item.quantity))
        }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header card
                VStack(spacing: 8) {
                    Text(cart.title)
                        .font(.system(.title3))
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.cream)
                    
                    Text(cart.description)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.cream.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    HStack(spacing: 6) {
                        Text("Status:")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.cream.opacity(0.7))
                        Text(currentStatus.rawValue.uppercased())
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.25), in: Capsule())
                            .foregroundStyle(statusColor)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(RSMSTheme.primaryGradient)
                
                // Items List
                ScrollView {
                    VStack(spacing: 16) {
                        if cart.items.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "cart.badge.questionmark")
                                    .font(.system(size: 48))
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Text("This cart is empty")
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(cart.items) { item in
                                let product = dataStore.products.first(where: { $0.id == item.productId })
                                
                                HStack(spacing: 16) {
                                    // Visual indicator
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(RSMSTheme.primary.opacity(0.08))
                                            .frame(width: 60, height: 60)
                                        Image(systemName: "gift.fill")
                                            .font(.title3)
                                            .foregroundStyle(RSMSTheme.primary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product?.name ?? "Unknown Product")
                                            .font(.system(.headline))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        
                                        Text("SKU: \(product?.sku ?? "N/A")")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                        
                                        if let itemNote = item.note, !itemNote.isEmpty {
                                            Text("Note: \(itemNote)")
                                                .font(.caption)
                                                .italic()
                                                .foregroundStyle(RSMSTheme.textSecondary)
                                                .padding(.top, 2)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("₹\(Int(product?.price ?? 0).formatted())")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        
                                        Text("Qty: \(item.quantity)")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                }
                                .padding()
                                .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(RSMSTheme.border, lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                // Bottom summary & Action
                VStack(spacing: 16) {
                    Divider()
                        .background(RSMSTheme.divider)
                    
                    HStack {
                        Text("Total Value")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Spacer()
                        Text("₹\(Int(totalAmount).formatted())")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(RSMSTheme.primary)
                    }
                    .padding(.horizontal, 24)
                    
                    if currentStatus == .active || currentStatus == .draft {
                        Button {
                            shareCart()
                        } label: {
                            HStack {
                                if isSharing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share with Client")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RSMSTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isSharing)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    } else if currentStatus == .shared {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Shared with Client")
                        }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.success)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RSMSTheme.success.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSTheme.success.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .background(RSMSTheme.surfacePrimary)
            }
        }
        .navigationTitle("Curated Cart Detail")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if shareSuccess {
                ToastView(message: "Shared successfully!")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                shareSuccess = false
                            }
                        }
                    }
            }
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
            return RSMSTheme.textTertiary
        }
    }
    
    private func shareCart() {
        guard let dbCart = dataStore.universalCarts.first(where: { $0.id == cart.id }) else { return }
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
                try await dataStore.updateUniversalCart(updated)
                await MainActor.run {
                    currentStatus = .shared
                    isSharing = false
                    withAnimation {
                        shareSuccess = true
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
