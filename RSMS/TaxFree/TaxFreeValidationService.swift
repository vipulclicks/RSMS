//
//  TaxFreeValidationService.swift
//  RSMS
//

import Foundation

public final class TaxFreeValidationService {
    
    /// Validates the structure of a passport number.
    /// Standard passport validation matches alphanumeric strings of 6 to 15 characters.
    public static func isValidPassport(_ passport: String) -> Bool {
        let trimmed = passport.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 && trimmed.count <= 15 else { return false }
        
        let characterSet = CharacterSet.alphanumerics
        return trimmed.unicodeScalars.allSatisfy { characterSet.contains($0) }
    }
    
    /// Checks if the customer is eligible for a tax refund.
    /// Rules:
    /// 1. Configuration must be enabled.
    /// 2. Customer Country of Residence must not equal the Store Country.
    /// 3. The transaction subtotal must be greater than or equal to the minimum configuration purchase amount threshold.
    public static func evaluateEligibility(
        customerCountry: String,
        storeCountry: String,
        transactionSubtotal: Decimal,
        config: TaxFreeConfig
    ) -> Bool {
        guard config.isEnabled else { return false }
        
        // Country of Residence must be different from Store Country
        let normalizedCustomerCountry = customerCountry.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedStoreCountry = storeCountry.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedCustomerCountry.isEmpty && !normalizedStoreCountry.isEmpty else { return false }
        guard normalizedCustomerCountry != normalizedStoreCountry else { return false }
        
        // Purchase amount threshold
        guard transactionSubtotal >= config.minPurchaseAmount else { return false }
        
        // Optional country restriction (if configured eligible countries list is not empty)
        if !config.eligibleCountries.isEmpty {
            let lowercaseEligible = config.eligibleCountries.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            guard lowercaseEligible.contains(normalizedCustomerCountry) else { return false }
        }
        
        return true
    }
}
