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
    // Backgrounds — Luxury Ivory & Beige
    static let background       = Color(hex: "F1E2D1")
    static let surfacePrimary   = Color(hex: "DCC3AA")
    static let surfaceSecondary = Color(hex: "D3B69C")
    static let surfaceTertiary  = Color(hex: "C9A98E")

    // Primary palette — Luxury Burgundy
    static let primary      = Color(hex: "810B38")
    static let primaryLight = Color(hex: "A32D5A")
    static let primaryDark  = Color(hex: "540623")

    // Text — Deep Maroon
    static let cream         = Color(hex: "FFFFFF")
    static let textPrimary   = Color(hex: "541A1A")
    static let textSecondary = Color(hex: "7A3A3A")
    static let textTertiary  = Color(hex: "9C6060")

    // Semantic (Adjusted for light theme)
    static let success = Color(hex: "2D7A5D")
    static let warning = Color(hex: "B37D2A")
    static let danger  = Color(hex: "B33A3A")
    static let info    = Color(hex: "2B738A")

    // Divider / Border
    static let divider = Color.black.opacity(0.08)
    static let border  = Color.black.opacity(0.06)

    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "F1E2D1"), Color(hex: "EBD9C5"), Color(hex: "F1E2D1")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "810B38"), Color(hex: "A32D5A"), Color(hex: "810B38")],
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(RSMSTheme.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 6)
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
    var iconColor: Color = RSMSTheme.primary

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
                    .stroke(RSMSTheme.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
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

// MARK: - Custom Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
