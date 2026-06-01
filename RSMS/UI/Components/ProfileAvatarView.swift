//
//  ProfileAvatarView.swift
//  RSMS
//
//  Created by Antigravity on 2026-06-01.
//

import SwiftUI

struct ProfileAvatarView: View {
    let avatarURL: String?
    let initials: String
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            if let urlString = avatarURL, let url = URL(string: urlString) {
                if url.scheme == "file" {
                    if let image = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        fallbackView
                    }
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackView
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
