import SwiftUI

// MARK: - View Extensions

extension View {
    func rsmsCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: RSMSTheme.textPrimary.opacity(0.05), radius: 15, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
    }
}

// MARK: - Reusable Components

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct KPICard: View {
    let icon: String
    let value: String
    let label: String
    var trend: String? = nil
    var trendColor: Color? = nil
    var iconColor: Color = RSMSTheme.gold
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            if let trend = trend, let trendColor = trendColor {
                Text(trend)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(trendColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rsmsCard(padding: 16)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let label: String
    let value: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(RSMSTheme.surfaceTertiary, lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                .stroke(
                    RSMSTheme.primaryGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
        .frame(width: 100, height: 100)
    }
}
