//
//  TaxFreeService.swift
//  RSMS
//

import Foundation

public final class TaxFreeService {
    
    /// Calculate exact tax refund amount.
    /// Formula: RefundAmount = TaxAmount * RefundPercentage - ServiceFee
    public static func calculateRefund(
        taxAmount: Decimal,
        refundPercentage: Decimal,
        serviceFee: Decimal
    ) -> Decimal {
        guard taxAmount > 0 else { return 0 }
        
        let percentageFraction = refundPercentage / Decimal(100)
        let rawRefund = taxAmount * percentageFraction
        let netRefund = rawRefund - serviceFee
        
        return max(0, netRefund)
    }
}
