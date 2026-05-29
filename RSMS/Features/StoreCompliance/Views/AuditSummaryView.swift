//
//  AuditSummaryView.swift
//  RSMS
//

import SwiftUI

struct AuditSummaryView: View {
    @Bindable var viewModel: AuditExecutionViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header Score
                VStack(spacing: 8) {
                    Text(String(format: "%.0f%%", viewModel.complianceScore))
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(viewModel.complianceScore >= 90 ? .green : (viewModel.complianceScore >= 70 ? .orange : .red))
                    
                    Text("Compliance Score")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    let passedCount = viewModel.responses.values.filter { $0.status == .pass }.count
                    let failedCount = viewModel.responses.values.filter { $0.status == .fail }.count
                    let evidenceCount = viewModel.responses.values.map { $0.evidenceIds.count }.reduce(0, +)
                    
                    SummaryStatCard(title: "Passed", value: "\(passedCount)", color: .green)
                    SummaryStatCard(title: "Failed", value: "\(failedCount)", color: .red)
                    SummaryStatCard(title: "Evidence", value: "\(evidenceCount)", color: .blue)
                }
                
                Divider()
                
                // Issues Overview
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Issues & Corrective Actions")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.newlyCreatedIssues.count) Found")
                            .foregroundColor(.gray)
                    }
                    
                    if viewModel.newlyCreatedIssues.isEmpty {
                        Text("No issues recorded. Great job!")
                            .foregroundColor(.green)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        ForEach(viewModel.newlyCreatedIssues) { issue in
                            HStack {
                                Circle().fill(issue.severity.color).frame(width: 12, height: 12)
                                VStack(alignment: .leading) {
                                    Text(issue.title)
                                        .fontWeight(.medium)
                                    Text("Severity: \(issue.severity.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(white: 0.98))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            try? await viewModel.submitAudit()
                            // Navigate back to dashboard or show success
                            dismiss()
                        }
                    }) {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RSMSTheme.primary)
                                .cornerRadius(12)
                        } else {
                            Text("Submit Audit")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RSMSTheme.primary)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                    
                    Button("Edit Audit") {
                        dismiss()
                    }
                    .foregroundColor(RSMSTheme.primary)
                }
                .padding(.top, 16)
                
            }
            .padding(32)
        }
        .navigationTitle("Audit Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
