//
//  ComplianceHistoryView.swift
//  RSMS
//

import SwiftUI

struct ComplianceHistoryView: View {
    @Bindable var viewModel: ComplianceViewModel
    @State private var searchText = ""
    
    var historyChecks: [ComplianceCheck] {
        var checks = viewModel.complianceChecks
        
        if !searchText.isEmpty {
            checks = checks.filter { $0.notes?.localizedCaseInsensitiveContains(searchText) == true }
        }
        
        return checks.sorted { $0.checkedAt > $1.checkedAt }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if historyChecks.isEmpty {
                    Text("No history available.")
                        .foregroundColor(RSMSTheme.textSecondary)
                        .padding()
                } else {
                    ForEach(Array(historyChecks.enumerated()), id: \.element.id) { index, check in
                        TimelineRow(viewModel: viewModel, check: check, isLast: index == historyChecks.count - 1)
                    }
                }
            }
            .padding()
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Compliance History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search history...")
    }
}

struct TimelineRow: View {
    @Bindable var viewModel: ComplianceViewModel
    let check: ComplianceCheck
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline graphics
            VStack(spacing: 0) {
                Circle()
                    .fill(check.status.color)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 1)
                
                if !isLast {
                    Rectangle()
                        .fill(RSMSTheme.border)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.top, 4)
            
            // Content
            NavigationLink {
                ComplianceCheckDetailsView(viewModel: viewModel, check: check)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(check.checkedAt.formatted(date: .long, time: .shortened))
                            .font(.subheadline.bold())
                            .foregroundColor(RSMSTheme.textPrimary)
                        Spacer()
                        Text(check.status.displayName)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(check.status.color.opacity(0.2))
                            .foregroundColor(check.status.color)
                            .cornerRadius(8)
                    }
                    
                    Text("Inspector ID: \(check.checkedBy.uuidString)")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.textSecondary)
                    
                    Text("Planogram ID: \(check.planogramId.uuidString)")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.textSecondary)
                }
                .padding()
                .background(RSMSTheme.surfaceSecondary)
                .cornerRadius(12)
                .padding(.bottom, 24)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
