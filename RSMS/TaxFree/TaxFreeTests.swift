//
//  TaxFreeTests.swift
//  RSMS
//

import Foundation

public final class TaxFreeTests {
    
    public static func runAllTests() {
        print("[TaxFreeTests] 🧪 Running Tax-Free shopping suite...")
        
        testValidationService()
        testCalculationService()
        testReceiptGeneration()
        testEdgeCases()
        
        print("[TaxFreeTests] ✅ All tests passed successfully!")
    }
    
    private static func testValidationService() {
        // Valid passport check
        assert(TaxFreeValidationService.isValidPassport("A1234567"))
        assert(!TaxFreeValidationService.isValidPassport("A1")) // Too short
        assert(!TaxFreeValidationService.isValidPassport("A1234567890123456")) // Too long
        assert(!TaxFreeValidationService.isValidPassport("A1234@56")) // Special character
        
        // Eligibility check
        let config = TaxFreeConfig(
            storeId: UUID(),
            isEnabled: true,
            minPurchaseAmount: 50000,
            refundPercentage: 100,
            serviceFee: 0,
            eligibleCountries: ["United States", "United Kingdom"]
        )
        
        // Eligible: Different countries, amount >= min
        let isEligible = TaxFreeValidationService.evaluateEligibility(
            customerCountry: "United States",
            storeCountry: "India",
            transactionSubtotal: 60000,
            config: config
        )
        assert(isEligible)
        
        // Ineligible: Same store/customer country
        let sameCountry = TaxFreeValidationService.evaluateEligibility(
            customerCountry: "India",
            storeCountry: "India",
            transactionSubtotal: 60000,
            config: config
        )
        assert(!sameCountry)
        
        // Ineligible: Subtotal < min
        let belowMin = TaxFreeValidationService.evaluateEligibility(
            customerCountry: "United States",
            storeCountry: "India",
            transactionSubtotal: 40000,
            config: config
        )
        assert(!belowMin)
    }
    
    private static func testCalculationService() {
        // Basic Refund calculation
        let refund = TaxFreeService.calculateRefund(
            taxAmount: 10000,
            refundPercentage: 100,
            serviceFee: 0
        )
        assert(refund == 10000)
        
        // Fee deduction
        let refundWithFee = TaxFreeService.calculateRefund(
            taxAmount: 10000,
            refundPercentage: 100,
            serviceFee: 500
        )
        assert(refundWithFee == 9500)
        
        // Partial percentage
        let partialRefund = TaxFreeService.calculateRefund(
            taxAmount: 10000,
            refundPercentage: 80,
            serviceFee: 0
        )
        assert(partialRefund == 8000)
    }
    
    private static func testReceiptGeneration() {
        let txnId = UUID()
        let layout = TaxFreeReceiptGenerator.generateLayout(
            transactionId: txnId,
            passportNumber: "Z987654",
            countryOfResidence: "Canada",
            taxAmount: 5000,
            refundAmount: 5000
        )
        
        assert(layout.refNumber.hasPrefix("TF-"))
        assert(layout.passportNumber == "Z987654")
        assert(layout.country == "Canada")
        assert(layout.taxAmount == 5000)
        assert(layout.refundAmount == 5000)
        assert(layout.qrCodeContent.contains("Z987654"))
    }
    
    private static func testEdgeCases() {
        // Negative tax amount
        let negRefund = TaxFreeService.calculateRefund(
            taxAmount: -1000,
            refundPercentage: 100,
            serviceFee: 0
        )
        assert(negRefund == 0)
        
        // Exorbitant fee larger than refund value
        let excessFee = TaxFreeService.calculateRefund(
            taxAmount: 100,
            refundPercentage: 100,
            serviceFee: 500
        )
        assert(excessFee == 0)
    }
}
