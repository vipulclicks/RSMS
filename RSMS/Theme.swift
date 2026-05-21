//
//  Theme.swift
//  RSMS
//
//  Luxury Ivory & Burgundy design system for Maison Lumière.
//

import SwiftUI

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Design Tokens

enum RSMSTheme {

    // Internal Asset References
    private static let beige      = Color("beige")
    private static let darkRed    = Color("darkRed")
    private static let lightBrown = Color("lightBrown")
    private static let magenta    = Color("magenta")

    // Backgrounds — Luxury Ivory & Beige
    static let background       = beige
    static let surfacePrimary   = lightBrown
    static let surfaceSecondary = lightBrown.opacity(0.80)
    static let surfaceTertiary  = lightBrown.opacity(0.90)

    // Primary palette — Luxury Burgundy
    static let primary      = magenta
    static let primaryLight = magenta.opacity(0.85)
    static let primaryDark  = darkRed

    // Legacy aliases — keep all call-sites compiling without edits
    static let gold         = primary
    static let goldGradient = primaryGradient

    // Text — Deep Maroon on Ivory
    static let cream         = Color.white
    static let textPrimary   = darkRed
    static let textSecondary = darkRed.opacity(0.75)
    static let textTertiary  = darkRed.opacity(0.55)

    // Semantic — darkened for legibility on light backgrounds
    static let success = Color(red:  45 / 255.0, green: 122 / 255.0, blue:  93 / 255.0)
    static let warning = Color(red: 179 / 255.0, green: 125 / 255.0, blue:  42 / 255.0)
    static let danger  = Color(red: 179 / 255.0, green:  58 / 255.0, blue:  58 / 255.0)
    static let info    = Color(red:  43 / 255.0, green: 115 / 255.0, blue: 138 / 255.0)

    // Divider / Border
    static let divider = darkRed.opacity(0.10)
    static let border  = darkRed.opacity(0.08)

    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [beige, lightBrown.opacity(0.80), beige],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let primaryGradient = LinearGradient(
        colors: [magenta, magenta.opacity(0.85), darkRed],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - Card Modifier

struct RSMSCardModifier: ViewModifier {
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(RSMSTheme.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func rsmsCard(padding: CGFloat = 20) -> some View {
        modifier(RSMSCardModifier(padding: padding))
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - KPI Card

struct KPICard: View {
    let icon: String
    let value: String
    let label: String
    var trend: String? = nil
    var trendColor: Color = RSMSTheme.success
    var iconColor: Color = RSMSTheme.gold

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                Spacer()
                if let trend {
                    Text(trend)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(trendColor)
                }
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .rsmsCard()
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
    }
}

// MARK: - Circular Progress

struct CircularProgressView: View {
    let progress: Double
    let label: String
    let value: String
    var size: CGFloat = 140

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(RSMSTheme.surfaceTertiary, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(RSMSTheme.gold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            .frame(width: size, height: size)
        }
    }
}
