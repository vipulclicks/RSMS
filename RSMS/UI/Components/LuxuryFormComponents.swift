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
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .foregroundStyle(RSMSTheme.primary)
                }
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

            // Styled static picker container
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
            // Invisible menu overlay to capture taps and display options
            .overlay {
                Menu {
                    ForEach(options, id: \.self) { option in
                        Button(option) {
                            // Dismiss keyboard first to prevent layout jumping
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            selection = option
                        }
                    }
                } label: {
                    Color.clear
                        .contentShape(Rectangle())
                }
            }
        }
    }
}

// MARK: - India-Specific Size Presets Registry

struct SizePresetCategory {
    let name: String
    let options: [String]
}

enum LuxurySizePresets {
    // MARK: Rings
    static let rings: [SizePresetCategory] = [
        SizePresetCategory(name: "Women's — India (Numerical)", options: [
            "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"
        ]),
        SizePresetCategory(name: "Men's — India (Numerical)", options: [
            "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25"
        ]),
        SizePresetCategory(name: "Women's — UK/India (Letter)", options: [
            "H (Small)", "I", "J", "K", "L (Medium)", "M", "N", "O (Large)", "P"
        ]),
        SizePresetCategory(name: "Men's — UK/India (Letter)", options: [
            "Q", "R", "S (Medium)", "T", "U", "V (Large)", "W", "X (XL)"
        ]),
        SizePresetCategory(name: "European (Cartier / EU)", options: [
            "46", "48", "50", "52", "54", "56", "58", "60", "62", "64", "66"
        ]),
        SizePresetCategory(name: "US (Tiffany / Bulgari)", options: [
            "US 4", "US 4.5", "US 5", "US 5.5", "US 6", "US 6.5",
            "US 7", "US 7.5", "US 8", "US 8.5", "US 9", "US 9.5", "US 10"
        ])
    ]

    // MARK: Shoes
    static let shoes: [SizePresetCategory] = [
        SizePresetCategory(name: "Women's — India / UK", options: [
            "UK 3", "UK 3.5", "UK 4", "UK 4.5", "UK 5",
            "UK 5.5", "UK 6", "UK 6.5", "UK 7", "UK 7.5", "UK 8"
        ]),
        SizePresetCategory(name: "Women's — Luxury EU / IT (Gucci, Louboutin)", options: [
            "35", "35.5", "36", "36.5", "37", "37.5",
            "38", "38.5", "39", "39.5", "40", "40.5", "41"
        ]),
        SizePresetCategory(name: "Men's — India / UK", options: [
            "UK 5", "UK 6", "UK 7", "UK 8", "UK 9", "UK 10", "UK 11", "UK 12"
        ]),
        SizePresetCategory(name: "Men's — Luxury EU / IT (Gucci, Berluti)", options: [
            "39", "40", "41", "42", "43", "44", "45", "46"
        ])
    ]

    // MARK: Belts
    static let belts: [SizePresetCategory] = [
        SizePresetCategory(name: "Waist Size — Named & Inches", options: [
            "XS / 28\"",
            "S / 30\"",
            "M / 32\"",
            "L / 34\"",
            "XL / 36\"",
            "2XL / 38\"",
            "3XL / 40\"",
            "4XL / 42\""
        ]),
        SizePresetCategory(name: "Luxury Belt — Centimeters (Hermès, Gucci)", options: [
            "75 cm", "80 cm", "85 cm", "90 cm", "95 cm",
            "100 cm", "105 cm", "110 cm", "115 cm", "120 cm"
        ])
    ]

    // MARK: Necklaces
    static let necklaces: [SizePresetCategory] = [
        SizePresetCategory(name: "Named Necklace Styles", options: [
            "Collar (14\" / 35 cm)",
            "Choker (16\" / 40 cm)",
            "Princess (18\" / 45 cm)",
            "Matinee (20\" / 50 cm)",
            "Opera Short (22\" / 55 cm)",
            "Opera Long (24\" / 60 cm)",
            "Rope (30\" / 75 cm)"
        ])
    ]

    // MARK: Bracelets
    static let bracelets: [SizePresetCategory] = [
        SizePresetCategory(name: "Bracelet Sizes — Named (Cartier / Hermès)", options: [
            "XS (15 cm)",
            "S (16 cm)",
            "M (17 cm)",
            "L (18 cm)",
            "XL (19 cm)",
            "XXL (20 cm)",
            "3XL (21 cm)"
        ])
    ]

    // MARK: Wrist Sizes
    static let wristSizes: [SizePresetCategory] = [
        SizePresetCategory(name: "Wrist Size — Watch Strap Fit", options: [
            "Very Small (14 cm)",
            "Small (15 cm)",
            "Small-Medium (15.5 cm)",
            "Medium (16 cm)",
            "Medium (16.5 cm)",
            "Medium-Large (17 cm)",
            "Large (17.5 cm)",
            "Large (18 cm)",
            "Extra Large (19 cm)",
            "Extra Large (20 cm)",
            "XXL (21 cm)"
        ])
    ]
}

// MARK: - Luxury Size Field (Text Field + Preset Picker)

struct LuxurySizeField: View {
    let title: String
    @Binding var text: String
    let presets: [SizePresetCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)

            HStack(spacing: 0) {
                // Editable text field
                TextField("Enter or select…", text: $text)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .font(.subheadline)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .padding(.trailing, 8)

                // Divider
                Rectangle()
                    .fill(RSMSTheme.border)
                    .frame(width: 1, height: 24)

                // Preset picker button
                Menu {
                    ForEach(presets, id: \.name) { category in
                        Menu(category.name) {
                            ForEach(category.options, id: \.self) { option in
                                Button(option) {
                                    UIApplication.shared.sendAction(
                                        #selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil
                                    )
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        text = option
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(RSMSTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
            }
            .background(RSMSTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
    }
}
