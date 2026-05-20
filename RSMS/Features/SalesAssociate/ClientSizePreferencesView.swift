//
//  ClientSizePreferencesView.swift
//  RSMS
//
//  Created by SidMoon on 20/05/26.
//

import SwiftUI

struct ClientSizePreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessBanner = false
    
    // Form State
    @State private var shoeSize = "39"
    @State private var shoeFit = "Regular"
    
    @State private var ringSize = "52"
    @State private var braceletSize = "16 cm"
    @State private var necklaceLength = "42 cm"
    @State private var preferredMetal = "Rose Gold"
    @State private var preferredGemstone = "Diamond"
    
    @State private var wristSize = "15 cm"
    @State private var watchCasePref = "36mm"
    @State private var strapMaterial = "Metal"
    
    @State private var bagSize = "Medium"
    @State private var bagStyle = "Crossbody"
    @State private var bagMaterial = "Leather"
    
    @State private var beltSize = "80"
    @State private var bucklePref = "Gold Hardware"
    
    @State private var fragranceFamily = "Floral"
    @State private var fragranceStrength = "EDP"
    @State private var scentPref = "Mild"
    
    @State private var favoriteBrands = "Chanel, Cartier"
    @State private var favoriteColors = "Beige, Navy, Burgundy"
    @State private var shoppingPref = "VIP Appointment"
    @State private var additionalNotes = "Prefers private viewing room. Champagne on arrival."



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
            
            if showSuccessBanner {
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
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Eleanor Croft")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        Text("PLATINUM VIP")
                            .font(.system(size: 10, weight: .bold))
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
        luxuryCard(title: "Shoes", icon: "shoe.fill") {
            HStack(spacing: 20) {
                luxuryTextField(title: "Shoe Size", text: $shoeSize)
                luxuryPicker(title: "Fit Preference", selection: $shoeFit, options: ["Regular", "Wide", "Narrow"])
            }
        }
    }
    
    private var jewellerySection: some View {
        luxuryCard(title: "Jewellery", icon: "sparkles") {
            HStack(spacing: 20) {
                luxuryTextField(title: "Ring Size", text: $ringSize)
                luxuryTextField(title: "Bracelet Size", text: $braceletSize)
            }
            luxuryTextField(title: "Necklace Length", text: $necklaceLength)
            
            HStack(spacing: 20) {
                luxuryPicker(title: "Preferred Metal", selection: $preferredMetal, options: ["Gold", "Platinum", "Silver", "Rose Gold"])
                luxuryTextField(title: "Preferred Gemstone", text: $preferredGemstone)
            }
        }
    }
    
    private var watchesSection: some View {
        luxuryCard(title: "Watches & Accessories", icon: "applewatch") {
            HStack(spacing: 20) {
                luxuryTextField(title: "Wrist Size", text: $wristSize)
                luxuryTextField(title: "Case Preference", text: $watchCasePref)
            }
            luxuryPicker(title: "Strap Material", selection: $strapMaterial, options: ["Leather", "Metal", "Rubber"])
        }
    }
    
    private var handbagsSection: some View {
        luxuryCard(title: "Handbags", icon: "handbag.fill") {
            HStack(spacing: 20) {
                luxuryPicker(title: "Preferred Size", selection: $bagSize, options: ["Mini", "Small", "Medium", "Large"])
                luxuryPicker(title: "Preferred Style", selection: $bagStyle, options: ["Tote", "Crossbody", "Clutch", "Shoulder", "Satchel"])
            }
            luxuryPicker(title: "Preferred Material", selection: $bagMaterial, options: ["Leather", "Canvas", "Exotic"])
        }
    }
    
    private var beltsSection: some View {
        luxuryCard(title: "Belts", icon: "figure.mixed.cardio") { // Using generic icon as placeholder
            HStack(spacing: 20) {
                luxuryTextField(title: "Belt Size", text: $beltSize)
                luxuryTextField(title: "Buckle Preference", text: $bucklePref)
            }
        }
    }
    
    private var perfumesSection: some View {
        luxuryCard(title: "Perfumes", icon: "drop.fill") {
            HStack(spacing: 20) {
                luxuryPicker(title: "Fragrance Family", selection: $fragranceFamily, options: ["Woody", "Floral", "Oriental", "Citrus", "Fresh"])
                luxuryPicker(title: "Strength", selection: $fragranceStrength, options: ["EDT", "EDP", "Parfum"])
            }
            luxuryPicker(title: "Scent Preference", selection: $scentPref, options: ["Mild", "Strong", "Long-lasting"])
        }
    }
    
    private var preferencesSection: some View {
        luxuryCard(title: "General Preferences", icon: "heart.fill") {
            luxuryTextField(title: "Favorite Brands", text: $favoriteBrands)
            luxuryTextField(title: "Favorite Colors", text: $favoriteColors)
            luxuryPicker(title: "Shopping Preference", selection: $shoppingPref, options: ["In-store", "Remote Selling", "VIP Appointment"])
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Notes")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                TextEditor(text: $additionalNotes)
                    .frame(height: 80)
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
            savePreferences()
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
    
    // MARK: - Reusable UI Components
    
    private func luxuryCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(RSMSTheme.primary)
                Text(title.uppercased())
                    .font(.subheadline.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding(.bottom, 4)
            
            content()
        }
        .padding(24)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }
    
    private func luxuryTextField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            TextField("", text: text)
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(RSMSTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
        }
    }
    
    private func luxuryPicker(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection.wrappedValue = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? "Select" : selection.wrappedValue)
                        .foregroundStyle(selection.wrappedValue.isEmpty ? RSMSTheme.textSecondary : RSMSTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(RSMSTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
            }
        }
    }
    
    // MARK: - Actions
    
    private func savePreferences() {
        withAnimation(.spring(duration: 0.5)) {
            showSuccessBanner = true
        }
        
        // Hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring(duration: 0.5)) {
                showSuccessBanner = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClientSizePreferencesView()
    }
}
