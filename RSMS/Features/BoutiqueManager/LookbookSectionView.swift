//
//  LookbookSectionView.swift
//  RSMS
//
//  Dashboard section showing digital lookbooks with search, filter,
//  and navigation to detail view. Fully connected to Supabase backend.
//

import SwiftUI

struct LookbookSectionView: View {
    @Bindable var lookbookVM: LookbookViewModel
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var gridColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible())]
        } else {
            return [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

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

                // Archive toggle
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        lookbookVM.showArchived.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: lookbookVM.showArchived ? "archivebox.fill" : "archivebox")
                            .font(.system(size: 13))
                        Text(lookbookVM.showArchived ? "Show Active" : "Show All")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(RSMSTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.primary.opacity(0.08))
                    .clipShape(Capsule())
                }
            }

            // MARK: - Search + Season Filter
            VStack(spacing: 12) {
                // Search bar
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

                // Season chips
                if !lookbookVM.availableSeasons.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            seasonChip(label: "All Seasons", season: nil)
                            ForEach(lookbookVM.availableSeasons, id: \.self) { season in
                                seasonChip(label: season, season: season)
                            }
                        }
                    }
                }
            }

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
            } else if let error = lookbookVM.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(RSMSTheme.warning)
                    Text("Failed to load lookbooks")
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
    }

    // MARK: - Season Chip

    private func seasonChip(label: String, season: String?) -> some View {
        let isSelected = lookbookVM.selectedSeason == season

        return Button {
            withAnimation(.spring(response: 0.25)) {
                lookbookVM.selectedSeason = season
            }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : RSMSTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? AnyShapeStyle(RSMSTheme.primaryGradient)
                        : AnyShapeStyle(RSMSTheme.surfaceTertiary)
                )
                .clipShape(Capsule())
        }
    }

    // MARK: - Lookbook Card

    private func lookbookCard(_ lookbook: Lookbook) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                if let firstURL = lookbook.imageURLs.first, let url = URL(string: firstURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                        case .failure:
                            cardPlaceholder
                        case .empty:
                            cardPlaceholder
                                .overlay {
                                    ProgressView()
                                        .tint(RSMSTheme.primary)
                                }
                        @unknown default:
                            cardPlaceholder
                        }
                    }
                } else {
                    cardPlaceholder
                }

                // Status badge overlay
                StatusBadge(
                    text: lookbook.isActive ? "Active" : "Archived",
                    color: lookbook.isActive ? RSMSTheme.success : RSMSTheme.textSecondary
                )
                .padding(10)
            }
            .frame(height: 180)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(lookbook.title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label(lookbook.season, systemImage: "leaf.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.primary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 10))
                        Text("\(lookbook.imageURLs.count)")
                            .font(.caption)
                    }
                    .foregroundStyle(RSMSTheme.textTertiary)
                }

                if let description = lookbook.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

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

    private var cardPlaceholder: some View {
        ZStack {
            RSMSTheme.surfaceTertiary
            VStack(spacing: 8) {
                Image(systemName: "book.pages")
                    .font(.system(size: 32))
                    .foregroundStyle(RSMSTheme.textTertiary)
                Text("No Preview")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .frame(height: 180)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("No Lookbooks Found")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textSecondary)

            if !lookbookVM.searchText.isEmpty || lookbookVM.selectedSeason != nil {
                Text("Try adjusting your search or filter.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)

                Button("Clear Filters") {
                    withAnimation {
                        lookbookVM.searchText = ""
                        lookbookVM.selectedSeason = nil
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.primary)
            } else {
                Text("No lookbooks have been published yet.\nThey will appear here once added to the system.")
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
