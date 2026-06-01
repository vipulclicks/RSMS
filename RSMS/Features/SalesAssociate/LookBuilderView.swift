//
//  LookBuilderView.swift
//  RSMS
//
//  Visual outfit/look curation — create styled combinations
//  of products for clients with the Look Builder.
//

import SwiftUI

struct LookBuilderView: View {
    @State private var viewModel = LookBuilderViewModel()

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    outfitListSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Look Builder")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isShowingEditor) {
            LBOutfitEditorSheet(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            SectionHeader(
                title: "Styled Looks",
                subtitle: "Create curated product combinations for clients"
            )
            Spacer()
            Button {
                viewModel.startNewOutfit()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(RSMSTheme.primary)
            }
            .accessibilityLabel("Create New Look")
        }
        .padding(.top, 12)
    }

    // MARK: - Outfit List

    private var outfitListSection: some View {
        VStack(spacing: 16) {
            if viewModel.outfits.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 48))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("No Looks Created")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Create your first styled look by tapping the + button.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(viewModel.outfits) { outfit in
                    LBOutfitCard(outfit: outfit, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Outfit Card

private struct LBOutfitCard: View {
    let outfit: LookBuilderOutfit
    let viewModel: LookBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(viewModel.clientName(for: outfit.clientId))
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                StatusBadge(
                    text: "\(outfit.productIds.count) items",
                    color: RSMSTheme.info
                )
            }

            // Product chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(outfit.productIds, id: \.self) { productId in
                        if let product = viewModel.product(by: productId) {
                            LBProductChip(product: product)
                        }
                    }
                }
            }

            if let notes = outfit.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .lineLimit(2)
            }

            HStack {
                Text("Created \(outfit.createdAt, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)

                Spacer()

                Button {
                    viewModel.startEditing(outfit)
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Edit \(outfit.name)")
            }
        }
        .rsmsCard()
    }
}

// MARK: - Product Chip (in outfit card)

private struct LBProductChip: View {
    let product: Product

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 8))
                .foregroundStyle(RSMSTheme.primary)
            Text(product.name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .lineLimit(1)
            Text("₹\(Int(product.price).formatted())")
                .font(.caption2.weight(.bold))
                .foregroundStyle(RSMSTheme.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RSMSTheme.surfacePrimary, in: Capsule())
        .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
    }
}

// MARK: - Outfit Editor Sheet

private struct LBOutfitEditorSheet: View {
    @Bindable var viewModel: LookBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Details card
                        LuxuryFormCard(title: "Look Details", icon: "tshirt.fill") {
                            LuxuryTextField(title: "Look Name *", text: $viewModel.outfitName)

                            LuxuryPicker(
                                title: "Client",
                                selection: Binding(
                                    get: {
                                        viewModel.selectedClientId.flatMap { id in
                                            viewModel.clients.first { $0.id == id }?.fullName
                                        } ?? ""
                                    },
                                    set: { name in
                                        viewModel.selectedClientId = viewModel.clients.first { $0.fullName == name }?.id
                                    }
                                ),
                                options: viewModel.clients.map(\.fullName)
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                TextEditor(text: $viewModel.outfitNotes)
                                    .frame(height: 60)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(RSMSTheme.border, lineWidth: 1))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                        }

                        // Selected products
                        LuxuryFormCard(title: "Selected Products (\(viewModel.selectedProductIds.count))", icon: "checkmark.circle.fill") {
                            if viewModel.selectedProducts.isEmpty {
                                Text("No products selected. Tap products below to add.")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            } else {
                                ForEach(viewModel.selectedProducts) { product in
                                    HStack(spacing: 10) {
                                        Image(systemName: "diamond.fill")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.primary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(product.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(RSMSTheme.textPrimary)
                                            Text("₹\(Int(product.price).formatted())")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(RSMSTheme.primary)
                                        }
                                        Spacer()
                                        Button {
                                            viewModel.toggleProduct(product.id)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(RSMSTheme.danger.opacity(0.6))
                                        }
                                        .accessibilityLabel("Remove \(product.name)")
                                    }
                                    if product.id != viewModel.selectedProducts.last?.id {
                                        Divider().overlay(RSMSTheme.divider)
                                    }
                                }
                            }
                        }

                        // Product picker
                        LuxuryFormCard(title: "Add Products", icon: "magnifyingglass") {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                TextField("Search products…", text: $viewModel.searchQuery)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RSMSTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            ForEach(viewModel.filteredProducts.prefix(8)) { product in
                                Button {
                                    viewModel.toggleProduct(product.id)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: viewModel.selectedProductIds.contains(product.id)
                                              ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(viewModel.selectedProductIds.contains(product.id)
                                                             ? RSMSTheme.primary : RSMSTheme.textTertiary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(product.name)
                                                .font(.subheadline)
                                                .foregroundStyle(RSMSTheme.textPrimary)
                                            Text("\(product.category) · \(product.sku)")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.textTertiary)
                                        }
                                        Spacer()
                                        Text("₹\(Int(product.price).formatted())")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(RSMSTheme.primary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Save button
                        Button {
                            viewModel.saveOutfit()
                        } label: {
                            Text(viewModel.editingOutfit != nil ? "Update Look" : "Create Look")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.cream)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.canSaveOutfit
                                             ? AnyShapeStyle(RSMSTheme.primaryGradient)
                                             : AnyShapeStyle(RSMSTheme.surfaceSecondary))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: viewModel.canSaveOutfit
                                        ? RSMSTheme.primary.opacity(0.3) : .clear,
                                        radius: 12, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(!viewModel.canSaveOutfit)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(viewModel.editingOutfit != nil ? "Edit Look" : "New Look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LookBuilderView()
    }
}
