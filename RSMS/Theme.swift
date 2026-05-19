//
//  Theme.swift
//  RSMS
//
//  Deep Emerald & Gold luxury design system for Maison Lumière.
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
    // Backgrounds — deep emerald tones
    static let background       = Color(hex: "0A1F1A")
    static let surfacePrimary   = Color(hex: "122C24")
    static let surfaceSecondary = Color(hex: "1A3D32")
    static let surfaceTertiary  = Color(hex: "234A3E")

    // Gold palette
    static let gold      = Color(hex: "D4A843")
    static let goldLight = Color(hex: "E8C96E")
    static let goldDark  = Color(hex: "9A7A2E")

    // Text — ivory & sage
    static let cream         = Color(hex: "F2EDE4")
    static let textPrimary   = Color(hex: "F2EDE4")
    static let textSecondary = Color(hex: "8FA99C")
    static let textTertiary  = Color(hex: "5E7A6E")

    // Semantic
    static let success = Color(hex: "5CB88A")
    static let warning = Color(hex: "DEBB4C")
    static let danger  = Color(hex: "D45B5B")
    static let info    = Color(hex: "4DA8B0")

    // Divider / Border
    static let divider = Color.white.opacity(0.08)
    static let border  = Color.white.opacity(0.06)

    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "0A1F1A"), Color(hex: "0E2920"), Color(hex: "0A1F1A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let goldGradient = LinearGradient(
        colors: [Color(hex: "D4A843"), Color(hex: "E8C96E"), Color(hex: "D4A843")],
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
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
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
