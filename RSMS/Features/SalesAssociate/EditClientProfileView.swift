// EditClientProfileView.swift
import SwiftUI

struct EditClientProfileView: View {
    let client: ClientProfile
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var vipTier: VIPTier = .standard
    
    // Sizing
    @State private var shoeSize: String = ""
    @State private var shoeFit: String = ""
    @State private var ringSize: String = ""
    @State private var braceletSize: String = ""
    @State private var necklaceLength: String = ""
    @State private var wristSize: String = ""
    @State private var beltSize: String = ""
    
    // Preferences & Interests
    @State private var favoriteCategories: String = ""
    @State private var favoriteMetals: String = ""
    @State private var favoriteGemstones: String = ""
    @State private var favoriteBrands: String = ""
    @State private var favoriteColors: String = ""
    
    // Detailed preferences
    @State private var preferredMetal: String = ""
    @State private var preferredGemstone: String = ""
    @State private var watchCasePref: String = ""
    @State private var strapMaterial: String = ""
    @State private var bagSize: String = ""
    @State private var bagStyle: String = ""
    @State private var bagMaterial: String = ""
    @State private var bucklePref: String = ""
    @State private var fragranceFamily: String = ""
    @State private var fragranceStrength: String = ""
    @State private var scentPref: String = ""
    @State private var stylePreference: String = ""
    @State private var shoppingPreference: String = ""
    
    @State private var notes: String = ""
    @State private var privacyConsentGiven: Bool = false
    
    @State private var isSaving = false
    @State private var showValidationAlert = false

    init(client: ClientProfile, dataStore: DataStore) {
        self.client = client
        self.dataStore = dataStore
        
        self._fullName = State(initialValue: client.fullName)
        self._email = State(initialValue: client.email ?? "")
        self._phone = State(initialValue: client.phone ?? "")
        self._vipTier = State(initialValue: client.vipTier)
        
        self._shoeSize = State(initialValue: client.shoeSize ?? "")
        self._shoeFit = State(initialValue: client.shoeFitPreference ?? "Regular")
        self._ringSize = State(initialValue: client.ringSize ?? "")
        self._braceletSize = State(initialValue: client.braceletSize ?? "")
        self._necklaceLength = State(initialValue: client.necklaceLength ?? "")
        self._wristSize = State(initialValue: client.wristSize ?? "")
        self._beltSize = State(initialValue: client.beltSize ?? "")
        
        self._favoriteCategories = State(initialValue: client.favoriteCategories?.joined(separator: ", ") ?? "")
        self._favoriteMetals = State(initialValue: client.favoriteMetals?.joined(separator: ", ") ?? "")
        self._favoriteGemstones = State(initialValue: client.favoriteGemstones?.joined(separator: ", ") ?? "")
        self._favoriteBrands = State(initialValue: client.preferredBrands ?? "")
        self._favoriteColors = State(initialValue: client.favoriteColors ?? "")
        
        self._preferredMetal = State(initialValue: client.preferredMetal ?? "")
        self._preferredGemstone = State(initialValue: client.preferredGemstone ?? "")
        self._watchCasePref = State(initialValue: client.watchCasePreference ?? "")
        self._strapMaterial = State(initialValue: client.strapMaterialPreference ?? "Metal")
        self._bagSize = State(initialValue: client.preferredBagSize ?? "Medium")
        self._bagStyle = State(initialValue: client.preferredBagStyle ?? "Crossbody")
        self._bagMaterial = State(initialValue: client.preferredMaterial ?? "Leather")
        self._bucklePref = State(initialValue: client.bucklePreference ?? "")
        self._fragranceFamily = State(initialValue: client.fragranceFamily ?? "Floral")
        self._fragranceStrength = State(initialValue: client.fragranceStrength ?? "EDP")
        self._scentPref = State(initialValue: client.scentPreference ?? "Mild")
        self._stylePreference = State(initialValue: client.stylePreference ?? "Classic")
        self._shoppingPreference = State(initialValue: client.shoppingPreference ?? "VIP Appointment")
        
        self._notes = State(initialValue: client.notes ?? "")
        self._privacyConsentGiven = State(initialValue: client.privacyConsentGiven)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Identity
                        LuxuryFormCard(title: "Client Identity", icon: "person.fill") {
                            LuxuryTextField(title: "Full Name *", text: $fullName)
                            LuxuryTextField(title: "Email", text: $email)
                            LuxuryTextField(title: "Phone", text: $phone)
                            
                            // VIP Tier Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("VIP Tier")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Picker("VIP Tier", selection: $vipTier) {
                                    ForEach(VIPTier.allCases, id: \.self) { tier in
                                        Text(tier.rawValue.uppercased()).tag(tier)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // 2. Sizes
                        LuxuryFormCard(title: "Shoes & Belts", icon: "shoe.fill") {
                            HStack(spacing: 12) {
                                LuxurySizeField(title: "Shoe Size", text: $shoeSize, presets: LuxurySizePresets.shoes)
                                LuxuryPicker(title: "Shoe Fit", selection: $shoeFit, options: ["Regular", "Wide", "Narrow"])
                            }
                            HStack(spacing: 12) {
                                LuxurySizeField(title: "Belt Size", text: $beltSize, presets: LuxurySizePresets.belts)
                                LuxuryTextField(title: "Buckle Pref", text: $bucklePref)
                            }
                        }
                        
                        // 3. Jewelry & Watches
                        LuxuryFormCard(title: "Jewellery & Watches", icon: "sparkles") {
                            HStack(spacing: 12) {
                                LuxurySizeField(title: "Ring Size", text: $ringSize, presets: LuxurySizePresets.rings)
                                LuxurySizeField(title: "Bracelet Size", text: $braceletSize, presets: LuxurySizePresets.bracelets)
                            }
                            HStack(spacing: 12) {
                                LuxurySizeField(title: "Necklace Length", text: $necklaceLength, presets: LuxurySizePresets.necklaces)
                                LuxurySizeField(title: "Wrist Size", text: $wristSize, presets: LuxurySizePresets.wristSizes)
                            }
                            HStack(spacing: 12) {
                                LuxuryPicker(title: "Preferred Metal", selection: $preferredMetal, options: ["", "Gold", "Platinum", "Silver", "Rose Gold"])
                                LuxuryPicker(title: "Strap Material", selection: $strapMaterial, options: ["Metal", "Leather", "Rubber"])
                            }
                            LuxuryTextField(title: "Watch Case Preference", text: $watchCasePref)
                        }
                        
                        // 4. Bags & Perfumes
                        LuxuryFormCard(title: "Handbags & Perfumes", icon: "handbag.fill") {
                            HStack(spacing: 12) {
                                LuxuryPicker(title: "Bag Size", selection: $bagSize, options: ["Mini", "Small", "Medium", "Large"])
                                LuxuryPicker(title: "Bag Style", selection: $bagStyle, options: ["Tote", "Crossbody", "Clutch", "Shoulder", "Satchel"])
                            }
                            HStack(spacing: 12) {
                                LuxuryPicker(title: "Bag Material", selection: $bagMaterial, options: ["Leather", "Canvas", "Exotic"])
                                LuxuryPicker(title: "Fragrance Family", selection: $fragranceFamily, options: ["Woody", "Floral", "Oriental", "Citrus", "Fresh"])
                            }
                            HStack(spacing: 12) {
                                LuxuryPicker(title: "Fragrance Strength", selection: $fragranceStrength, options: ["EDT", "EDP", "Parfum"])
                                LuxuryPicker(title: "Scent Preference", selection: $scentPref, options: ["Mild", "Strong", "Long-lasting"])
                            }
                        }
                        
                        // 5. Style & Interests
                        LuxuryFormCard(title: "Style & Brands", icon: "heart.fill") {
                            LuxuryTextField(title: "Favourite Categories (comma-separated)", text: $favoriteCategories)
                            LuxuryTextField(title: "Favourite Metals (comma-separated)", text: $favoriteMetals)
                            LuxuryTextField(title: "Favourite Gemstones (comma-separated)", text: $favoriteGemstones)
                            LuxuryTextField(title: "Favourite Brands", text: $favoriteBrands)
                            LuxuryTextField(title: "Favourite Colors", text: $favoriteColors)
                            HStack(spacing: 12) {
                                LuxuryPicker(title: "Style", selection: $stylePreference, options: ["Classic", "Modern", "Sporty Luxury", "Bohemian", "Minimalist"])
                                LuxuryPicker(title: "Shopping", selection: $shoppingPreference, options: ["VIP Appointment", "Online Assisted", "Walk-in"])
                            }
                        }
                        
                        // 6. Notes & Consent
                        LuxuryFormCard(title: "Associate Notes & Consent", icon: "note.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Associate Notes")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(RSMSTheme.border, lineWidth: 1)
                                    )
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            
                            Toggle("Privacy Consent Given", isOn: $privacyConsentGiven)
                                .tint(RSMSTheme.primary)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RSMSTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveClient()
                    }
                    .font(.headline)
                    .foregroundStyle(fullName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : RSMSTheme.primary)
                    .disabled(fullName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .alert("Missing Name", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Full Name is a required field.")
            }
        }
    }
    
    private func saveClient() {
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            showValidationAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            let updatedClient = ClientProfile(
                id: client.id,
                fullName: fullName,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                preferredStoreId: client.preferredStoreId,
                vipTier: vipTier,
                privacyConsentGiven: privacyConsentGiven,
                consentDate: privacyConsentGiven ? (client.consentDate ?? Date()) : nil,
                notes: notes.isEmpty ? nil : notes,
                createdAt: client.createdAt,
                updatedAt: Date(),
                
                shoeSize: shoeSize.isEmpty ? nil : shoeSize,
                ringSize: ringSize.isEmpty ? nil : ringSize,
                braceletSize: braceletSize.isEmpty ? nil : braceletSize,
                necklaceLength: necklaceLength.isEmpty ? nil : necklaceLength,
                wristSize: wristSize.isEmpty ? nil : wristSize,
                beltSize: beltSize.isEmpty ? nil : beltSize,
                
                favoriteCategories: splitCSV(favoriteCategories),
                favoriteMetals: splitCSV(favoriteMetals),
                favoriteGemstones: splitCSV(favoriteGemstones),
                
                shoeFitPreference: shoeFit,
                preferredMetal: preferredMetal.isEmpty ? nil : preferredMetal,
                preferredGemstone: preferredGemstone.isEmpty ? nil : preferredGemstone,
                watchCasePreference: watchCasePref.isEmpty ? nil : watchCasePref,
                strapMaterialPreference: strapMaterial,
                preferredBagSize: bagSize,
                preferredBagStyle: bagStyle,
                preferredMaterial: bagMaterial,
                bucklePreference: bucklePref.isEmpty ? nil : bucklePref,
                fragranceFamily: fragranceFamily,
                fragranceStrength: fragranceStrength,
                scentPreference: scentPref,
                preferredBrands: favoriteBrands.isEmpty ? nil : favoriteBrands,
                favoriteColors: favoriteColors.isEmpty ? nil : favoriteColors,
                stylePreference: stylePreference,
                giftingPreference: client.giftingPreference,
                shoppingPreference: shoppingPreference
            )
            
            do {
                try await dataStore.updateClient(updatedClient)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("Failed to save client: \(error.localizedDescription)")
                await MainActor.run {
                    if let idx = dataStore.clients.firstIndex(where: { $0.id == client.id }) {
                        dataStore.clients[idx] = updatedClient
                    }
                    isSaving = false
                    dismiss()
                }
            }
        }
    }
    
    private func splitCSV(_ text: String) -> [String]? {
        let items = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return items.isEmpty ? nil : items
    }
}
