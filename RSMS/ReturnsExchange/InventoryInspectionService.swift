//
//  InventoryInspectionService.swift
//  RSMS
//

import Foundation

final class InventoryInspectionService {
    static let shared = InventoryInspectionService()
    
    private init() {}
    
    /// Processes inspection for a ReturnRequest, updates its status/condition, and maps condition to StockStatus.
    func inspectReturn(
        request: inout POSReturnRequest,
        condition: POSInspectionCondition,
        notes: String?,
        userId: UUID
    ) -> (stockStatus: StockStatus, location: String) {
        request.inspectionCondition = condition
        request.inspectionNotes = notes
        request.inspectedBy = userId
        request.inspectedAt = Date()
        request.updatedAt = Date()
        
        switch condition {
        case .new:
            return (.available, "Showroom Floor")
        case .opened:
            return (.reserved, "Inspection Hold Room")
        case .used:
            return (.reserved, "Inspection Hold Room")
        case .damaged:
            return (.damaged, "Damaged Inventory Area")
        case .defective:
            return (.damaged, "Defective Inventory Area")
        }
    }
    
    /// Processes inspection for an ExchangeRequest, updates its status/condition, and maps condition to StockStatus.
    func inspectExchange(
        request: inout POSExchangeRequest,
        condition: POSInspectionCondition,
        notes: String?,
        userId: UUID
    ) -> (stockStatus: StockStatus, location: String) {
        request.inspectionCondition = condition
        request.inspectionNotes = notes
        request.inspectedBy = userId
        request.inspectedAt = Date()
        request.updatedAt = Date()
        
        switch condition {
        case .new:
            return (.available, "Showroom Floor")
        case .opened:
            return (.reserved, "Inspection Hold Room")
        case .used:
            return (.reserved, "Inspection Hold Room")
        case .damaged:
            return (.damaged, "Damaged Inventory Area")
        case .defective:
            return (.damaged, "Defective Inventory Area")
        }
    }
}
