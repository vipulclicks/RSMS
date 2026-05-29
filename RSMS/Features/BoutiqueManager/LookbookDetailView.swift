//
//  LookbookDetailView.swift
//  RSMS
//
//  Full-screen detail view for a single lookbook — shows the PDF document.
//

import SwiftUI

struct LookbookDetailView: View {
    let lookbook: Lookbook

    @Environment(\.dismiss) private var dismiss
    @State private var isSharePresented = false

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
                Button {
                    isSharePresented = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isSharePresented) {
            shareSheet
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
}
