//
//  AuditExecutionViewModel.swift
//  RSMS
//

import Foundation
import Observation

@Observable
final class AuditExecutionViewModel {
    var audit: Audit?
    var template: AuditTemplate?
    var checklistItems: [ChecklistItem] = []
    var responses: [UUID: AuditChecklistResponse] = [:] // Keyed by ChecklistItemId
    var newlyCreatedIssues: [ComplianceIssue] = []
    
    var isLoading = false
    var isSubmitting = false
    
    var progressPercentage: Double {
        guard !checklistItems.isEmpty else { return 0 }
        let completed = responses.values.filter { $0.status != .notStarted }.count
        return Double(completed) / Double(checklistItems.count)
    }
    
    var complianceScore: Double {
        let scoredItems = responses.values.filter { $0.status == .pass || $0.status == .fail }
        guard !scoredItems.isEmpty else { return 100.0 }
        let passed = scoredItems.filter { $0.status == .pass }.count
        return (Double(passed) / Double(scoredItems.count)) * 100.0
    }
    
    func startAudit(storeId: UUID, templateId: UUID, inspectorId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // In a real app, we'd fetch the template from DB
            let templates = try await ComplianceService.shared.fetchTemplates()
            guard let tpl = templates.first(where: { $0.id == templateId }) else { return }
            self.template = tpl
            
            let newAudit = Audit(
                id: UUID(),
                storeId: storeId,
                templateId: templateId,
                inspectorId: inspectorId,
                status: .inProgress,
                score: nil,
                startedAt: Date(),
                completedAt: nil,
                targetZones: []
            )
            
            self.audit = try await ComplianceService.shared.createAudit(newAudit)
            self.checklistItems = try await ComplianceService.shared.fetchChecklistItems(for: templateId)
            
            // Initialize empty responses
            for item in checklistItems {
                responses[item.id] = AuditChecklistResponse(
                    id: UUID(),
                    auditId: newAudit.id,
                    checklistItemId: item.id,
                    status: .notStarted,
                    evidenceIds: []
                )
            }
        } catch {
            print("Error starting audit: \(error)")
        }
    }
    
    func updateResponseStatus(for itemId: UUID, status: ChecklistItemStatus) {
        responses[itemId]?.status = status
        
        // Auto-generate draft issue if marked as fail
        if status == .fail {
            if !newlyCreatedIssues.contains(where: { $0.checklistItemId == itemId }) {
                guard let audit = audit, let item = checklistItems.first(where: { $0.id == itemId }) else { return }
                
                let draftIssue = ComplianceIssue(
                    id: UUID(),
                    auditId: audit.id,
                    checklistItemId: itemId,
                    title: "Failed: \(item.title)",
                    description: "Automatic draft issue from audit failure.",
                    severity: .medium,
                    location: "General", // To be selected by user
                    guidelineReference: item.guidelineReference,
                    status: .open,
                    createdDate: Date()
                )
                newlyCreatedIssues.append(draftIssue)
            }
        }
    }
    
    func updateResponseComment(for itemId: UUID, comment: String) {
        responses[itemId]?.comments = comment
    }
    
    func attachEvidence(to itemId: UUID, url: String, type: EvidenceType, userId: UUID) {
        guard let auditId = audit?.id else { return }
        
        let newEvidence = Evidence(
            id: UUID(),
            auditId: auditId,
            linkedChecklistItemId: itemId,
            type: type,
            fileUrl: url,
            timestamp: Date(),
            capturedById: userId
        )
        // In real app, save to backend here. We just append the ID to the response locally.
        responses[itemId]?.evidenceIds.append(newEvidence.id)
    }
    
    func submitAudit() async throws {
        isSubmitting = true
        defer { isSubmitting = false }
        
        guard var currentAudit = audit else { return }
        currentAudit.status = .submitted
        currentAudit.score = complianceScore
        currentAudit.completedAt = Date()
        
        // In real app, push updates to DB
        let finalResponses = Array(responses.values)
        try await ComplianceService.shared.saveResponses(finalResponses)
        
        for issue in newlyCreatedIssues {
            _ = try await ComplianceService.shared.reportIssue(issue)
        }
        
        self.audit = currentAudit
    }
}
