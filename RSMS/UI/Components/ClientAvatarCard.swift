import SwiftUI

struct ClientAvatarCard: View {
    let client: ClientProfile
    var spending: Double? = nil
    var avatarSize: CGFloat = 52
    var cardWidth: CGFloat = 72

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
                    .frame(width: avatarSize, height: avatarSize)
                Text(initials)
                    .font(.system(size: avatarSize * 0.35, weight: .semibold))
                    
                    .foregroundStyle(RSMSTheme.primary)

                if client.vipTier != .standard {
                    VIPDotIndicator(tier: client.vipTier, size: avatarSize)
                }
            }

            VStack(spacing: 2) {
                Text(firstName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if let spending = spending {
                    Text(spending, format: .currency(code: "INR"))
                        .font(.system(size: 10))
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: cardWidth)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spending != nil ? "\(client.fullName), \(client.vipTier.rawValue) client, spent \(spending!, format: .currency(code: "INR"))" : "\(client.fullName), \(client.vipTier.rawValue) client")
    }
}

// MARK: - VIP Dot Indicator

struct VIPDotIndicator: View {
    let tier: VIPTier
    var size: CGFloat = 52

    var body: some View {
        let dotSize = size * 0.2
        let offsetVal = size * 0.35
        
        Circle()
            .fill(tierColor)
            .frame(width: dotSize, height: dotSize)
            .overlay(Circle().stroke(RSMSTheme.background, lineWidth: 1.5))
            .offset(x: offsetVal, y: offsetVal)
    }

    private var tierColor: Color {
        switch tier {
        case .standard: return RSMSTheme.textSecondary
        case .silver:   return Color(red: 192/255, green: 192/255, blue: 192/255)
        case .gold:     return RSMSTheme.primary
        case .platinum: return Color(red: 176/255, green: 196/255, blue: 222/255)
        case .prive:    return RSMSTheme.danger
        case .vip:      return RSMSTheme.primaryDark
        }
    }
}
