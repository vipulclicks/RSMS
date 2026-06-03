//
//  InventorySourcingRequestFormView.swift
//  RSMS
//

import SwiftUI

struct InventorySourcingRequestFormView: View {
    let product: Product
    
    @Environment(AppViewModel.self) private var appViewModel
    @State private var sourcingVM = InventorySourcingViewModel()
    @State private var quantity: Int = 1
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Product info card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(RSMSTheme.surfaceSecondary)
                                    .frame(width: 60, height: 60)
                                
                                if let urlString = product.imageURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        default:
                                            Image(systemName: product.categoryIconName)
                                                .font(.title2)
                                                .foregroundStyle(RSMSTheme.primary)
                                        }
                                    }
                                } else {
                                    Image(systemName: product.categoryIconName)
                                        .font(.title2)
                                        .foregroundStyle(RSMSTheme.primary)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text("SKU: \(product.sku)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Text(product.brand)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Price")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            Spacer()
                            Text(product.formattedPrice)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.primary)
                        }
                    }
                    .padding(20)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
                    
                    // Sourcing request fields
                    LuxuryFormCard(title: "Request Sourcing", icon: "shippingbox.and.arrow.backward") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Requested Quantity")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text("How many units do you need?")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 16) {
                                    Button {
                                        if quantity > 1 { quantity -= 1 }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    
                                    Text("\(quantity)")
                                        .font(.title3.bold())
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .frame(minWidth: 30)
                                    
                                    Button {
                                        quantity += 1
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Originating Store")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                let storeName = appViewModel.currentUser?.storeId.map { appViewModel.dataStore.storeName(for: $0) } ?? "Unknown Store"
                                Text(storeName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                        }
                    }
                    
                    if let error = sourcingVM.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(RSMSTheme.danger)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.danger)
                            Spacer()
                        }
                        .padding()
                        .background(RSMSTheme.danger.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        Task {
                            guard let associateId = appViewModel.currentUser?.id,
                                  let storeId = appViewModel.currentUser?.storeId else { return }
                            
                            await sourcingVM.submitRequest(
                                dataStore: appViewModel.dataStore,
                                productId: product.id,
                                productName: product.name,
                                quantity: quantity,
                                associateId: associateId,
                                storeId: storeId
                            )
                        }
                    } label: {
                        HStack {
                            if sourcingVM.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Submit Sourcing Request")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 10, y: 4)
                    }
                    .disabled(sourcingVM.isSubmitting)
                }
                .padding(24)
            }
        }
        .navigationTitle("Request From Another Store")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Request Submitted Successfully", isPresented: Bindable(sourcingVM).showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your request for \(quantity)x \(product.name) has been sent to the inventory controller.")
        }
    }
}
