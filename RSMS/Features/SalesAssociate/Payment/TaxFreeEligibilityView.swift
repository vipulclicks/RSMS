//
//  TaxFreeEligibilityView.swift
//  RSMS
//

import SwiftUI

struct TaxFreeEligibilityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    let subtotal: Double
    let storeCountry: String
    let config: TaxFreeConfig
    
    @Binding var passportNumber: String
    @Binding var customerName: String
    @Binding var countryOfResidence: String
    @Binding var isEligible: Bool
    
    @State private var passportInput: String = ""
    @State private var nameInput: String = ""
    @State private var countryInput: String = ""
    @State private var validationChecked: Bool = false
    
    // Country picker items
    private let countriesList = ["United States", "United Kingdom", "Canada", "Singapore", "Japan", "France", "Germany", "India", "Australia", "Switzerland"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Form {
                        Section(header: Text("Customer Travel Information").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                            TextField("Full Name (as in Passport)", text: $nameInput)
                                .textContentType(.name)
                                .autocorrectionDisabled()
                                .foregroundStyle(RSMSTheme.textPrimary)
                            
                            TextField("Passport Number", text: $passportInput)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .foregroundStyle(RSMSTheme.textPrimary)
                            
                            Picker("Country of Residence", selection: $countryInput) {
                                Text("Select Country").tag("")
                                ForEach(countriesList, id: \.self) { country in
                                    Text(country).tag(country)
                                }
                            }
                            .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        .listRowBackground(RSMSTheme.surfacePrimary)
                        
                        if validationChecked {
                            Section(header: Text("Eligibility Result").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                                let eligible = evaluateEligibility()
                                if eligible {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(RSMSTheme.success)
                                                .font(.title3)
                                            Text("Eligible for Tax-Free Refund")
                                                .font(.headline)
                                                .foregroundStyle(RSMSTheme.success)
                                        }
                                        Text("Customer Country (\(countryInput)) matches rules. Transaction amount of ₹\(Int(subtotal).formatted()) meets the threshold of ₹\(Int(truncating: config.minPurchaseAmount as NSDecimalNumber).formatted()).")
                                            .font(.caption)
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "xmark.shield.fill")
                                                .foregroundStyle(RSMSTheme.danger)
                                                .font(.title3)
                                            Text("Not Eligible")
                                                .font(.headline)
                                                .foregroundStyle(RSMSTheme.danger)
                                        }
                                        
                                        if countryInput.lowercased() == storeCountry.lowercased() {
                                            Text("Customer country of residence matches store country (\(storeCountry)). Only non-resident travelers are eligible.")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.textSecondary)
                                        } else if Decimal(subtotal) < config.minPurchaseAmount {
                                            Text("Transaction amount of ₹\(Int(subtotal).formatted()) is below the minimum threshold of ₹\(Int(truncating: config.minPurchaseAmount as NSDecimalNumber).formatted()).")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.textSecondary)
                                        } else {
                                            Text("Travel documentation details or country format is invalid.")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.textSecondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .listRowBackground(RSMSTheme.surfacePrimary)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Tax-Free Eligibility")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RSMSTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Verify") {
                        if evaluateEligibility() {
                            passportNumber = passportInput
                            customerName = nameInput
                            countryOfResidence = countryInput
                            isEligible = true
                            dismiss()
                        } else {
                            withAnimation {
                                validationChecked = true
                            }
                        }
                    }
                    .disabled(!isInputFilled)
                    .foregroundStyle(isInputFilled ? RSMSTheme.primary : RSMSTheme.textTertiary)
                }
            }
            .onAppear {
                passportInput = passportNumber
                nameInput = customerName
                countryInput = countryOfResidence
                if !passportInput.isEmpty {
                    validationChecked = true
                }
            }
        }
    }
    
    private var isInputFilled: Bool {
        !nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        TaxFreeValidationService.isValidPassport(passportInput) &&
        !countryInput.isEmpty
    }
    
    private func evaluateEligibility() -> Bool {
        TaxFreeValidationService.evaluateEligibility(
            customerCountry: countryInput,
            storeCountry: storeCountry,
            transactionSubtotal: Decimal(subtotal),
            config: config
        )
    }
}
