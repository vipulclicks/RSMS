//
//  Theme.swift
//  RSMS
//
//  Deep Emerald & Gold luxury design system for Maison Lumière.
//

import SwiftUI

// MARK: - Design Tokens

enum RSMSTheme {
    // Internal Asset References
    private static let beige = Color("beige")
    private static let darkRed = Color("darkRed")
    private static let lightBrown = Color("lightBrown")
    private static let magenta = Color("magenta")

    // Backgrounds — Luxury Ivory & Beige
    static let background       = beige
    static let surfacePrimary   = lightBrown
    static let surfaceSecondary = lightBrown.opacity(0.8)
    static let surfaceTertiary  = lightBrown.opacity(0.9)

    // Primary palette — Luxury Burgundy
    static let primary      = magenta
    static let primaryLight = magenta.opacity(0.85)
    static let primaryDark = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0x70/255.0, green: 0x1A/255.0, blue: 0x30/255.0, alpha: 1.0)
            : UIColor(red: 0x54/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1.0)
    })

    // Legacy aliases
    static let gold = primary
    static let goldGradient = primaryGradient

    // Text — Deep Maroon
    static let cream         = Color.white
    static let textPrimary   = darkRed
    static let textSecondary = darkRed.opacity(0.75)
    static let textTertiary  = darkRed.opacity(0.55)

    // Semantic (Adjusted for light theme)
    static let success = Color(red: 45 / 255.0, green: 122 / 255.0, blue: 93 / 255.0)
    static let warning = Color(red: 179 / 255.0, green: 125 / 255.0, blue: 42 / 255.0)
    static let danger  = Color(red: 179 / 255.0, green: 58 / 255.0, blue: 58 / 255.0)
    static let info    = Color(red: 43 / 255.0, green: 115 / 255.0, blue: 138 / 255.0)

    // Divider / Border
    static let divider = darkRed.opacity(0.10)
    static let border  = darkRed.opacity(0.08)

    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [beige, lightBrown.opacity(0.8), beige],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let primaryGradient = LinearGradient(
        colors: [magenta, magenta.opacity(0.85), primaryDark],
        startPoint: .leading, endPoint: .trailing
    )
}
