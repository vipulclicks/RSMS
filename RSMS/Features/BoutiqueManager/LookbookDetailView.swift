//
//  LookbookDetailView.swift
//  RSMS
//
//  Full-screen detail view for a single lookbook — shows the PDF document.
//

import SwiftUI

struct LookbookDetailView: View {
    let lookbook: Lookbook
    var lookbookVM: LookbookViewModel? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @State private var isSharePresented = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        VStack(spacing: 0) {
            if let path = lookbook.pdfStoragePath,
               let url = URL(string: "\(SupabaseConfig.projectURL)/storage/v1/object/public/\(path)") {
                PDFViewer(url: url)
                    .edgesIgnoringSafeArea(.bottom)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("No PDF Available")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle(lookbook.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if lookbookVM != nil {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(RSMSTheme.danger)
                        }
                        .disabled(isDeleting)
                    }
                    
                    Button {
                        isSharePresented = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $isSharePresented) {
            shareSheet
        }
        .alert("Delete Lookbook", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCurrentLookbook()
            }
        } message: {
            Text("Are you sure you want to delete this lookbook? This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Deleting...")
                        .padding()
                        .background(RSMSTheme.surfacePrimary)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private func deleteCurrentLookbook() {
        guard let lookbookVM = lookbookVM else { return }
        isDeleting = true
        Task {
            await lookbookVM.deleteLookbook(lookbook, dataStore: appVM.dataStore)
            isDeleting = false
            dismiss()
        }
    }

    // MARK: - Share Sheet

    private var shareSheet: some View {
        var items: [Any] = []
        let shareText = "📖 \(lookbook.title)"
        items.append(shareText)
        
        if let path = lookbook.pdfStoragePath,
           let url = URL(string: "\(SupabaseConfig.projectURL)/storage/v1/object/public/\(path)") {
            items.append(url)
        }
        
        return ActivityViewControllerRepresentable(activityItems: items)
    }
}

// MARK: - UIActivityViewController Wrapper

struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        LookbookDetailView(lookbook: Lookbook(
            id: UUID(),
            title: "Spring / Summer 2025",
            isActive: true,
            createdAt: .now,
            pdfStoragePath: nil
        ))
    }
    .environment(AppViewModel())
}
