//
//  TaxFreeReceiptGenerator.swift
//  RSMS
//

import Foundation

public final class TaxFreeReceiptGenerator {
    
    public struct ReceiptLayoutData: Hashable {
        public let refNumber: String
        public let passportNumber: String
        public let country: String
        public let taxAmount: Decimal
        public let refundAmount: Decimal
        public let message: String
        
        public var qrCodeContent: String {
            // Standard Tax-Free validation format for customs scan
            return "TAXFREE-REF:\(refNumber)|PASS:\(passportNumber)|REFUND:\(refundAmount)"
        }
    }
    
    public static func generateLayout(
        transactionId: UUID,
        passportNumber: String,
        countryOfResidence: String,
        taxAmount: Decimal,
        refundAmount: Decimal
    ) -> ReceiptLayoutData {
        // Generate a standard pseudo-random reference code based on transaction ID
        let prefix = "TF"
        let shortId = transactionId.uuidString.prefix(8).uppercased()
        let refNumber = "\(prefix)-\(shortId)"
        
        let message = "TAX REFUND IS SUBJECT TO CUSTOMS VERIFICATION UPON DEPARTURE."
        
        return ReceiptLayoutData(
            refNumber: refNumber,
            passportNumber: passportNumber,
            country: countryOfResidence,
            taxAmount: taxAmount,
            refundAmount: refundAmount,
            message: message
        )
    }
}
