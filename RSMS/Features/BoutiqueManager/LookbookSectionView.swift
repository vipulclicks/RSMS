//
//  LookbookSectionView.swift
//  RSMS
//
//  Dashboard section showing digital lookbooks with search, filter,
//  and navigation to detail view. Fully connected to Supabase backend.
//

import SwiftUI
import UniformTypeIdentifiers

struct LookbookSectionView: View {
    @Bindable var lookbookVM: LookbookViewModel
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var isFileImporterPresented = false
    @State private var newLookbookTitle = ""
    @State private var selectedFileURL: URL?
    @State private var isTitleAlertPresented = false

    private var gridColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible())]
        } else {
            return [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // MARK: - Section Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(RSMSTheme.primary)
                        Text("Digital Lookbooks")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    Text("\(lookbookVM.activeCount) active • \(lookbookVM.archivedCount) archived")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }

                Spacer()

                // Upload Button
                Button {
                    isFileImporterPresented = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 13))
                        Text("Upload PDF")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.primary)
                    .clipShape(Capsule())
                }
            }

            // MARK: - Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(RSMSTheme.textTertiary)

                TextField("Search lookbooks...", text: Bindable(lookbookVM).searchText)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .autocorrectionDisabled()

                if !lookbookVM.searchText.isEmpty {
                    Button {
                        lookbookVM.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RSMSTheme.surfaceTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // MARK: - Content
            if lookbookVM.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(RSMSTheme.primary)
                    Text("Loading lookbooks...")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if lookbookVM.isUploading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(RSMSTheme.primary)
                    Text("Uploading Lookbook...")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if let error = lookbookVM.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(RSMSTheme.warning)
                    Text("Something went wrong")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        Task {
                            await lookbookVM.load(dataStore: appVM.dataStore)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.primary)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else if lookbookVM.filteredLookbooks.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(lookbookVM.filteredLookbooks) { lookbook in
                        NavigationLink(value: lookbook) {
                            lookbookCard(lookbook)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .rsmsCard()
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            do {
                if let selectedURL = try result.get().first {
                    self.selectedFileURL = selectedURL
                    self.newLookbookTitle = selectedURL.deletingPathExtension().lastPathComponent
                    self.isTitleAlertPresented = true
                }
            } catch {
                lookbookVM.errorMessage = error.localizedDescription
            }
        }
        .alert("Upload Lookbook", isPresented: $isTitleAlertPresented) {
            TextField("Title", text: $newLookbookTitle)
            Button("Cancel", role: .cancel) {
                selectedFileURL = nil
                newLookbookTitle = ""
            }
            Button("Upload") {
                if let url = selectedFileURL, !newLookbookTitle.isEmpty {
                    Task {
                        await lookbookVM.uploadLookbook(title: newLookbookTitle, fileURL: url, dataStore: appVM.dataStore)
                    }
                }
            }
        } message: {
            Text("Enter a title for the new Lookbook.")
        }
    }

    // MARK: - Lookbook Card

    private func lookbookCard(_ lookbook: Lookbook) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail / Icon
            ZStack {
                RSMSTheme.surfaceTertiary
                VStack(spacing: 12) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(RSMSTheme.primary.opacity(0.8))
                }
                
                // Status badge overlay
                StatusBadge(
                    text: lookbook.isActive ? "Active" : "Archived",
                    color: lookbook.isActive ? RSMSTheme.success : RSMSTheme.textSecondary
                )
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            .frame(height: 140)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(lookbook.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)

                // Date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(lookbookVM.formattedDate(lookbook.createdAt))
                        .font(.caption2)
                }
                .foregroundStyle(RSMSTheme.textTertiary)
            }
            .padding(14)
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("No Lookbooks Found")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textSecondary)

            if !lookbookVM.searchText.isEmpty {
                Text("Try adjusting your search.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)

                Button("Clear Search") {
                    withAnimation {
                        lookbookVM.searchText = ""
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.primary)
            } else {
                Text("No lookbooks have been published yet.\nUpload a PDF to get started.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            LookbookSectionView(lookbookVM: LookbookViewModel())
                .padding(24)
        }
        .background(RSMSTheme.background)
    }
    .environment(AppViewModel())
}
