import SwiftUI

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
                        .font(.system(size: 22, weight: .bold))
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
