//
//  NewClientOnboardingViewModel.swift
//  RSMS
//
//  ViewModel for the New Client Onboarding sheet.
//  Manages form state, validation, and database operations.
//

import SwiftUI

struct NewAnniversaryInput: Identifiable, Hashable {
    var id = UUID()
    var title = "Birthday"
    var date = Date()
    var reminderEnabled = true
    var notes = ""
}

@Observable
final class NewClientOnboardingViewModel {

    var dataStore: DataStore?

    // MARK: - Form State — Identity
    var fullName = ""
    var email = ""
    var phone = ""
    var selectedTier: VIPTier = .standard
    var preferredStoreId: UUID?

    // MARK: - Form State — Sizing
    var shoeSize = ""
    var shoeFit = "Regular"
    var ringSize = ""
    var braceletSize = ""
    var necklaceLength = ""
    var wristSize = ""
    var watchCasePref = ""
    var strapMaterial = "Metal"
    var bagSize = "Medium"
    var bagStyle = "Crossbody"
    var bagMaterial = "Leather"
    var beltSize = ""
    var bucklePref = ""
    var fragranceFamily = "Floral"
    var fragranceStrength = "EDP"
    var scentPref = "Mild"

    // MARK: - Form State — General Preferences
    var favoriteBrands = ""
    var favoriteColors = ""
    var favoriteCategories = ""
    var favoriteMetals = ""
    var favoriteGemstones = ""
    var preferredMetal = ""
    var preferredGemstone = ""
    var stylePreference = "Classic"
    var shoppingPreference = "VIP Appointment"
    var notes = ""

    // MARK: - Form State — Important Dates (Anniversaries)
    var anniversaries: [NewAnniversaryInput] = []

    // MARK: - Form State — Wishlist
    var selectedProductIds: Set<UUID> = []
    var productNotes: [UUID: String] = [:]

    // MARK: - Form State — Consent & Channels
    var privacyConsentGiven = false
    var preferredEmail = false
    var preferredSMS = false
    var preferredPhone = false
    var preferredWhatsApp = false

    // MARK: - UI State
    var currentStep = 0
    var showValidationAlert = false
    var isSaving = false
    var showSuccessBanner = false

    static let stepTitles = ["Identity", "Preferences", "Special Dates", "Wishlist", "Privacy"]
    var stepCount: Int { Self.stepTitles.count }

    // MARK: - Validation

    var isFullNameValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canProceedFromStep: Bool {
        switch currentStep {
        case 0:  return isFullNameValid
        default: return true
        }
    }

    var isLastStep: Bool { currentStep == stepCount - 1 }

    // MARK: - Navigation

    func nextStep() {
        guard canProceedFromStep else {
            showValidationAlert = true
            return
        }
        if currentStep < stepCount - 1 {
            withAnimation(.spring(duration: 0.45)) {
                currentStep += 1
            }
        }
    }

    func previousStep() {
        if currentStep > 0 {
            withAnimation(.spring(duration: 0.45)) {
                currentStep -= 1
            }
        }
    }

    // MARK: - Wishlist Helpers
    func toggleProductSelection(_ productId: UUID) {
        if selectedProductIds.contains(productId) {
            selectedProductIds.remove(productId)
        } else {
            selectedProductIds.insert(productId)
        }
    }

    // MARK: - Save

    func saveClient() async {
        guard isFullNameValid, let store = dataStore else { return }
        isSaving = true

        let clientId = UUID()
        let now = Date()

        // 1. Build communication preferences summary
        var channels: [String] = []
        if preferredEmail { channels.append("Email") }
        if preferredSMS { channels.append("SMS") }
        if preferredPhone { channels.append("Phone Call") }
        if preferredWhatsApp { channels.append("WhatsApp") }

        let channelsStr = channels.isEmpty ? "None" : channels.joined(separator: ", ")
        let finalNotes = "Preferred Channels: \(channelsStr)\n" + notes

        // 2. Construct the ClientProfile
        let newClient = ClientProfile(
            id: clientId,
            fullName: fullName,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            preferredStoreId: preferredStoreId,
            vipTier: selectedTier,
            privacyConsentGiven: privacyConsentGiven,
            consentDate: privacyConsentGiven ? now : nil,
            notes: finalNotes.isEmpty ? nil : finalNotes,
            createdAt: now,
            updatedAt: now,
            
            // Sizes
            shoeSize: shoeSize.isEmpty ? nil : shoeSize,
            ringSize: ringSize.isEmpty ? nil : ringSize,
            braceletSize: braceletSize.isEmpty ? nil : braceletSize,
            necklaceLength: necklaceLength.isEmpty ? nil : necklaceLength,
            wristSize: wristSize.isEmpty ? nil : wristSize,
            beltSize: beltSize.isEmpty ? nil : beltSize,
            
            // Arrays
            favoriteCategories: splitCSV(favoriteCategories),
            favoriteMetals: splitCSV(favoriteMetals),
            favoriteGemstones: splitCSV(favoriteGemstones),
            
            // Detailed preferences
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
            giftingPreference: nil,
            shoppingPreference: shoppingPreference
        )

        // 3. Save Client Profile
        do {
            try await store.createClient(newClient)
        } catch {
            print("Supabase client insertion failed: \(error.localizedDescription). Falling back to optimistic local cache.")
            // Fallback to local mutation optimistically
            store.clients.append(newClient)
        }

        // 4. Save Anniversaries
        for input in anniversaries {
            let ann = ClientAnniversary(
                id: UUID(),
                clientId: clientId,
                title: input.title,
                date: input.date,
                reminderEnabled: input.reminderEnabled,
                notes: input.notes.isEmpty ? nil : input.notes
            )
            do {
                try await store.createClientAnniversary(ann)
            } catch {
                print("Supabase anniversary insertion failed: \(error.localizedDescription). Saving to local cache.")
                store.clientAnniversaries.append(ann)
            }
        }

        // 5. Save Wishlist Items
        for prodId in selectedProductIds {
            let wish = WishlistItem(
                id: UUID(),
                clientId: clientId,
                productId: prodId,
                addedAt: now,
                isAvailable: true,
                notifyOnRestock: true,
                notes: productNotes[prodId]?.isEmpty == false ? productNotes[prodId] : nil
            )
            do {
                try await store.createWishlistItem(wish)
            } catch {
                print("Supabase wishlist insertion failed: \(error.localizedDescription). Saving to local cache.")
                store.wishlistItems.append(wish)
            }
        }

        withAnimation(.spring(duration: 0.5)) {
            showSuccessBanner = true
        }
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation(.spring(duration: 0.5)) {
            showSuccessBanner = false
        }
        isSaving = false
    }

    // MARK: - Helpers

    private func splitCSV(_ text: String) -> [String]? {
        let items = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return items.isEmpty ? nil : items
    }
}
