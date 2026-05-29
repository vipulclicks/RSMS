//
//  ComplianceModels.swift
//  RSMS
//

import Foundation
import SwiftUI

// MARK: - Enums

enum AuditStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case inProgress = "In Progress"
    case submitted = "Submitted"
    case reviewed = "Reviewed"
    case approved = "Approved"
    case archived = "Archived"
}

enum ChecklistItemStatus: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case pass = "Pass"
    case fail = "Fail"
    case notApplicable = "N/A"
}

enum IssueSeverity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

enum CorrectiveActionStatus: String, Codable, CaseIterable {
    case open = "Open"
    case assigned = "Assigned"
    case inProgress = "In Progress"
    case resolved = "Resolved"
    case closed = "Closed"
}

enum EvidenceType: String, Codable {
    case photo = "Photo"
    case video = "Video"
    case document = "Document"
}

// MARK: - Models

struct AuditTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var estimatedDuration: Int // minutes
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case estimatedDuration = "estimated_duration"
        case lastUpdated = "last_updated"
    }
}

struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var templateId: UUID
    var title: String
    var description: String
    var guidelineReference: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case templateId = "template_id"
        case guidelineReference = "guideline_reference"
    }
}

struct Audit: Identifiable, Codable, Hashable {
    let id: UUID
    var storeId: UUID
    var templateId: UUID
    var inspectorId: UUID
    var status: AuditStatus
    var score: Double?
    var startedAt: Date
    var completedAt: Date?
    var targetZones: [UUID] // Which store zones are included
    
    enum CodingKeys: String, CodingKey {
        case id, status, score
        case storeId = "store_id"
        case templateId = "template_id"
        case inspectorId = "inspector_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case targetZones = "target_zones"
    }
}

struct AuditChecklistResponse: Identifiable, Codable, Hashable {
    let id: UUID
    var auditId: UUID
    var checklistItemId: UUID
    var status: ChecklistItemStatus
    var comments: String?
    var evidenceIds: [UUID]
    
    enum CodingKeys: String, CodingKey {
        case id, status, comments
        case auditId = "audit_id"
        case checklistItemId = "checklist_item_id"
        case evidenceIds = "evidence_ids"
    }
}

struct ComplianceIssue: Identifiable, Codable, Hashable {
    let id: UUID
    var auditId: UUID
    var checklistItemId: UUID
    var title: String
    var description: String
    var severity: IssueSeverity
    var location: String // e.g. "Window Display Left"
    var guidelineReference: String?
    var status: CorrectiveActionStatus
    var createdDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, severity, location, status
        case auditId = "audit_id"
        case checklistItemId = "checklist_item_id"
        case guidelineReference = "guideline_reference"
        case createdDate = "created_date"
    }
}

struct CorrectiveAction: Identifiable, Codable, Hashable {
    let id: UUID
    var issueId: UUID
    var ownerId: UUID?
    var title: String
    var priority: IssueSeverity
    var dueDate: Date?
    var expectedResolution: String
    var notes: String?
    var status: CorrectiveActionStatus
    
    enum CodingKeys: String, CodingKey {
        case id, title, priority, notes, status
        case issueId = "issue_id"
        case ownerId = "owner_id"
        case dueDate = "due_date"
        case expectedResolution = "expected_resolution"
    }
}

struct Evidence: Identifiable, Codable, Hashable {
    let id: UUID
    var auditId: UUID
    var linkedChecklistItemId: UUID?
    var type: EvidenceType
    var fileUrl: String
    var timestamp: Date
    var capturedById: UUID
    
    enum CodingKeys: String, CodingKey {
        case id, type, timestamp
        case auditId = "audit_id"
        case linkedChecklistItemId = "linked_checklist_item_id"
        case fileUrl = "file_url"
        case capturedById = "captured_by_id"
    }
}

struct AuditSchedule: Identifiable, Codable, Hashable {
    let id: UUID
    var templateId: UUID
    var frequency: String // e.g., "Daily", "Weekly"
    var targetZones: [UUID]
    var assigneeId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, frequency
        case templateId = "template_id"
        case targetZones = "target_zones"
        case assigneeId = "assignee_id"
    }
}

// MARK: - Mock Data Factory

struct ComplianceMockData {
    static let shared = ComplianceMockData()
    
    let templates: [AuditTemplate] = [
        AuditTemplate(id: UUID(), name: "Window Display Audit", description: "Verify front windows follow current seasonal guidelines.", estimatedDuration: 15, lastUpdated: Date()),
        AuditTemplate(id: UUID(), name: "Women's Wear Daily Audit", description: "Check mannequins and table displays for Women's section.", estimatedDuration: 20, lastUpdated: Date()),
        AuditTemplate(id: UUID(), name: "Accessories Compliance", description: "Audit high-value accessory cabinets.", estimatedDuration: 10, lastUpdated: Date())
    ]
    
    let checklistItems: [ChecklistItem] = [
        ChecklistItem(id: UUID(), templateId: UUID(), title: "Signage Correctness", description: "Is the correct seasonal campaign signage displayed?", guidelineReference: "VM-24-01"),
        ChecklistItem(id: UUID(), templateId: UUID(), title: "Mannequin Styling", description: "Are mannequins dressed according to the current Lookbook?", guidelineReference: "VM-24-02"),
        ChecklistItem(id: UUID(), templateId: UUID(), title: "Product Alignment", description: "Are bags evenly spaced at 10cm apart?", guidelineReference: "VM-ACC-11"),
        ChecklistItem(id: UUID(), templateId: UUID(), title: "Lighting Alignment", description: "Are spotlights hitting the hero products?", guidelineReference: "VM-LGT-01")
    ]
}
