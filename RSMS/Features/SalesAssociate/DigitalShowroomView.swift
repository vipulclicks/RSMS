//
//  DigitalShowroomView.swift
//  RSMS
//
//  A full-screen immersive catalog experience for the Sales Associate and client
//  to curate a luxury shopping cart.
//

import SwiftUI

struct DigitalShowroomView: View {
    @Bindable var viewModel: DigitalShowroomViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var showAdvancedFilters = false
    @State private var showShareToast = false
    @State private var navigateToCart = false
    
    // Grid columns based on device idiom
    private var columns: [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [
                GridItem(.flexible(), spacing: 24),
                GridItem(.flexible(), spacing: 24),
                GridItem(.flexible(), spacing: 24)
            ]
        } else {
            // Immersive vertical cards on iPhone
            return [GridItem(.flexible(), spacing: 16)]
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    showroomHeader
                        .padding(.top, 16)
                    
                    // Search & Filters Panel
                    searchAndFiltersSection
                    
                    // Product Catalog Grid
                    if viewModel.filteredCatalog.isEmpty {
                        emptyCatalogView
                    } else {
                        catalogGrid
                    }
                    
                    Spacer(minLength: 120) // Space for floating bar
                }
            }
            
            // Persistent Floating Bottom Bar
            if !viewModel.cartItems.isEmpty {
                floatingCartBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
            
            // Share success toast overlay
            if showShareToast {
                VStack {
                    Spacer()
                    ToastView(message: "Shared curated link successfully!")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 100)
                }
                .animation(.spring(), value: showShareToast)
            }
        }
        .navigationTitle("Digital Showroom")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.surfacePrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isSaving {
                    ProgressView().tint(RSMSTheme.primary)
                } else {
                    Button("Save") {
                        viewModel.isSaving = true
                        Task { await viewModel.saveShowroom() }
                    }
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.primary)
                    .disabled(viewModel.cartItems.isEmpty || viewModel.isSaving)
                }
            }
        }
        .sheet(item: $selectedProduct) { product in
            ShowroomProductDetailView(product: product, viewModel: viewModel)
        }
        .navigationDestination(isPresented: $navigateToCart) {
            ShowroomCartView(mode: .activeSession(viewModel: viewModel))
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your Curated Edit has been saved for \(viewModel.client.fullName).")
        }
    }
    
    // MARK: - Header
    private var showroomHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Client initials avatar
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.12))
                        .frame(width: 60, height: 60)
                    Text(viewModel.client.fullName.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Digital Showroom for")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    
                    Text(viewModel.client.fullName)
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Search & Filters Section
    private var searchAndFiltersSection: some View {
        VStack(spacing: 0) {
            // Category scroll chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(label: "All", isSelected: viewModel.selectedCategory == nil) {
                        viewModel.selectedCategory = nil
                    }
                    
                    ForEach(viewModel.categories, id: \.self) { category in
                        CategoryChip(label: category, isSelected: viewModel.selectedCategory == category) {
                            viewModel.selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Product Catalog Grid
    private var catalogGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Showroom Collection")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.filteredCatalog) { product in
                    ShowroomProductCard(
                        product: product,
                        isInCart: viewModel.cartItems.contains { $0.product.id == product.id },
                        stockQty: viewModel.stockQuantity(for: product.id),
                        onAdd: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                viewModel.toggleCartItem(product)
                            }
                        },
                        onDetail: {
                            selectedProduct = product
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyCatalogView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.textTertiary)
                .padding(.top, 40)
            Text("No products match filters")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Try clearing search or filters to see all catalog items.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Floating Bottom Bar
    private var floatingCartBar: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                Divider().overlay(RSMSTheme.divider)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.cartItems.count) Pieces Selected")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("₹\(Int(viewModel.totalValue).formatted())")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Share Button
                        Button {
                            showShareToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showShareToast = false
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.primary)
                                .frame(width: 40, height: 40)
                                .background(Color.white, in: Circle())
                                .overlay(Circle().stroke(RSMSTheme.primary, lineWidth: 1))
                        }
                        
                        // View Cart (pushed)
                        Button {
                            navigateToCart = true
                        } label: {
                            HStack(spacing: 6) {
                                Text("View Cart")
                                Image(systemName: "chevron.right")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(RSMSTheme.primaryGradient, in: Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Supporting Views

private struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : RSMSTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AnyShapeStyle(RSMSTheme.primaryGradient) : AnyShapeStyle(RSMSTheme.surfacePrimary),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1))
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : RSMSTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? RSMSTheme.primary : Color.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1))
        }
    }
}
