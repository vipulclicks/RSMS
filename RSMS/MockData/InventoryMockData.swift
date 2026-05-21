//
//  InventoryMockData.swift
//  RSMS
//
//  Preview data for inventory, RFID, movements, and auditing.
//  Updated to match Supabase-aligned models.
//

import Foundation

// MARK: - Product Mock Data

extension Product {
    static let preview = Product(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
        sku: "JWL-DIA-NK-001",
        name: "Étoile Diamond Necklace",
        category: "Jewelry",
        subcategory: "Necklaces",
        brand: "Maison Lumière",
        collection: "Étoile",
        material: "Platinum",
        price: 24500.00,
        currency: "EUR",
        imageURL: nil,
        description: "An exquisite platinum necklace featuring a 2.5ct brilliant-cut diamond pendant.",
        isActive: true,
        createdAt: .now,
        updatedAt: .now
    )

    static let previewWatch = Product(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
        sku: "WCH-AUT-RG-001",
        name: "Lumière Grande Complication",
        category: "Watches",
        subcategory: "Automatic",
        brand: "Maison Lumière",
        collection: "Heritage",
        material: "Rose Gold",
        price: 38000.00,
        currency: "EUR",
        imageURL: nil,
        description: "A handcrafted rose gold automatic with perpetual calendar and moon phase.",
        isActive: true,
        createdAt: .now,
        updatedAt: .now
    )

    static let previewBag = Product(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
        sku: "LTH-BAG-CL-001",
        name: "Vendôme Clutch",
        category: "Leather Goods",
        subcategory: "Clutches",
        brand: "Maison Lumière",
        collection: "Vendôme",
        material: "Calfskin Leather",
        price: 3200.00,
        currency: "EUR",
        imageURL: nil,
        description: "A sleek evening clutch in butter-soft calfskin with gold hardware.",
        isActive: true,
        createdAt: .now,
        updatedAt: .now
    )

    static let all: [Product] = [.preview, .previewWatch, .previewBag]
}

// MARK: - Stock Item Mock Data

extension StockItem {
    static let preview = StockItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000110")!,
        productId: Product.preview.id,
        storeId: Store.preview.id,
        quantity: 2,
        rfidTag: "RFID-LUM-0001",
        location: "display_case_A3",
        status: .available,
        lastScannedAt: .now,
        updatedAt: .now
    )

    static let previewWatch = StockItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000111")!,
        productId: Product.previewWatch.id,
        storeId: Store.preview.id,
        quantity: 1,
        rfidTag: "RFID-LUM-0002",
        location: "vault",
        status: .available,
        lastScannedAt: .now,
        updatedAt: .now
    )

    static let all: [StockItem] = [.preview, .previewWatch]
}

// MARK: - RFID Scan Record Mock Data

extension RFIDScanRecord {
    static let preview = RFIDScanRecord(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000120")!,
        storeId: Store.preview.id,
        scannedBy: UserProfile.previewInventory.id,
        scannedAt: .now,
        itemsScanned: 342,
        exceptionsFound: 3,
        notes: "Monthly full-store scan. 3 items flagged for location verification."
    )

    static let all: [RFIDScanRecord] = [.preview]
}

// MARK: - Inventory Variance Mock Data

extension InventoryVariance {
    static let preview = InventoryVariance(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000130")!,
        storeId: Store.preview.id,
        productId: Product.previewBag.id,
        expectedQty: 5,
        actualQty: 4,
        variance: -1,
        reportedBy: UserProfile.previewInventory.id,
        status: .open,
        cycleCountId: nil,
        resolution: nil,
        reportedAt: .now,
        resolvedAt: nil
    )

    static let all: [InventoryVariance] = [.preview]
}

// MARK: - Inventory Movement Mock Data

extension InventoryMovement {
    /// A store-to-store transfer
    static let previewTransfer = InventoryMovement(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000140")!,
        type: .storeTransfer,
        sourceId: Store.preview.id.uuidString,
        destinationId: Store.previewMumbai.id.uuidString,
        status: .approved,
        requestedBy: UserProfile.previewInventory.id,
        approvedBy: UserProfile.previewManager.id,
        requestedAt: .now,
        shippedAt: nil,
        receivedAt: nil,
        asnNumber: nil,
        itemsExpected: 3,
        itemsReceived: nil,
        reason: "Stock rebalancing",
        notes: "Mumbai low on watches"
    )

    /// A DC replenishment shipment
    static let previewReplenishment = InventoryMovement(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000141")!,
        type: .dcReplenishment,
        sourceId: "DC-PARIS-01",
        destinationId: Store.preview.id.uuidString,
        status: .inTransit,
        requestedBy: nil,
        approvedBy: nil,
        requestedAt: nil,
        shippedAt: Calendar.current.date(byAdding: .day, value: -2, to: .now),
        receivedAt: nil,
        asnNumber: "ASN-2026-0547",
        itemsExpected: 12,
        itemsReceived: nil,
        reason: nil,
        notes: "Spring collection replenishment"
    )

    /// A vendor return
    static let previewVendorReturn = InventoryMovement(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000142")!,
        type: .vendorReturn,
        sourceId: Store.preview.id.uuidString,
        destinationId: "VENDOR-CARTIER-01",
        status: .requested,
        requestedBy: UserProfile.previewInventory.id,
        approvedBy: nil,
        requestedAt: .now,
        shippedAt: nil,
        receivedAt: nil,
        asnNumber: nil,
        itemsExpected: 2,
        itemsReceived: nil,
        reason: "Damaged clasp mechanism",
        notes: nil
    )

    static let all: [InventoryMovement] = [.previewTransfer, .previewReplenishment, .previewVendorReturn]
}

// MARK: - Movement Item Mock Data

extension MovementItem {
    static let preview = MovementItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000150")!,
        movementId: InventoryMovement.previewTransfer.id,
        productId: Product.previewWatch.id,
        quantity: 1,
        reason: nil
    )

    static let all: [MovementItem] = [.preview]
}

// MARK: - Cycle Count Mock Data

extension CycleCount {
    static let preview = CycleCount(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000160")!,
        storeId: Store.preview.id,
        scheduledDate: .now,
        status: .completed,
        conductedBy: UserProfile.previewInventory.id,
        completedAt: .now,
        notes: "Quarterly jewelry section count",
        createdAt: .now
    )

    static let all: [CycleCount] = [.preview]
}

// MARK: - Audit Trail Mock Data

extension AuditTrail {
    static let preview = AuditTrail(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000170")!,
        storeId: Store.preview.id,
        action: "Stock Transfer Approved",
        entityType: "InventoryMovement",
        entityId: InventoryMovement.previewTransfer.id,
        performedBy: UserProfile.previewManager.id,
        timestamp: .now,
        details: "Approved transfer of 3 watches to Mumbai Palladium"
    )

    static let all: [AuditTrail] = [.preview]
}

// MARK: - Serial Capture Mock Data

extension SerialCapture {
    static let preview = SerialCapture(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000180")!,
        productId: Product.preview.id,
        serialNumber: "LUM-DIA-2026-00142",
        capturedBy: UserProfile.previewInventory.id,
        capturedAt: .now
    )

    static let all: [SerialCapture] = [.preview]
}

// MARK: - Auth Certificate Mock Data

extension AuthCertificate {
    static let preview = AuthCertificate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000190")!,
        productId: Product.preview.id,
        serialNumber: "LUM-DIA-2026-00142",
        certificateURL: "https://certs.maisonlumiere.com/LUM-DIA-2026-00142",
        issuedAt: .now,
        issuedBy: UserProfile.previewInventory.id
    )

    static let all: [AuthCertificate] = [.preview]
}

// MARK: - Shrinkage Analytics Mock Data

extension ShrinkageAnalytics {
    static let preview = ShrinkageAnalytics(
        id: UUID(uuidString: "00000000-0000-0000-0000-0000000001A0")!,
        storeId: Store.preview.id,
        periodStart: Calendar.current.date(byAdding: .day, value: -90, to: .now)!,
        periodEnd: .now,
        totalLossUnits: 4,
        totalLossValue: 12800.00,
        currency: "EUR",
        topCategory: "Leather Goods",
        primaryCause: "Unverified transfer discrepancy"
    )

    static let all: [ShrinkageAnalytics] = [.preview]
}
