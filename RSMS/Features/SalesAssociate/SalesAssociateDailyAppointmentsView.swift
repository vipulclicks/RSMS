//
//  SalesAssociateDailyAppointmentsView.swift
//  RSMS
//

import SwiftUI

struct SalesAssociateDailyAppointmentsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let appointments: [Appointment]
    
    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            if appointments.isEmpty {
                ContentUnavailableView("No Appointments", systemImage: "calendar.badge.exclamationmark", description: Text("You have no appointments scheduled for today."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(appointments.sorted(by: { $0.dateTime < $1.dateTime })) { appt in
                            appointmentCard(appt)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Today's Appointments")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func appointmentCard(_ appt: Appointment) -> some View {
        let clientName = appViewModel.dataStore.clientName(for: appt.clientId)
        let timeString = appt.dateTime.formatted(date: .omitted, time: .shortened)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clientName)
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(timeString)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                
                statusBadge(appt.status)
            }
            
            if let notes = appt.notes, !notes.isEmpty {
                Divider().background(RSMSTheme.divider)
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 2)
    }
    
    private func statusBadge(_ status: AppointmentStatus) -> some View {
        let color: Color
        switch status {
        case .completed: color = RSMSTheme.success
        case .scheduled: color = RSMSTheme.info
        case .confirmed: color = RSMSTheme.primary
        case .inProgress: color = RSMSTheme.warning
        case .cancelled, .noShow: color = RSMSTheme.danger
        }
        
        return Text(status.rawValue.capitalized)
            .font(.caption.weight(.bold))
            .foregroundStyle(RSMSTheme.cream)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color, in: Capsule())
    }
}
