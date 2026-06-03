//
//  MFAVerificationView.swift
//  RSMS
//
//  TOTP entry screen shown during login.
//

import SwiftUI

struct MFAVerificationView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var code = ""
    @State private var appeared = false
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            // Background Decoration
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.04))
                    .frame(width: isCompact ? 400 : 600, height: isCompact ? 400 : 600)
                    .offset(x: isCompact ? -150 : -200, y: isCompact ? -200 : -300)
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.03))
                    .frame(width: isCompact ? 300 : 400, height: isCompact ? 300 : 400)
                    .offset(x: isCompact ? 150 : 300, y: isCompact ? 150 : 200)
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: isCompact ? 60 : 100)
                    
                    // Icon
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: isCompact ? 48 : 64))
                        .foregroundStyle(RSMSTheme.goldGradient)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -20)
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Two-Factor Authentication")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        Text("Enter the 6-digit code from Microsoft Authenticator to continue.")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    
                    // Content Card
                    VStack(spacing: 24) {
                        if let error = viewModel.mfaError {
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
                        }
                        
                        // Code Input
                        HStack {
                            Image(systemName: "number")
                                .foregroundStyle(RSMSTheme.gold)
                                .frame(width: 24)
                            TextField("6-Digit Code", text: $code)
                                .keyboardType(.numberPad)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .font(.body)
                                .onChange(of: code) { _, newValue in
                                    code = String(newValue.filter { $0.isNumber }.prefix(6))
                                }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(RSMSTheme.surfaceSecondary)
                        .cornerRadius(12)
                        
                        // Verify Button
                        Button {
                            Task { await viewModel.verifyMFA(code: code) }
                        } label: {
                            HStack {
                                Spacer()
                                if viewModel.isMFAVerifying {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Verify")
                                        .font(.headline.weight(.semibold))
                                }
                                Spacer()
                            }
                            .frame(height: 50)
                            .background(RSMSTheme.goldGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(code.count < 6 || viewModel.isMFAVerifying)
                        .opacity(code.count < 6 ? 0.6 : 1.0)
                        
                        // Cancel
                        Button {
                            viewModel.cancelMFA()
                        } label: {
                            Text("Use a different account")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RSMSTheme.gold)
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
                    .shadow(color: Color.black.opacity(0.15), radius: isCompact ? 20 : 30, y: isCompact ? 10 : 15)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, isCompact ? 24 : 0)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

#Preview {
    MFAVerificationView()
        .environment(AppViewModel())
}
