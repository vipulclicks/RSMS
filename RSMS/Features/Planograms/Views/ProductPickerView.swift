//
//  ProductPickerView.swift
//  RSMS
//

import SwiftUI

struct ProductPickerView: View {
    @Bindable var viewModel: PlanogramViewModel
    let targetZone: MerchandisingZone
    var productToSwap: StoreProduct? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(viewModel.availableInventory) { product in
                HStack(spacing: 16) {
                    Group {
                        if product.imageName.starts(with: "http"), let urlString = product.imageName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else if phase.error != nil {
                                    Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray)
                                } else {
                                    ProgressView()
                                }
                            }
                        } else {
                            Image(systemName: product.imageName.isEmpty ? "photo" : product.imageName)
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .background(Color(white: 0.95))
                    .cornerRadius(8)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name).font(.headline)
                        Text("SKU: \(product.sku)").font(.subheadline).foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Stock: \(product.stockCount)")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(white: 0.92))
                        .clipShape(Capsule())
                        .foregroundColor(product.isLowStock ? .red : .primary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let oldProduct = productToSwap {
                        viewModel.swapProduct(oldProduct: oldProduct, newProduct: product, in: targetZone.id)
                    } else {
                        viewModel.addProduct(product, to: targetZone.id)
                    }
                    dismiss()
                }
            }
            .navigationTitle(productToSwap == nil ? "Add to \(targetZone.name)" : "Swap Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if viewModel.availableInventory.isEmpty {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                            .padding(.bottom, 8)
                        Text("All available inventory is merchandised.")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
