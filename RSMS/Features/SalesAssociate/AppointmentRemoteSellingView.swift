//
//  AppointmentRemoteSellingView.swift
//  RSMS
//
//  Appointments, remote selling, and curated carts.
//

import SwiftUI

struct AppointmentRemoteSellingView: View {
    @State private var viewModel = AppointmentRemoteSellingViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                HStack(alignment: .top, spacing: 16) {
                    appointmentsColumn
                    remoteSellingColumn
                }
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Appointments & Remote Selling")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            SectionHeader(title: "Upcoming Schedule", subtitle: "Manage appointments and curated selections")
            Spacer()
        }
    }

    // MARK: - Appointments Column

    private var appointmentsColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Appointments")

            // Appointment card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(RSMSTheme.gold.opacity(0.1))
                            .frame(width: 48, height: 48)
                        Text(String(viewModel.client.fullName.prefix(1)))
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.client.fullName)'s Appointment")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        StatusBadge(text: viewModel.client.vipTier.rawValue, color: RSMSTheme.gold)
                    }

                    Spacer()

                    StatusBadge(
                        text: viewModel.appointment.status.rawValue.replacingOccurrences(of: "_", with: " "),
                        color: viewModel.appointmentStatusColor(viewModel.appointment.status)
                    )
                }

                Divider().overlay(RSMSTheme.divider)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    infoChip(icon: "calendar", label: "Date", value: viewModel.formattedDate(viewModel.appointment.dateTime))
                    infoChip(icon: "clock.fill", label: "Duration", value: "\(viewModel.appointment.durationMinutes) min")
                    infoChip(icon: "building.2.fill", label: "Type", value: viewModel.appointment.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    infoChip(icon: "mappin.circle.fill", label: "Location", value: "Paris Vendôme")
                }

                if let notes = viewModel.appointment.notes {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "text.quote")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.gold)
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .italic()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(RSMSTheme.surfaceSecondary)
                    )
                }

                if let videoLink = viewModel.appointment.videoLink {
                    HStack {
                        Image(systemName: "video.fill")
                            .foregroundStyle(RSMSTheme.info)
                        Text(videoLink)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.info)
                    }
                }
            }
            .rsmsCard()

            // Quick stats
            HStack(spacing: 12) {
                miniStat(icon: "checkmark.circle.fill", value: "1", label: "Confirmed", color: RSMSTheme.success)
                miniStat(icon: "clock.fill", value: "60m", label: "Duration", color: RSMSTheme.info)
                miniStat(icon: "person.fill", value: "VIP", label: "Priority", color: RSMSTheme.gold)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Remote Selling Column

    private var remoteSellingColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Curated Carts")

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selection for \(viewModel.client.fullName)")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Prepared by Lucas Dubois")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    Spacer()
                    StatusBadge(
                        text: viewModel.curatedCart.status.rawValue,
                        color: viewModel.cartStatusColor(viewModel.curatedCart.status)
                    )
                }

                Divider().overlay(RSMSTheme.divider)

                if let note = viewModel.curatedCart.note {
                    Text("\"\(note)\"")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .italic()
                }

                // Cart items
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.surfaceSecondary)
                            .frame(width: 60, height: 60)
                        Image(systemName: "watch.analog")
                            .font(.title2)
                            .foregroundStyle(RSMSTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.cartProduct?.name ?? "Product")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        if let product = viewModel.cartProduct {
                            Text("€\(String(format: "%,.0f", product.price)) · \(product.category)")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }

                    Spacer()

                    if let itemNote = viewModel.curatedItem.note {
                        Text(itemNote)
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .frame(maxWidth: 120)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RSMSTheme.surfaceSecondary)
                )
            }
            .rsmsCard()

            // Remote selling options
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Remote Selling Tools")

                toolRow(icon: "video.fill", title: "Video Consultation", subtitle: "Start a live session", color: RSMSTheme.info)
                toolRow(icon: "envelope.fill", title: "Share Cart", subtitle: "Send curated selection", color: RSMSTheme.gold)
                toolRow(icon: "message.fill", title: "Follow Up", subtitle: "Send appointment reminder", color: RSMSTheme.success)
            }
            .rsmsCard()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sub-components

    private func infoChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RSMSTheme.gold)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(RSMSTheme.surfaceSecondary))
    }

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .rsmsCard(padding: 14)
    }

    private func toolRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        return f.string(from: date)
    }

    private func appointmentStatusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled:  return RSMSTheme.info
        case .confirmed:  return RSMSTheme.success
        case .inProgress: return RSMSTheme.warning
        case .completed:  return RSMSTheme.textSecondary
        case .cancelled:  return RSMSTheme.danger
        case .noShow:     return RSMSTheme.danger
        }
    }

    private func cartStatusColor(_ status: CartStatus) -> Color {
        switch status {
        case .draft:     return RSMSTheme.textSecondary
        case .shared:    return RSMSTheme.info
        case .viewed:    return RSMSTheme.warning
        case .converted: return RSMSTheme.success
        case .expired:   return RSMSTheme.danger
        case .active, .completed, .abandoned: return RSMSTheme.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        AppointmentRemoteSellingView()
    }
}
