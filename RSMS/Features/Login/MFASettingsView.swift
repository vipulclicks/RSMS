//
//  MFASettingsView.swift
//  RSMS
//
//  Settings screen to manage MFA enrollment with Microsoft Authenticator.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct MFASettingsView: View {
    @State private var viewModel = MFASettingsViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: viewModel.hasVerifiedTOTPFactor ? "shield.fill" : "shield.slash.fill")
                        .font(.largeTitle)
                        .foregroundStyle(viewModel.hasVerifiedTOTPFactor ? AnyShapeStyle(RSMSTheme.success) : AnyShapeStyle(RSMSTheme.goldGradient))
                    
                    Text("Two-Factor Authentication")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    Text(viewModel.hasVerifiedTOTPFactor 
                         ? "Your account is protected by Microsoft Authenticator."
                         : "Add an extra layer of security to your account with Microsoft Authenticator.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.danger)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RSMSTheme.danger.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Main Content
                VStack(spacing: 24) {
                    if viewModel.isEnrolling, let data = viewModel.enrollmentData {
                        enrollmentContent(data: data)
                    } else if viewModel.hasVerifiedTOTPFactor {
                        enrolledContent
                    } else {
                        unenrolledContent
                    }
                }
                .padding(isCompact ? 24 : 32)
                .background(
                    RoundedRectangle(cornerRadius: isCompact ? 20 : 24)
                        .fill(RSMSTheme.surfacePrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: isCompact ? 20 : 24)
                                .stroke(RSMSTheme.gold.opacity(0.15), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
                .frame(maxWidth: 500)
                .padding(.horizontal, isCompact ? 16 : 0)
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFactors()
        }
        .onDisappear {
            if viewModel.isEnrolling {
                Task { await viewModel.cancelEnrollment() }
            }
        }
    }
    
    // MARK: - States
    
    private var unenrolledContent: some View {
        VStack(spacing: 24) {
            Button {
                Task { await viewModel.beginEnrollment() }
            } label: {
                HStack {
                    Spacer()
                    Text("Enable Two-Factor Auth")
                        .font(.headline.weight(.semibold))
                    Spacer()
                }
                .frame(minHeight: 50)
                .background(RSMSTheme.goldGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var enrolledContent: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Status")
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text("Active")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.success)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.success.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Divider().background(RSMSTheme.surfaceSecondary)
            
            Button(role: .destructive) {
                if let factor = viewModel.factors.first(where: { $0.factorType == "totp" }) {
                    Task { await viewModel.removeFactor(factor) }
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Disable Two-Factor Auth")
                        .font(.headline.weight(.semibold))
                    Spacer()
                }
                .frame(minHeight: 50)
                .background(RSMSTheme.danger.opacity(0.1))
                .foregroundColor(RSMSTheme.danger)
                .cornerRadius(12)
            }
        }
    }
    
    private func enrollmentContent(data: MFAEnrollResponse) -> some View {
        VStack(spacing: 24) {
            Text("1. Scan QR Code")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Open Microsoft Authenticator and scan this code:")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let qrImage = generateQRCode(from: data.totp.uri) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Or enter this secret manually:")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                HStack {
                    Text(data.totp.secret)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = data.totp.secret
                    } label: {
                        Image(systemName: "doc.on.doc").accessibilityLabel("Action")
                            .foregroundStyle(RSMSTheme.gold)
                    }
                }
                .padding()
                .background(RSMSTheme.surfaceSecondary)
                .cornerRadius(8)
            }
            
            Divider().padding(.vertical, 8)
            
            Text("2. Verify Code")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Image(systemName: "number")
                    .foregroundStyle(RSMSTheme.gold)
                    .frame(width: 24)
                TextField("6-Digit Code", text: $viewModel.verificationCode)
                    .keyboardType(.numberPad)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .font(.body)
                    .onChange(of: viewModel.verificationCode) { _, newValue in
                        viewModel.verificationCode = String(newValue.filter { $0.isNumber }.prefix(6))
                    }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(12)
            
            HStack(spacing: 16) {
                Button {
                    Task { await viewModel.cancelEnrollment() }
                } label: {
                    Text("Cancel")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(RSMSTheme.surfaceSecondary)
                        .foregroundColor(RSMSTheme.textPrimary)
                        .cornerRadius(12)
                }
                
                Button {
                    Task { await viewModel.confirmEnrollment() }
                } label: {
                    Text("Verify")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(RSMSTheme.goldGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(viewModel.verificationCode.count < 6)
                .opacity(viewModel.verificationCode.count < 6 ? 0.6 : 1.0)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // Scale up to make it sharp
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        MFASettingsView()
    }
}
