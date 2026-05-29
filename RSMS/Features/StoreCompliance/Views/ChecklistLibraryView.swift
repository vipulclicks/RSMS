//
//  ChecklistLibraryView.swift
//  RSMS
//

import SwiftUI

struct ChecklistLibraryView: View {
    @State private var templates: [AuditTemplate] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    // Navigation
    @State private var selectedTemplate: AuditTemplate?
    @State private var showAreaSelection = false
    
    var filteredTemplates: [AuditTemplate] {
        if searchText.isEmpty {
            return templates
        }
        return templates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Library...")
            } else {
                List {
                    ForEach(filteredTemplates) { template in
                        Button(action: {
                            selectedTemplate = template
                            showAreaSelection = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(template.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                        Text("\(template.estimatedDuration) min")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search audit templates...")
            }
        }
        .navigationTitle("Audit Templates")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                isLoading = true
                do {
                    templates = try await ComplianceService.shared.fetchTemplates()
                } catch {
                    print("Error fetching templates: \(error)")
                }
                isLoading = false
            }
        }
        .navigationDestination(isPresented: $showAreaSelection) {
            if let template = selectedTemplate {
                AuditScopeView(template: template)
            }
        }
    }
}
