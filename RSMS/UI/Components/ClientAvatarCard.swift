import SwiftUI

struct ClientAvatarCard: View {
    let client: ClientProfile

    var initials: String {
        client.fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    var firstName: String {
        client.fullName.components(separatedBy: " ").first ?? client.fullName
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.primary.opacity(0.10))
                    .frame(width: 52, height: 52)
                Text(initials)
                    .font(.headline.weight(.semibold))
                    
                    .foregroundStyle(RSMSTheme.primary)

                if client.vipTier != .standard {
                    VIPDotIndicator(tier: client.vipTier)
                }
            }

            Text(firstName)
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(client.fullName), \(client.vipTier.rawValue) client")
    }
}

// MARK: - VIP Dot Indicator

struct VIPDotIndicator: View {
    let tier: VIPTier

    var body: some View {
        Circle()
            .fill(tierColor)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(RSMSTheme.background, lineWidth: 1.5))
            .offset(x: 18, y: 18)
    }

    private var tierColor: Color {
        switch tier {
        case .standard:
            return .clear
        case .silver:
            return Color(red: 192/255, green: 192/255, blue: 192/255)
        case .gold:
            return RSMSTheme.primary
        case .platinum:
            return Color(red: 176/255, green: 196/255, blue: 222/255)
        case .prive:
            return RSMSTheme.danger
        }
    }
}
