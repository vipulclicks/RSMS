//
//  ClientSizePreferencesViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class ClientSizePreferencesViewModel {

    // MARK: - Form State (Shoes)
    var shoeSize: String = "39"
    var shoeFit: String = "Regular"

    // MARK: - Form State (Jewellery)
    var ringSize: String = "52"
    var braceletSize: String = "16 cm"
    var necklaceLength: String = "42 cm"
    var preferredMetal: String = "Rose Gold"
    var preferredGemstone: String = "Diamond"

    // MARK: - Form State (Watches)
    var wristSize: String = "15 cm"
    var watchCasePref: String = "36mm"
    var strapMaterial: String = "Metal"

    // MARK: - Form State (Handbags)
    var bagSize: String = "Medium"
    var bagStyle: String = "Crossbody"
    var bagMaterial: String = "Leather"

    // MARK: - Form State (Belts)
    var beltSize: String = "80"
    var bucklePref: String = "Gold Hardware"

    // MARK: - Form State (Perfumes)
    var fragranceFamily: String = "Floral"
    var fragranceStrength: String = "EDP"
    var scentPref: String = "Mild"

    // MARK: - Form State (General)
    var favoriteBrands: String = "Chanel, Cartier"
    var favoriteColors: String = "Beige, Navy, Burgundy"
    var shoppingPref: String = "VIP Appointment"
    var additionalNotes: String = "Prefers private viewing room. Champagne on arrival."

    // MARK: - UI State
    var showSuccessBanner: Bool = false

    // MARK: - Actions

    func savePreferences() async {
        // TODO: Replace with actual Supabase save call
        withAnimation(.spring(duration: 0.5)) {
            showSuccessBanner = true
        }
        try? await Task.sleep(for: .seconds(3))
        withAnimation(.spring(duration: 0.5)) {
            showSuccessBanner = false
        }
    }
}
