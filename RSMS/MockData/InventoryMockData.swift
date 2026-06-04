////
////  InventoryMockData.swift
////  RSMS_Mock_Data
////
////  Created by Prem Kumar on 18/05/26.
////
//
//import Foundation
//
//// MARK: - Product
//
//extension Product {
//    static let previewWatch = Product(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
//        sku: "WA-CHR-RG-42",
//        name: "Chronograph Royale - 42mm",
//        category: "Watches",
//        subcategory: "Chronograph",
//        brand: "Maison Lumière",
//        collection: "Royale",
//        material: "Rose Gold",
//        price: 24500.00,
//        currency: "EUR",
//        imageURL: nil,
//        description: "18k Rose Gold chronograph with alligator strap.",
//        isActive: true,
//        createdAt: .now,
//        updatedAt: .now
//    )
//
//    static let previewRing = Product(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
//        sku: "RG-DIA-ET-52",
//        name: "Eternity Diamond Ring",
//        category: "Jewelry",
//        subcategory: "Rings",
//        brand: "Maison Lumière",
//        collection: "Eternity",
//        material: "Platinum",
//        price: 8900.00,
//        currency: "EUR",
//        imageURL: nil,
//        description: "Platinum eternity ring with 2ct pavé diamonds.",
//        isActive: true,
//        createdAt: .now,
//        updatedAt: .now
//    )
//    
//    static let all: [Product] = [.previewWatch, .previewRing]
//}
//
//// MARK: - StockItem
//
//extension StockItem {
//    static let preview = StockItem(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000010")!,
//        productId: Product.previewWatch.id,
//        storeId: Store.preview.id,
//        quantity: 1,
//        rfidTag: "RFID-1234567890",
//        location: "vault",
//        status: .available,
//        lastScannedAt: .now,
//        updatedAt: .now
//    )
//}
//
//// MARK: - RFIDScanRecord
//
//extension RFIDScanRecord {
//    static let preview = RFIDScanRecord(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000020")!,
//        storeId: Store.preview.id,
//        scannedBy: UserProfile.previewInventory.id,
//        scannedAt: .now.addingTimeInterval(-3600),
//        itemsScanned: 450,
//        exceptionsFound: 2,
//        notes: "Routine morning scan. Missing 2 items from display case C."
//    )
//}
//
//// MARK: - InventoryVariance
//
//extension InventoryVariance {
//    static let preview = InventoryVariance(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000030")!,
//        storeId: Store.preview.id,
//        productId: Product.previewRing.id,
//        expectedQty: 2,
//        actualQty: 1,
//        variance: -1,
//        reportedBy: UserProfile.previewInventory.id,
//        status: .investigating,
//        cycleCountId: nil,
//        resolution: nil,
//        reportedAt: .now,
//        resolvedAt: nil
//    )
//}
//
//// MARK: - InventoryMovement (replaces StockTransfer, ReplenishmentShipment, VendorReturn)
//
//extension InventoryMovement {
//    static let previewTransfer = InventoryMovement(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000040")!,
//        type: .storeTransfer,
//        sourceId: Store.preview.id.uuidString,
//        destinationId: Store.previewMumbai.id.uuidString,
//        status: .inTransit,
//        requestedBy: UserProfile.previewManager.id,
//        approvedBy: UserProfile.previewManager.id,
//        requestedAt: .now.addingTimeInterval(-2 * 86400),
//        shippedAt: .now.addingTimeInterval(-1 * 86400),
//        receivedAt: nil,
//        asnNumber: nil,
//        itemsExpected: 1,
//        itemsReceived: nil,
//        reason: "Customer request transfer.",
//        notes: nil
//    )
//
//    static let previewReplenishment = InventoryMovement(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000050")!,
//        type: .dcReplenishment,
//        sourceId: "DC-EUROPE-01",
//        destinationId: Store.preview.id.uuidString,
//        status: .inTransit,
//        requestedBy: nil,
//        approvedBy: nil,
//        requestedAt: nil,
//        shippedAt: .now.addingTimeInterval(-1 * 86400),
//        receivedAt: nil,
//        asnNumber: "ASN-987654321",
//        itemsExpected: 15,
//        itemsReceived: nil,
//        reason: nil,
//        notes: "Weekly replenishment."
//    )
//
//    static let previewVendorReturn = InventoryMovement(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000060")!,
//        type: .vendorReturn,
//        sourceId: Store.preview.id.uuidString,
//        destinationId: "VEND-001",
//        status: .requested,
//        requestedBy: UserProfile.previewInventory.id,
//        approvedBy: nil,
//        requestedAt: .now,
//        shippedAt: nil,
//        receivedAt: nil,
//        asnNumber: nil,
//        itemsExpected: 1,
//        itemsReceived: nil,
//        reason: "Defective clasp",
//        notes: nil
//    )
//}
//
//extension MovementItem {
//    static let preview = MovementItem(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000045")!,
//        movementId: InventoryMovement.previewTransfer.id,
//        productId: Product.previewWatch.id,
//        quantity: 1,
//        reason: nil
//    )
//}
//
//// MARK: - AuditTrail
//
//extension AuditTrail {
//    static let preview = AuditTrail(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000080")!,
//        storeId: Store.preview.id,
//        action: "Stock Adjusted",
//        entityType: "StockItem",
//        entityId: StockItem.preview.id,
//        performedBy: UserProfile.previewManager.id,
//        timestamp: .now,
//        details: "Adjusted due to found item."
//    )
//}
//
//// MARK: - SerialCapture
//
//extension SerialCapture {
//    static let preview = SerialCapture(
//        id: UUID(uuidString: "30000000-0000-0000-0000-000000000090")!,
//        productId: Product.previewWatch.id,
//        serialNumber: "SN-99887766",
//        capturedBy: UserProfile.previewInventory.id,
//        capturedAt: .now
//    )
//}
//
//// MARK: - AuthCertificate
//
//extension AuthCertificate {
//    static let preview = AuthCertificate(
//        id: UUID(uuidString: "30000000-0000-0000-0000-0000000000A0")!,
//        productId: Product.previewWatch.id,
//        serialNumber: "SN-99887766",
//        certificateURL: "https://example.com/certs/SN-99887766.pdf",
//        issuedAt: .now,
//        issuedBy: UserProfile.previewManager.id
//    )
//}
//
//
//extension ShrinkageAnalytics {
//    static let preview = ShrinkageAnalytics(
//        id: UUID(uuidString: "30000000-0000-0000-0000-0000000000B0")!,
//        storeId: Store.preview.id,
//        periodStart: .now.addingTimeInterval(-90 * 86400),
//        periodEnd: .now,
//        totalLossUnits: 3,
//        totalLossValue: 12500.00,
//        currency: "EUR",
//        topCategory: "Small Leather Goods",
//        primaryCause: "Theft"
//    )
//}
//
//// MARK: - Additional AuditTrail Previews (for activity feed)
//
//extension AuditTrail {
//    static let previewTwo = AuditTrail(
//        id: UUID(uuidString: "00000000-0000-0000-0000-000000000171")!,
//        storeId: Store.preview.id,
//        action: "RFID Scan Complete",
//        entityType: "RFIDScanRecord",
//        entityId: UUID(uuidString: "00000000-0000-0000-0000-000000000172")!,
//        performedBy: UserProfile.previewInventory.id,
//        timestamp: .now.addingTimeInterval(-900),
//        details: "SKU: 882-ALP-04 — 142 items scanned, 0 exceptions"
//    )
//
//    static let previewThree = AuditTrail(
//        id: UUID(uuidString: "00000000-0000-0000-0000-000000000173")!,
//        storeId: Store.preview.id,
//        action: "Low Stock Alert",
//        entityType: "StockItem",
//        entityId: UUID(uuidString: "00000000-0000-0000-0000-000000000174")!,
//        performedBy: UserProfile.previewInventory.id,
//        timestamp: .now.addingTimeInterval(-1800),
//        details: "Eternity Diamond Ring — only 1 unit remaining"
//    )
//}
//
//// MARK: - Dashboard Snapshot Mock Data
//
//extension InventoryDashboardSnapshot {
//    static let preview = InventoryDashboardSnapshot(
//        totalInventoryCount: 12_482,
//        todaysScanCount: 142,
//        scanCompletionPercent: 0.88,
//        lowStockAlertCount: 14,
//        newLowStockCount: 2,
//        pendingTaskCount: 38,
//        recentActivity: [.preview, .previewTwo, .previewThree]
//    )
//}
