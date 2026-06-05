//
//  ProfileAvatarView.swift
//  RSMS
//
//

import SwiftUI

struct ProfileAvatarView: View {
    let avatarURL: String?
    let initials: String
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            if let urlString = avatarURL, !urlString.isEmpty, let url = URL(string: urlString) {
                if url.scheme == "file" {
                    // Local-only file path (legacy/offline)
                    if let image = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        fallbackView
                    }
                } else {
                    // Cloud URL — use AsyncImage
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            // Cloud fetch failed — try local cache
                            localCacheOrFallback
                        default:
                            // Loading state — try local cache for instant display
                            ZStack {
                                localCacheOrFallback
                                ProgressView()
                                    .tint(.white.opacity(0.7))
                            }
                        }
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    /// Try to load a locally cached avatar image from Documents directory.
    @ViewBuilder
    private var localCacheOrFallback: some View {
        if let cached = loadLocalCache() {
            Image(uiImage: cached)
                .resizable()
                .scaledToFill()
        } else {
            fallbackView
        }
    }

    private func loadLocalCache() -> UIImage? {
        // Attempt to extract a user ID from the avatar URL path
        // The URL pattern is: .../avatars/<uuid>.jpg?t=...
        guard let urlString = avatarURL,
              let url = URL(string: urlString) else { return nil }
        let filename = url.lastPathComponent  // e.g. "abc123.jpg"
        let baseName = filename.components(separatedBy: "?").first ?? filename
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let localPath = docsPath?.appendingPathComponent("avatar_\(baseName.replacingOccurrences(of: ".jpg", with: "")).jpg") else { return nil }
        // Try matching by the UUID-based naming convention used in saveImageLocally
        if FileManager.default.fileExists(atPath: localPath.path) {
            return UIImage(contentsOfFile: localPath.path)
        }
        return nil
    }

    private var fallbackView: some View {
        ZStack {
            Circle()
                .fill(RSMSTheme.primaryGradient)

            Text(initials)
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
