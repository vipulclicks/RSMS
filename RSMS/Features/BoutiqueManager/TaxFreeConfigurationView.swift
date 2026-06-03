//
//  TaxFreeConfigurationView.swift
//  RSMS
//

import SwiftUI

struct TaxFreeConfigurationView: View {
    @Environment(AppViewModel.self) private var appVM
    
    @State private var isEnabled: Bool = true
    @State private var minPurchaseAmount: String = "10000"
    @State private var refundPercentage: String = "100"
    @State private var serviceFee: String = "0"
    @State private var selectedCountries: Set<String> = ["United States", "United Kingdom", "Canada"]
    @State private var showSuccessMessage = false
    @State private var isSaving = false
    
    private let availableCountries = ["United States", "United Kingdom", "Canada", "Singapore", "Japan", "France", "Germany", "India", "Australia", "Switzerland"]
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("Tax-Free Functionality").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                        Toggle("Enable Tax-Free Shopping", isOn: $isEnabled)
                            .tint(RSMSTheme.primary)
                    }
                    
                    if isEnabled {
                        Section(header: Text("Calculation Configurations").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                            HStack {
                                Text("Min. Purchase Amount (INR)")
                                Spacer()
                                TextField("Min. Purchase Amount", text: $minPurchaseAmount)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 150)
                            }
                            
                            HStack {
                                Text("Refund Percentage (%)")
                                Spacer()
                                TextField("Refund Percentage", text: $refundPercentage)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 150)
                            }
                            
                            HStack {
                                Text("Service Fee (INR)")
                                Spacer()
                                TextField("Service Fee", text: $serviceFee)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 150)
                            }
                        }
                        
                        Section(header: Text("Eligible Destination Countries").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                            ForEach(availableCountries, id: \.self) { country in
                                MultipleSelectionRow(title: country, isSelected: selectedCountries.contains(country)) {
                                    if selectedCountries.contains(country) {
                                        selectedCountries.remove(country)
                                    } else {
                                        selectedCountries.insert(country)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                
                VStack {
                    if showSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(RSMSTheme.success)
                            Text("Configuration saved successfully.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.success)
                        }
                        .padding(.bottom, 8)
                        .transition(.opacity)
                    }
                    
                    Button {
                        saveConfiguration()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Configuration")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSaving)
                }
                .padding(24)
                .background(RSMSTheme.surfacePrimary)
                .overlay(VStack { Divider(); Spacer() })
            }
        }
        .navigationTitle("Tax-Free Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        guard let storeId = appVM.currentUser?.storeId else { return }
        let config = appVM.dataStore.getTaxFreeConfig(for: storeId)
        
        self.isEnabled = config.isEnabled
        self.minPurchaseAmount = "\(Int(truncating: config.minPurchaseAmount as NSDecimalNumber))"
        self.refundPercentage = "\(Int(truncating: config.refundPercentage as NSDecimalNumber))"
        self.serviceFee = "\(Int(truncating: config.serviceFee as NSDecimalNumber))"
        self.selectedCountries = Set(config.eligibleCountries)
    }
    
    private func saveConfiguration() {
        guard let storeId = appVM.currentUser?.storeId else { return }
        isSaving = true
        showSuccessMessage = false
        
        let minAmt = Decimal(string: minPurchaseAmount) ?? 10000
        let refPct = Decimal(string: refundPercentage) ?? 100
        let fee = Decimal(string: serviceFee) ?? 0
        
        let config = TaxFreeConfig(
            storeId: storeId,
            isEnabled: isEnabled,
            minPurchaseAmount: minAmt,
            refundPercentage: refPct,
            serviceFee: fee,
            eligibleCountries: Array(selectedCountries)
        )
        
        Task {
            try? await appVM.dataStore.saveTaxFreeConfig(config)
            
            // Log action in audit logs
            let audit = TaxFreeAudit(
                userId: appVM.currentUser?.id ?? UUID(),
                action: "Updated tax-free configuration parameters"
            )
            try? await appVM.dataStore.createTaxFreeAudit(audit)
            
            withAnimation {
                showSuccessMessage = true
                isSaving = false
            }
            
            // Hide message after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showSuccessMessage = false
                }
            }
        }
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(RSMSTheme.primary)
                        .fontWeight(.bold)
                }
            }
        }
    }
}
