//
//  EditLayoutView.swift
//  RSMS
//

import SwiftUI

struct EditLayoutView: View {
    @Bindable var viewModel: PlanogramViewModel
    let zone: MerchandisingZone
    @State private var isShowingProductPicker = false
    @State private var productToSwap: StoreProduct? = nil
    @State private var selectedItemForSwap: StoreProduct? = nil
    @State private var selectedProductForDetail: StoreProduct? = nil
    @Environment(AppViewModel.self) private var appVM
    
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    
    // Luxury Colors
    private let backgroundGray = RSMSTheme.background
    private let textPrimary = RSMSTheme.textPrimary
    private let textSecondary = RSMSTheme.textSecondary
    private let badgeBg = RSMSTheme.surfacePrimary.opacity(0.2)
    private let shelfDropShadow = Color.black.opacity(0.08)
    
    // Grid layout for 4 items per shelf row
    let columns = Array(repeating: GridItem(.flexible(), spacing: 24), count: 4)
    
    var body: some View {
        ZStack {
            backgroundGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(zone.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(textPrimary)
                        Text("\(zone.items.count) items merchandised • Visual capacity: \(zone.fillPercentage)%")
                            .font(.system(size: 16))
                            .foregroundColor(textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            let storeId = appVM.currentStoreId ?? UUID()
                            do {
                                try await viewModel.saveLayout(storeId: storeId)
                                saveMessage = "Layout saved successfully!"
                                showingSaveAlert = true
                            } catch {
                                saveMessage = "Failed to save: \(error.localizedDescription)"
                                showingSaveAlert = true
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(RSMSTheme.primaryDark)
                                .clipShape(Capsule())
                        } else {
                            Text("Save Layout")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(RSMSTheme.primaryDark)
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 32)
                .alert("Save Layout", isPresented: $showingSaveAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(saveMessage)
                }
                
                if selectedItemForSwap != nil {
                    HStack {
                        Image(systemName: "arrow.2.squarepath")
                        Text("Choose 2nd item to swap")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSTheme.background)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(RSMSTheme.primaryDark)
                    .clipShape(Capsule())
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: selectedItemForSwap)
                }
                
                // Shelving Area
                ScrollView {
                    VStack(spacing: 60) {
                        let itemsPerRow = 4
                        let totalRows = max(1, Int((Double(zone.totalCapacity) / Double(itemsPerRow)).rounded(.up)))
                        
                        ForEach(0..<totalRows, id: \.self) { rowIndex in
                            let startIndex = rowIndex * itemsPerRow
                            let endIndex = min(startIndex + itemsPerRow, zone.totalCapacity)
                            let rowCapacity = endIndex - startIndex
                            
                            let rowItems: [StoreProduct?] = (0..<rowCapacity).map { i in
                                let itemIndex = startIndex + i
                                return itemIndex < zone.items.count ? zone.items[itemIndex] : nil
                            }
                            
                            shelfView(rowItems: rowItems)
                        }
                    }
                    .padding(40)
                    .background(RSMSTheme.surfacePrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(RSMSTheme.divider))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingProductPicker) {
            ProductPickerView(viewModel: viewModel, targetZone: zone, productToSwap: productToSwap)
                .onDisappear {
                    productToSwap = nil
                }
        }
        .sheet(item: $selectedProductForDetail) { product in
            PlanogramProductDetailSheet(product: product)
        }
    }
    
    // MARK: - Shelf Renderer
    private func shelfView(rowItems: [StoreProduct?]) -> some View {
        VStack(spacing: 0) {
            // Dotted Background
            ZStack {
                Canvas { context, size in
                    let spacing: CGFloat = 20
                    for x in stride(from: 0, to: size.width, by: spacing) {
                        for y in stride(from: 0, to: size.height, by: spacing) {
                            let rect = CGRect(x: x, y: y, width: 2, height: 2)
                            context.fill(Path(ellipseIn: rect), with: .color(Color.gray.opacity(0.2)))
                        }
                    }
                }
                
                // Products
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(Array(rowItems.enumerated()), id: \.offset) { _, item in
                        if let product = item {
                            productCard(product)
                        } else {
                            placeholderCard()
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24) // Lift items off the shelf line slightly
            }
            .frame(height: 280)
            
            // 3D Shelf Line - More Realistic
            ZStack(alignment: .top) {
                // Main shelf board (Darker gray/metallic look)
                Rectangle()
                    .fill(Color(white: 0.8))
                    .frame(height: 12)
                
                // Top edge highlight
                Rectangle()
                    .fill(Color(white: 0.95))
                    .frame(height: 2)
                
                // Bottom edge shadow/bevel
                Rectangle()
                    .fill(Color(white: 0.6))
                    .frame(height: 2)
                    .offset(y: 10)
                
                // Sharp drop shadow directly below the shelf
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(height: 8)
                    .offset(y: 12)
                    .blur(radius: 2)
            }
        }
    }
    
    // MARK: - Product Card
    private func productCard(_ product: StoreProduct) -> some View {
        VStack(spacing: 0) {
            // Image Area
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color(white: 0.97))
                    .overlay(
                        Group {
                            if product.imageName.starts(with: "http"), let urlString = product.imageName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else if phase.error != nil {
                                        Image(systemName: "photo").font(.system(size: 40)).foregroundColor(.gray)
                                    } else {
                                        ProgressView()
                                    }
                                }
                            } else {
                                Image(systemName: product.imageName.isEmpty ? "photo" : product.imageName)
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                    .clipped()
                
                // Top right actions
                HStack(spacing: 8) {
                    if product.isLowStock {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    }
                    
                    Menu {
                        Button(action: {
                            withAnimation {
                                selectedItemForSwap = product
                            }
                        }) {
                            Label("Swap Item", systemImage: "arrow.2.squarepath")
                        }
                        
                        Button(role: .destructive, action: {
                            viewModel.removeProduct(product, from: zone.id)
                        }) {
                            Label("Remove Item", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.black.opacity(0.4))
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(10)
            }
            .frame(height: 150)
            
            // Details Area
            VStack(spacing: 6) {
                Text(product.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(height: 40, alignment: .top)
                
                Text("SKU: \(product.sku)")
                    .font(.system(size: 12))
                    .foregroundColor(textSecondary)
                
                // Stock Badge
                Text(product.isLowStock ? "LOW STOCK: \(product.stockCount)" : "STOCK: \(product.stockCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(product.isLowStock ? .red : textSecondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(product.isLowStock ? Color.red.opacity(0.1) : badgeBg)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(RSMSTheme.surfacePrimary.opacity(0.2))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedItemForSwap?.id == product.id ? RSMSTheme.primaryDark : RSMSTheme.divider, 
                        lineWidth: selectedItemForSwap?.id == product.id ? 3 : 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        .onTapGesture {
            if let first = selectedItemForSwap {
                if first.id == product.id {
                    selectedItemForSwap = nil // Deselect
                } else {
                    withAnimation {
                        viewModel.swapProductsInZone(first.id, product.id, in: zone.id)
                    }
                    selectedItemForSwap = nil
                }
            } else {
                selectedProductForDetail = product
            }
        }
    }
    
    // MARK: - Placeholder
    private func placeholderCard() -> some View {
        Button(action: {
            isShowingProductPicker = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 24))
                Text("ADD ITEM")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
            }
            .foregroundColor(Color.gray.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundColor(Color.gray.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

struct PlanogramProductDetailSheet: View {
    let product: StoreProduct
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: product.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                    .padding(40)
                    .background(Color(white: 0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(spacing: 8) {
                    Text(product.name)
                        .font(.title2.bold())
                        .foregroundColor(RSMSTheme.textPrimary)
                    Text("SKU: \(product.sku)")
                        .foregroundColor(RSMSTheme.textSecondary)
                    
                    Text(product.isLowStock ? "Low Stock: \(product.stockCount) remaining" : "In Stock: \(product.stockCount) units")
                        .font(.headline)
                        .foregroundColor(product.isLowStock ? .red : RSMSTheme.textPrimary)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(RSMSTheme.primaryDark)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
