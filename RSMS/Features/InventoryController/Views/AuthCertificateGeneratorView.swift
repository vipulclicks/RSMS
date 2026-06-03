//
//  AuthCertificateGeneratorView.swift
//  RSMS
//

import SwiftUI

struct AuthCertificateGeneratorView: View {
    @Environment(AppViewModel.self) private var appVM
    
    @State private var searchText = ""
    @State private var selectedProduct: Product?
    @State private var serialNumber = ""
    
    @State private var generatedCertificate: AuthCertificate?
    @State private var isGenerating = false
    @State private var showSuccess = false
    
    @MainActor
    private var renderedImage: Image? {
        guard let cert = generatedCertificate, let product = selectedProduct else { return nil }
        
        let view = CertificatePreview(
            certificateID: cert.id.uuidString,
            product: product,
            serialNumber: cert.serialNumber,
            date: cert.issuedAt,
            issuerName: appVM.currentUser?.fullName ?? "System"
        )
        .frame(width: 600, height: 800)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        
        if let cgImage = renderer.cgImage {
            return Image(cgImage, scale: 1.0, label: Text("Certificate"))
        }
        return nil
    }
    
    var searchResults: [Product] {
        guard !searchText.isEmpty else { return [] }
        return appVM.dataStore.products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sku.localizedCaseInsensitiveContains(searchText)
        }.prefix(5).map { $0 }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if generatedCertificate == nil {
                        formSection
                    } else {
                        previewSection
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Authenticity Certificates")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Generate Certificate")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Issue proof of originality for eligible products.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Product Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Product")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .textCase(.uppercase)
                
                if let product = selectedProduct {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text(product.sku)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            selectedProduct = nil
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                    .padding()
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.gold, lineWidth: 1))
                } else {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        TextField("Search by name or SKU", text: $searchText)
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    .padding()
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    if !searchResults.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchResults) { product in
                                Button {
                                    selectedProduct = product
                                } label: {
                                    HStack {
                                        Text(product.name)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Spacer()
                                        Text(product.sku)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    .padding()
                                    .background(RSMSTheme.surfacePrimary)
                                }
                                Divider()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            // Serial Number
            if selectedProduct != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Serial Number")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .textCase(.uppercase)
                    
                    TextField("Enter exact serial number", text: $serialNumber)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .padding()
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Generate Button
            Button {
                Task { await generateCertificate() }
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView().tint(RSMSTheme.cream)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Generate Certificate")
                    }
                }
                .font(.headline)
                .foregroundStyle(RSMSTheme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedProduct == nil || serialNumber.isEmpty ? RSMSTheme.textTertiary : RSMSTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedProduct == nil || serialNumber.isEmpty || isGenerating)
            .padding(.top, 12)
        }
    }
    
    private var previewSection: some View {
        VStack(spacing: 24) {
            if let cert = generatedCertificate, let product = selectedProduct {
                CertificatePreview(
                    certificateID: cert.id.uuidString,
                    product: product,
                    serialNumber: cert.serialNumber,
                    date: cert.issuedAt,
                    issuerName: appVM.currentUser?.fullName ?? "System"
                )
                .frame(maxWidth: 600)
                
                HStack(spacing: 16) {
                    Button {
                        // Reset
                        generatedCertificate = nil
                        selectedProduct = nil
                        serialNumber = ""
                        searchText = ""
                    } label: {
                        Text("Create Another")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    if let image = renderedImage {
                        ShareLink(
                            item: image,
                            preview: SharePreview("Authenticity Certificate", image: image)
                        ) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share / Print")
                            }
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSTheme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }
    
    private func generateCertificate() async {
        guard let product = selectedProduct, !serialNumber.isEmpty else { return }
        isGenerating = true
        
        let newCert = AuthCertificate(
            id: UUID(),
            productId: selectedProduct?.id ?? UUID(),
            serialNumber: serialNumber,
            certificateURL: nil,
            issuedAt: Date(),
            issuedBy: appVM.currentUser?.id ?? UUID()
        )
        
        do {
            let created = try await appVM.dataStore.createAuthCertificate(newCert)
            
            // Log audit
            if let storeId = appVM.currentUser?.storeId {
                let userId = appVM.currentUser?.id ?? UUID()
                let details = "Issued Auth Certificate for \(product.name) (SN: \(serialNumber))."
                appVM.dataStore.logAudit(storeId: storeId, action: "Certificate Issued", entityType: "AuthCertificate", entityId: created.id, performedBy: userId, details: details)
            }
            
            withAnimation {
                self.generatedCertificate = created
            }
        } catch {
            print("Error generating cert: \(error)")
        }
        
        isGenerating = false
    }
}
