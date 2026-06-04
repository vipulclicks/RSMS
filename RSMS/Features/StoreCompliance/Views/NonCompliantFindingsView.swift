//
//  NonCompliantFindingsView.swift
//  RSMS
//

import SwiftUI

struct NonCompliantFindingsView: View {
    @Bindable var viewModel: ComplianceViewModel
    
    var nonCompliantChecks: [ComplianceCheck] {
        viewModel.complianceChecks
            .filter { $0.status == .nonCompliant }
            .sorted { $0.checkedAt > $1.checkedAt }
    }
    
    var body: some View {
        VStack {
            if nonCompliantChecks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 64))
                        .foregroundColor(RSMSTheme.success)
                    Text("No Non-Compliant Findings")
                        .font(.title2)
                        .foregroundColor(RSMSTheme.textPrimary)
                    Text("Your store is fully compliant!")
                        .foregroundColor(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(nonCompliantChecks) { check in
                    NavigationLink {
                        ComplianceCheckDetailsView(viewModel: viewModel, check: check)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Non-Compliant", systemImage: "xmark.octagon.fill")
                                    .foregroundColor(RSMSTheme.danger)
                                    .font(.headline)
                                Spacer()
                                Text(check.checkedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(RSMSTheme.textSecondary)
                            }
                            
                            if let notes = check.notes, !notes.isEmpty {
                                Text("Issue Summary:")
                                    .font(.caption)
                                    .foregroundColor(RSMSTheme.textSecondary)
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(RSMSTheme.textPrimary)
                            } else {
                                Text("No summary provided.")
                                    .font(.subheadline)
                                    .foregroundColor(RSMSTheme.textTertiary)
                                    .italic()
                            }
                            
                            HStack {
                                Label("\(check.photoURLs?.count ?? 0) Evidence Photos", systemImage: "photo")
                                    .font(.caption)
                                    .foregroundColor(RSMSTheme.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Non-Compliant Findings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
