//
//  CertificatePreview.swift
//  RSMS
//

import SwiftUI

struct CertificatePreview: View {
    let certificateID: String
    let product: Product
    let serialNumber: String
    let date: Date
    let issuerName: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(RSMSTheme.gold)
                
                Text("Maison Lumière")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text("CERTIFICATE OF AUTHENTICITY")
                    .font(.caption.weight(.bold))
                    .tracking(4)
                    .foregroundStyle(RSMSTheme.gold)
            }
            .padding(.bottom, 16)
            
            // Body text
            VStack(spacing: 16) {
                Text("We hereby certify that the item described below is an authentic creation of Maison Lumière, subject to the most exacting quality controls.")
                    .font(.system(size: 14, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(.horizontal, 24)
                
                VStack(spacing: 8) {
                    certDetailRow(title: "Model", value: product.name)
                    certDetailRow(title: "Collection", value: product.collection ?? "N/A")
                    certDetailRow(title: "Serial Number", value: serialNumber)
                }
                .padding(20)
                .background(RSMSTheme.surfacePrimary)
                .border(RSMSTheme.gold.opacity(0.3), width: 1)
                .padding(.horizontal, 16)
            }
            
            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Certificate ID")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .textCase(.uppercase)
                    Text(certificateID)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Issued On")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .textCase(.uppercase)
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 24)
            
            Text("Authorized by: \(issuerName)")
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(RSMSTheme.textSecondary)
                .padding(.bottom, 24)
        }
        .padding(.top, 32)
        .background(RSMSTheme.background)
        .overlay(
            Rectangle()
                .stroke(RSMSTheme.gold, lineWidth: 2)
                .padding(8)
        )
        .overlay(
            Rectangle()
                .stroke(RSMSTheme.gold.opacity(0.3), lineWidth: 1)
                .padding(14)
        )
    }
    
    private func certDetailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(RSMSTheme.textTertiary)
                .textCase(.uppercase)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
    }
}
