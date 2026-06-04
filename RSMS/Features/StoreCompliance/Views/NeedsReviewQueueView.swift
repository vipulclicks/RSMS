//
//  NeedsReviewQueueView.swift
//  RSMS
//

import SwiftUI

struct NeedsReviewQueueView: View {
    @Bindable var viewModel: ComplianceViewModel
    
    var reviewChecks: [ComplianceCheck] {
        viewModel.complianceChecks
            .filter { $0.status == .needsReview }
            .sorted { $0.checkedAt > $1.checkedAt }
    }
    
    var body: some View {
        VStack {
            if reviewChecks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(RSMSTheme.success)
                    Text("All Caught Up!")
                        .font(.title2)
                        .foregroundColor(RSMSTheme.textPrimary)
                    Text("No items currently need review.")
                        .foregroundColor(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(reviewChecks) { check in
                    NeedsReviewRow(viewModel: viewModel, check: check)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Needs Review Queue")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NeedsReviewRow: View {
    @Bindable var viewModel: ComplianceViewModel
    let check: ComplianceCheck
    
    @State private var isUpdating = false
    @State private var showCommentAlert = false
    @State private var newComment = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Needs Review", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(RSMSTheme.warning)
                    .font(.headline)
                Spacer()
                Text(check.checkedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(RSMSTheme.textSecondary)
            }
            
            Text("Inspector ID: \(check.checkedBy.uuidString)")
                .font(.caption)
                .foregroundColor(RSMSTheme.textSecondary)
            
            if let notes = check.notes, !notes.isEmpty {
                Text("Inspector Notes:")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.textSecondary)
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(white: 0.98))
                    .cornerRadius(8)
            }
            
            if let photos = check.photoURLs, !photos.isEmpty {
                Text("\(photos.count) Evidence Photos attached.")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.primary)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    updateStatus(to: .compliant)
                }) {
                    Text("Approve")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(RSMSTheme.success)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isUpdating)
                
                Button(action: {
                    updateStatus(to: .nonCompliant)
                }) {
                    Text("Reject")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isUpdating)
                
                Button(action: {
                    showCommentAlert = true
                }) {
                    Image(systemName: "text.bubble")
                        .padding(8)
                        .background(Color(white: 0.9))
                        .cornerRadius(8)
                }
                .accessibilityLabel("Add Comment")
                .disabled(isUpdating)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 8)
        .alert("Add Comment", isPresented: $showCommentAlert) {
            TextField("Comment", text: $newComment)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                addComment()
            }
        }
    }
    
    private func updateStatus(to newStatus: ComplianceStatus) {
        var updatedCheck = check
        updatedCheck.status = newStatus
        isUpdating = true
        Task {
            do {
                try await viewModel.updateCheck(updatedCheck)
            } catch {
                print("Error updating review: \(error)")
            }
            isUpdating = false
        }
    }
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        var updatedCheck = check
        let existingNotes = updatedCheck.notes ?? ""
        updatedCheck.notes = existingNotes.isEmpty ? newComment : "\(existingNotes)\n\nManager: \(newComment)"
        
        isUpdating = true
        Task {
            do {
                try await viewModel.updateCheck(updatedCheck)
            } catch {
                print("Error adding comment: \(error)")
            }
            isUpdating = false
            newComment = ""
        }
    }
}
