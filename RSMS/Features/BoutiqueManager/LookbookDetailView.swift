//
//  LookbookDetailView.swift
//  RSMS
//
//  Full-screen detail view for a single lookbook — shows images,
//  styling guidelines, brand instructions, and share/download actions.
//

import SwiftUI

struct LookbookDetailView: View {
    let lookbook: Lookbook

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    @State private var isSharePresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Hero Image Gallery
                imageGallery

                // MARK: - Content
                VStack(alignment: .leading, spacing: 24) {
                    // Title + Season + Status
                    headerSection

                    // Description
                    if let description = lookbook.description, !description.isEmpty {
                        descriptionSection(description)
                    }

                    // Brand Guidelines
                    if let guideline = lookbook.brandGuideline, !guideline.isEmpty {
                        guidelineSection(guideline)
                    }

                    // Metadata
                    metadataSection

                    // Action Buttons
                    actionButtons
                }
                .padding(24)
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle(lookbook.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isSharePresented) {
            shareSheet
        }
    }

    // MARK: - Image Gallery

    private var imageGallery: some View {
        Group {
            if lookbook.imageURLs.isEmpty {
                // No images placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(RSMSTheme.surfaceTertiary)
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text("No Images Available")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
                .frame(height: 320)
            } else {
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(lookbook.imageURLs.enumerated()), id: \.offset) { index, urlString in
                            AsyncImage(url: URL(string: urlString)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 400)
                                        .clipped()
                                case .failure:
                                    imagePlaceholder(icon: "photo.badge.exclamationmark")
                                case .empty:
                                    imagePlaceholder(icon: "photo")
                                        .overlay {
                                            ProgressView()
                                                .tint(RSMSTheme.primary)
                                        }
                                @unknown default:
                                    imagePlaceholder(icon: "photo")
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 400)

                    // Custom page indicator
                    if lookbook.imageURLs.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<lookbook.imageURLs.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedImageIndex
                                          ? RSMSTheme.primary
                                          : RSMSTheme.cream.opacity(0.6))
                                    .frame(width: index == selectedImageIndex ? 10 : 7,
                                           height: index == selectedImageIndex ? 10 : 7)
                                    .animation(.spring(response: 0.3), value: selectedImageIndex)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }

    private func imagePlaceholder(icon: String) -> some View {
        ZStack {
            RSMSTheme.surfaceTertiary
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(height: 400)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(lookbook.title)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(RSMSTheme.textPrimary)

                    HStack(spacing: 12) {
                        Label(lookbook.season, systemImage: "leaf.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.primary)

                        Text("•")
                            .foregroundStyle(RSMSTheme.textTertiary)

                        Text("\(lookbook.imageURLs.count) image\(lookbook.imageURLs.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }

                Spacer()

                StatusBadge(
                    text: lookbook.isActive ? "Active" : "Archived",
                    color: lookbook.isActive ? RSMSTheme.success : RSMSTheme.textSecondary
                )
            }
        }
    }

    // MARK: - Description

    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Overview", systemImage: "doc.text")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(RSMSTheme.textPrimary)

            Text(text)
                .font(.body)
                .foregroundStyle(RSMSTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Brand Guideline

    private func guidelineSection(_ guideline: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Brand & Styling Guidelines", systemImage: "paintpalette.fill")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(RSMSTheme.textPrimary)

            Text(guideline)
                .font(.body)
                .foregroundStyle(RSMSTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.primary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        HStack(spacing: 24) {
            metadataItem(icon: "calendar", label: "Published", value: formattedDate(lookbook.createdAt))
            metadataItem(icon: "tag.fill", label: "Season", value: lookbook.season)
            metadataItem(icon: "photo.stack", label: "Images", value: "\(lookbook.imageURLs.count)")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RSMSTheme.surfaceTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metadataItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(RSMSTheme.primary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                isSharePresented = true
            } label: {
                Label("Share Lookbook", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RSMSTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Share Sheet

    private var shareSheet: some View {
        let shareText = """
        📖 \(lookbook.title)
        Season: \(lookbook.season)
        \(lookbook.description ?? "")
        \(lookbook.brandGuideline != nil ? "\nGuidelines: \(lookbook.brandGuideline!)" : "")
        Images: \(lookbook.imageURLs.count)
        """
        return ActivityViewControllerRepresentable(activityItems: [shareText])
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
            season: "SS25",
            description: "A collection that celebrates the vibrant energy of Parisian spring with delicate silhouettes and bold color choices.",
            imageURLs: [],
            brandGuideline: "Use neutral mannequin stands. Lighting should be warm white (3000K). Group by color story: blush → champagne → ivory.",
            isActive: true,
            createdAt: .now
        ))
    }
}
