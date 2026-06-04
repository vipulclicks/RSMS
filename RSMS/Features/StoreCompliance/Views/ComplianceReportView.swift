//
//  ComplianceReportView.swift
//  RSMS
//

import SwiftUI

struct ComplianceReportView: View {
    @Bindable var viewModel: ComplianceViewModel
    
    // In a real app, this would use PDFKit or ShareLink.
    // For iOS 16+, we can use ShareLink for sharing.
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.largeTitle)
                        .foregroundColor(RSMSTheme.primary)
                    Text("Compliance Report")
                        .font(.largeTitle.bold())
                        .foregroundColor(RSMSTheme.textPrimary)
                    Text("Summary of all compliance checks")
                        .foregroundColor(RSMSTheme.textSecondary)
                }
                .padding(.top, 32)
                
                // Analytics
                HStack(spacing: 20) {
                    VStack {
                        Text("\(viewModel.complianceChecks.count)")
                            .font(.largeTitle.bold())
                            .foregroundColor(RSMSTheme.textPrimary)
                        Text("Total Audits")
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RSMSTheme.surfaceSecondary)
                    .cornerRadius(12)
                    
                    VStack {
                        Text(String(format: "%.0f%%", viewModel.overallComplianceRate * 100))
                            .font(.largeTitle.bold())
                            .foregroundColor(RSMSTheme.success)
                        Text("Compliance")
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RSMSTheme.surfaceSecondary)
                    .cornerRadius(12)
                }
                
                Divider()
                
                // Actions
                VStack(spacing: 16) {
                    ShareLink(item: generateReportText()) {
                        Label("Share Report / Export", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RSMSTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func generateReportText() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var report = "STORE COMPLIANCE REPORT\n"
        report += "Date: \(formatter.string(from: Date()))\n"
        report += "Overall Compliance Rate: \(String(format: "%.0f%%", viewModel.overallComplianceRate * 100))\n"
        report += "Total Audits: \(viewModel.complianceChecks.count)\n"
        report += "Compliant: \(viewModel.compliantCount)\n"
        report += "Non-Compliant: \(viewModel.nonCompliantCount)\n"
        report += "Needs Review: \(viewModel.needsReviewCount)\n\n"
        
        report += "--- AUDIT LOG ---\n"
        for check in viewModel.complianceChecks {
            report += "[\(check.checkedAt.formatted(date: .abbreviated, time: .shortened))] Status: \(check.status.displayName) | Planogram: \(check.planogramId.uuidString)\n"
            if let notes = check.notes {
                report += "Notes: \(notes)\n"
            }
            report += "\n"
        }
        
        return report
    }
}
