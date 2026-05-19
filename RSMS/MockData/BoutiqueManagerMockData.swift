//
//  BoutiqueManagerMockData.swift
//  RSMS_Mock_Data
//
//  Created by Prem Kumar on 18/05/26.
//

import Foundation

// MARK: - DashboardSummary

extension DashboardSummary {
    static let preview = DashboardSummary(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        storeId: Store.preview.id,
        date: .now,
        salesTarget: 150_000,
        salesActual: 112_500,
        appointmentCount: 8,
        lowStockAlertCount: 3,
        topSellingCategory: "Haute Joaillerie",
        footfallCount: 64
    )
}

// MARK: - StaffShift

extension StaffShift {
    static let preview = StaffShift(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000010")!,
        staffId: UserProfile.previewAssociate.id,
        storeId: Store.preview.id,
        shiftDate: .now,
        startTime: "09:00",
        endTime: "17:30",
        role: "floor",
        notes: nil
    )

    static let previewEvening = StaffShift(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000011")!,
        staffId: UserProfile.previewInventory.id,
        storeId: Store.preview.id,
        shiftDate: .now,
        startTime: "13:00",
        endTime: "21:00",
        role: "back_office",
        notes: "Cycle count scheduled"
    )

    static let all: [StaffShift] = [.preview, .previewEvening]
}

// MARK: - SalesGoal

extension SalesGoal {
    static let preview = SalesGoal(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000020")!,
        staffId: UserProfile.previewAssociate.id,
        storeId: Store.preview.id,
        targetAmount: 45_000,
        achievedAmount: 31_200,
        period: .monthly,
        startDate: .now,
        endDate: .now.addingTimeInterval(30 * 86400),
        createdAt: .now
    )
}

// MARK: - Commission

extension Commission {
    static let preview = Commission(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000030")!,
        staffId: UserProfile.previewAssociate.id,
        transactionId: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!,
        amount: 1250.00,
        rate: 0.05,
        status: .approved,
        createdAt: .now
    )
}

// MARK: - PerformanceMetric

extension PerformanceMetric {
    static let preview = PerformanceMetric(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000040")!,
        staffId: UserProfile.previewAssociate.id,
        storeId: Store.preview.id,
        totalSales: 87_600,
        unitsSold: 14,
        avgTransactionValue: 6_257,
        conversionRate: 0.42,
        period: .monthly,
        periodStart: .now.addingTimeInterval(-30 * 86400),
        periodEnd: .now
    )
}

// MARK: - Planogram

extension Planogram {
    static let preview = Planogram(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000050")!,
        storeId: Store.preview.id,
        name: "Window Display — Spring Florals",
        section: "main_window",
        imageURL: nil,
        isCompliant: true,
        lastCheckedAt: .now.addingTimeInterval(-2 * 86400),
        createdAt: .now,
        updatedAt: .now
    )
}

// MARK: - Lookbook

extension Lookbook {
    static let preview = Lookbook(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000055")!,
        title: "Printemps 2026 Collection",
        season: "SS26",
        description: "Spring/Summer haute joaillerie and timepieces.",
        imageURLs: [],
        brandGuideline: "Use warm lighting, velvet displays only.",
        isActive: true,
        createdAt: .now
    )
}

// MARK: - ComplianceCheck

extension ComplianceCheck {
    static let preview = ComplianceCheck(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000060")!,
        storeId: Store.preview.id,
        planogramId: Planogram.preview.id,
        checkedBy: UserProfile.previewManager.id,
        status: .compliant,
        notes: "All display standards met.",
        photoURLs: nil,
        checkedAt: .now
    )
}

// MARK: - ClientEvent

extension ClientEvent {
    static let preview = ClientEvent(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000070")!,
        storeId: Store.preview.id,
        title: "Autumn Haute Joaillerie Preview",
        description: "Exclusive preview of the new haute joaillerie collection.",
        type: .vipPreview,
        date: .now.addingTimeInterval(7 * 86400),
        endDate: nil,
        capacity: 30,
        location: "Salon Privé, 1st Floor",
        createdBy: UserProfile.previewManager.id,
        createdAt: .now
    )
}

// MARK: - EventInvitation

extension EventInvitation {
    static let preview = EventInvitation(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000080")!,
        eventId: ClientEvent.preview.id,
        clientId: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
        status: .confirmed,
        sentAt: .now.addingTimeInterval(-3 * 86400),
        respondedAt: .now.addingTimeInterval(-1 * 86400),
        plusOne: true
    )
}
