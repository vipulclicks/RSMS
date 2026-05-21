//
//  LuxuryFormComponents.swift
//  RSMS
//

import SwiftUI

// MARK: - Luxury Card Container

struct LuxuryFormCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(RSMSTheme.primary)
                Text(title.uppercased())
                    .font(.subheadline.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding(.bottom, 4)

            content()
        }
        .padding(24)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Luxury Text Field

struct LuxuryTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            TextField("", text: $text)
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(RSMSTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
        }
    }
}

// MARK: - Luxury Picker (Menu-based)

struct LuxuryPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection = option }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? "Select" : selection)
                        .foregroundStyle(
                            selection.isEmpty ? RSMSTheme.textSecondary : RSMSTheme.textPrimary
                        )
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(RSMSTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
            }
        }
    }
}
