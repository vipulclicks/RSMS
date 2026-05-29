//
//  ComplianceInspectionSplitView.swift
//  RSMS
//

import SwiftUI

struct ComplianceInspectionSplitView: View {
    let template: AuditTemplate
    let targetZones: [UUID]
    
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = AuditExecutionViewModel()
    
    @State private var selectedChecklistItem: ChecklistItem?
    
    // UI Layout states
    @State private var showSummary = false
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT PANEL: Checklist
            checklistPanel
                .frame(width: 320)
                .background(Color(white: 0.98))
            
            Divider()
            
            // CENTER PANEL: Visualizer (Planogram Comparison)
            visualizerPanel
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.95))
            
            Divider()
            
            // RIGHT PANEL: Issue Details
            issueDetailsPanel
                .frame(width: 320)
                .background(Color.white)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Save Draft & Exit") {
                    // Pop to root or previous
                }
            }
            
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(template.name)
                        .font(.headline)
                    Text("Auto-saving...")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Review & Submit") {
                    showSummary = true
                }
                .fontWeight(.bold)
            }
        }
        .onAppear {
            if let storeId = appViewModel.currentStoreId, let userId = appViewModel.currentUser?.id {
                Task {
                    await viewModel.startAudit(storeId: storeId, templateId: template.id, inspectorId: userId)
                    if let first = viewModel.checklistItems.first {
                        selectedChecklistItem = first
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showSummary) {
            AuditSummaryView(viewModel: viewModel)
        }
    }
    
    // MARK: - Left Panel
    
    private var checklistPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Checklist")
                    .font(.title3.bold())
                Spacer()
                Text("\(Int(viewModel.progressPercentage * 100))%")
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.primary)
            }
            .padding()
            .background(Color.white)
            
            Divider()
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                List(viewModel.checklistItems) { item in
                    let isSelected = selectedChecklistItem?.id == item.id
                    let response = viewModel.responses[item.id]
                    
                    Button(action: {
                        withAnimation { selectedChecklistItem = item }
                    }) {
                        HStack(alignment: .top) {
                            statusIcon(for: response?.status ?? .notStarted)
                                .padding(.top, 4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(item.guidelineReference ?? "General")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(isSelected ? RSMSTheme.primary.opacity(0.1) : Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? RSMSTheme.primary : Color.clear, lineWidth: 2)
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Center Panel
    
    private var visualizerPanel: some View {
        VStack {
            Text("Planogram Visualizer")
                .font(.headline)
                .padding()
            
            Spacer()
            
            Image(systemName: "photo.artframe")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .foregroundColor(.gray.opacity(0.3))
            
            Text("Side-by-side Layout Comparison Loading...")
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
        }
    }
    
    // MARK: - Right Panel
    
    private var issueDetailsPanel: some View {
        VStack(spacing: 0) {
            Text("Item Details")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
            
            Divider()
            
            if let item = selectedChecklistItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.title2.bold())
                            Text(item.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Status Controls
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Evaluation")
                                .font(.headline)
                            
                            let currentStatus = viewModel.responses[item.id]?.status ?? .notStarted
                            
                            HStack {
                                StatusButton(title: "Pass", icon: "checkmark.circle.fill", color: .green, isSelected: currentStatus == .pass) {
                                    viewModel.updateResponseStatus(for: item.id, status: .pass)
                                }
                                StatusButton(title: "Fail", icon: "xmark.circle.fill", color: .red, isSelected: currentStatus == .fail) {
                                    viewModel.updateResponseStatus(for: item.id, status: .fail)
                                }
                            }
                            
                            Button("Mark as N/A") {
                                viewModel.updateResponseStatus(for: item.id, status: .notApplicable)
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                        }
                        
                        Divider()
                        
                        // Evidence
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Evidence")
                                    .font(.headline)
                                Spacer()
                                Button(action: {}) {
                                    Image(systemName: "camera.fill")
                                }
                            }
                            
                            let evidences = viewModel.responses[item.id]?.evidenceIds ?? []
                            if evidences.isEmpty {
                                Text("No evidence attached.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            } else {
                                Text("\(evidences.count) file(s) attached.")
                                    .font(.subheadline)
                            }
                        }
                        
                        // Corrective Actions / Issues
                        if viewModel.responses[item.id]?.status == .fail {
                            Divider()
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Corrective Actions")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Spacer()
                                    Button(action: {}) {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                }
                                
                                let issues = viewModel.newlyCreatedIssues.filter { $0.checklistItemId == item.id }
                                if issues.isEmpty {
                                    Text("No issues recorded.")
                                } else {
                                    ForEach(issues) { issue in
                                        HStack {
                                            Circle().fill(issue.severity.color).frame(width: 8, height: 8)
                                            Text(issue.title)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
                Text("Select an item to view details")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    private func statusIcon(for status: ChecklistItemStatus) -> some View {
        switch status {
        case .notStarted: return Image(systemName: "circle.dashed").foregroundColor(.gray)
        case .pass: return Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .fail: return Image(systemName: "xmark.circle.fill").foregroundColor(.red)
        case .notApplicable: return Image(systemName: "minus.circle.fill").foregroundColor(.gray)
        }
    }
}

struct StatusButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? color : .gray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
    }
}
