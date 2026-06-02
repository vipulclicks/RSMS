import SwiftUI

// MARK: - KPI Card

struct KPICard: View {
    let icon: String
    let value: String
    let label: String
    var trend: String? = nil
    var trendColor: Color = RSMSTheme.success
    var iconColor: Color = RSMSTheme.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                Spacer()
                if let trend {
                    Text(trend)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(trendColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            
            Spacer(minLength: 0)
            
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 128)
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

