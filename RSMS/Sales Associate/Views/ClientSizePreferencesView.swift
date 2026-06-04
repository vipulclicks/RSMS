//
//  ClientSizePreferencesView.swift
//  RSMS
//
//  Created by SidMoon on 20/05/26.
//

import SwiftUI

struct ClientSizePreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ClientSizePreferencesViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            RSMSTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    VStack(spacing: 20) {
                        shoesSection
                        jewellerySection
                        watchesSection
                        handbagsSection
                        beltsSection
                        perfumesSection
                        preferencesSection
                    }
                    
                    saveButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
            
            if viewModel.showSuccessBanner {
                successBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .background(.ultraThinMaterial, in: Circle())
                    
                    Text("EC")
                        .font(.largeTitle.weight(.light))
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Eleanor Croft")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        Text("PLATINUM VIP")
                            .font(.caption2.weight(.bold))
                            .tracking(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RSMSTheme.primary.opacity(0.2))
                            .foregroundStyle(RSMSTheme.primary)
                            .clipShape(Capsule())
                    }
                    
                    Text("ID: CLI-8829-441")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    Text("Personalize recommendations with client preferences")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.primary)
                        .padding(.top, 4)
                }
                Spacer()
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Sections
    
    private var shoesSection: some View {
        LuxuryFormCard(title: "Shoes", icon: "shoe.fill") {
            HStack(spacing: 20) {
                LuxurySizeField(title: "Shoe Size", text: $viewModel.shoeSize, presets: LuxurySizePresets.shoes)
                LuxuryPicker(title: "Fit Preference", selection: $viewModel.shoeFit, options: ["Regular", "Wide", "Narrow"])
            }
        }
    }
    
    private var jewellerySection: some View {
        LuxuryFormCard(title: "Jewellery", icon: "sparkles") {
            HStack(spacing: 20) {
                LuxurySizeField(title: "Ring Size", text: $viewModel.ringSize, presets: LuxurySizePresets.rings)
                LuxurySizeField(title: "Bracelet Size", text: $viewModel.braceletSize, presets: LuxurySizePresets.bracelets)
            }
            LuxurySizeField(title: "Necklace Length", text: $viewModel.necklaceLength, presets: LuxurySizePresets.necklaces)
            
            HStack(spacing: 20) {
                LuxuryPicker(title: "Preferred Metal", selection: $viewModel.preferredMetal, options: ["Gold", "Platinum", "Silver", "Rose Gold"])
                LuxuryTextField(title: "Preferred Gemstone", text: $viewModel.preferredGemstone)
            }
        }
    }
    
    private var watchesSection: some View {
        LuxuryFormCard(title: "Watches & Accessories", icon: "applewatch") {
            HStack(spacing: 20) {
                LuxurySizeField(title: "Wrist Size", text: $viewModel.wristSize, presets: LuxurySizePresets.wristSizes)
                LuxuryTextField(title: "Case Preference", text: $viewModel.watchCasePref)
            }
            LuxuryPicker(title: "Strap Material", selection: $viewModel.strapMaterial, options: ["Leather", "Metal", "Rubber"])
        }
    }
    
    private var handbagsSection: some View {
        LuxuryFormCard(title: "Handbags", icon: "handbag.fill") {
            HStack(spacing: 20) {
                LuxuryPicker(title: "Preferred Size", selection: $viewModel.bagSize, options: ["Mini", "Small", "Medium", "Large"])
                LuxuryPicker(title: "Preferred Style", selection: $viewModel.bagStyle, options: ["Tote", "Crossbody", "Clutch", "Shoulder", "Satchel"])
            }
            LuxuryPicker(title: "Preferred Material", selection: $viewModel.bagMaterial, options: ["Leather", "Canvas", "Exotic"])
        }
    }
    
    private var beltsSection: some View {
        LuxuryFormCard(title: "Belts", icon: "figure.mixed.cardio") {
            HStack(spacing: 20) {
                LuxurySizeField(title: "Belt Size", text: $viewModel.beltSize, presets: LuxurySizePresets.belts)
                LuxuryTextField(title: "Buckle Preference", text: $viewModel.bucklePref)
            }
        }
    }
    
    private var perfumesSection: some View {
        LuxuryFormCard(title: "Perfumes", icon: "drop.fill") {
            HStack(spacing: 20) {
                LuxuryPicker(title: "Fragrance Family", selection: $viewModel.fragranceFamily, options: ["Woody", "Floral", "Oriental", "Citrus", "Fresh"])
                LuxuryPicker(title: "Strength", selection: $viewModel.fragranceStrength, options: ["EDT", "EDP", "Parfum"])
            }
            LuxuryPicker(title: "Scent Preference", selection: $viewModel.scentPref, options: ["Mild", "Strong", "Long-lasting"])
        }
    }
    
    private var preferencesSection: some View {
        LuxuryFormCard(title: "General Preferences", icon: "heart.fill") {
            LuxuryTextField(title: "Favorite Brands", text: $viewModel.favoriteBrands)
            LuxuryTextField(title: "Favorite Colors", text: $viewModel.favoriteColors)
            LuxuryPicker(title: "Shopping Preference", selection: $viewModel.shoppingPref, options: ["In-store", "Remote Selling", "VIP Appointment"])
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Notes")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                TextEditor(text: $viewModel.additionalNotes)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.savePreferences()
            }
        } label: {
            Text("Update Preferences")
                .font(.headline)
                .foregroundStyle(RSMSTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RSMSTheme.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 15, y: 5)
        }
        .padding(.top, 16)
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var successBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(RSMSTheme.primary)
                .font(.title3)
            Text("Client preferences updated successfully")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(RSMSTheme.primary.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.top, 16)
    }
}

#Preview {
    NavigationStack {
        ClientSizePreferencesView()
    }
}
