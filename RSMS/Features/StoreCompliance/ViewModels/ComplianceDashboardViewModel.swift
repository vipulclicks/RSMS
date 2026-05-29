//
//  ComplianceDashboardViewModel.swift
//  RSMS
//

import Foundation
import Observation

@Observable
final class ComplianceDashboardViewModel {
    var isLoading = false
    var overallScore: Double = 87.5 // Mock baseline
    var openIssuesCount: Int = 12
    var auditsDueTodayCount: Int = 2
    var lastAuditDate: Date? = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    
    var recentActivity: [Audit] = []
    var upcomingSchedules: [AuditSchedule] = []
    var openIssues: [ComplianceIssue] = []
    
    var storeId: UUID?
    
    func loadDashboard(for storeId: UUID) async {
        self.storeId = storeId
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let fetchedAudits = try await ComplianceService.shared.fetchAudits(storeId: storeId)
            self.recentActivity = fetchedAudits.sorted(by: { $0.startedAt > $1.startedAt })
            
            self.openIssues = try await ComplianceService.shared.fetchIssues(storeId: storeId)
            self.openIssuesCount = self.openIssues.filter { $0.status != .closed }.count
            
        } catch {
            print("Failed to load compliance dashboard: \(error)")
        }
    }
}
