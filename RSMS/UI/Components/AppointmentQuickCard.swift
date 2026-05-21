import SwiftUI

struct AppointmentQuickCard: View {
    let appointment: Appointment
    let clientName: String
    let statusColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // AccentBarHeader
            Rectangle()
                .fill(statusColor)
                .frame(height: 4)

            // Inner Content
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    AppointmentTypeIconView(type: appointment.type)
                    Spacer()
                    StatusBadge(
                        text: appointment.status.displayName,
                        color: statusColor
                    )
                }

                Text(clientName)
                    .font(.headline)
                    .fontDesign(.serif)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(2)
                    .frame(height: 44, alignment: .topLeading)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(appointment.dateTime, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            .padding(14)
        }
        .frame(width: 220)
        .rsmsCard(padding: 0)
    }
}

// MARK: - Appointment Type Icon View

struct AppointmentTypeIconView: View {
    let type: AppointmentType

    var body: some View {
        ZStack {
            Circle()
                .fill(typeColor(type).opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: typeIcon(type))
                .font(.subheadline)
                .foregroundStyle(typeColor(type))
        }
    }

    private func typeIcon(_ type: AppointmentType) -> String {
        switch type {
        case .inStore: return "building.2.fill"
        case .video:   return "video.fill"
        case .phone:   return "phone.fill"
        }
    }

    private func typeColor(_ type: AppointmentType) -> Color {
        switch type {
        case .inStore: return RSMSTheme.primary
        case .video:   return RSMSTheme.info
        case .phone:   return RSMSTheme.success
        }
    }
}

// MARK: - AppointmentStatus Extension

extension AppointmentStatus {
    var displayName: String {
        switch self {
        case .scheduled:  return "Scheduled"
        case .confirmed:  return "Confirmed"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        case .noShow:     return "No Show"
        }
    }
}
