import SwiftUI

struct AppointmentsInventoryView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var dashboardVM = BoutiqueDashboardViewModel()
    @State private var cycleCountVM = CycleCountViewModel()

    @State private var hasAppeared = false
    @State private var showCheckedItems = false
    
    var body: some View {
        Group {
            if dashboardVM.isLoading {
                ProgressView("Loading Appointments & Inventory...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = dashboardVM.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        appointmentsSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: hasAppeared)
                        
                        cycleCountSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.15), value: hasAppeared)
                        
                        InventoryAlertsView(dashboardVM: dashboardVM)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: hasAppeared)
                    }
                    .padding(32)
                }
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Appointments & Inventory")
        .task {
            if let storeId = appVM.currentStoreId {
                await dashboardVM.load(dataStore: appVM.dataStore, storeId: storeId)
                await cycleCountVM.load(dataStore: appVM.dataStore, storeId: storeId)
                withAnimation {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Appointments Section
    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Appointments")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Scheduled clients for today")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                
                let count = appVM.dataStore.appointments.filter { Calendar.current.isDateInToday($0.dateTime) }.count
                if count > 0 {
                    Text("\(count)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(RSMSTheme.primary))
                }
            }
            
            let todaysAppointments = appVM.dataStore.appointments.filter {
                Calendar.current.isDateInToday($0.dateTime)
            }.sorted { $0.dateTime < $1.dateTime }
            
            if todaysAppointments.isEmpty {
                emptyAppointmentsState
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                    ForEach(todaysAppointments) { appointment in
                        appointmentCard(for: appointment)
                    }
                }
            }
        }
    }
    
    private var emptyAppointmentsState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [RSMSTheme.primary.opacity(0.1), RSMSTheme.primary.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 32))
                    .foregroundStyle(RSMSTheme.primary)
            }
            Text("No Appointments Today")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Take this time to review inventory or assist walk-ins.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(RSMSTheme.surfacePrimary.opacity(0.5))
                .stroke(RSMSTheme.border.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func appointmentCard(for appointment: Appointment) -> some View {
        let clientName = appVM.dataStore.clientName(for: appointment.clientId)
        let associateName = appVM.dataStore.userName(for: appointment.associateId)
        
        return Button {
            // Action if needed
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(clientName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(RSMSTheme.primary)
                            Text(appointment.dateTime.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }
                    Spacer()
                    
                    Text(appointment.status.rawValue)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(statusColor(for: appointment.status).opacity(0.15))
                        .foregroundStyle(statusColor(for: appointment.status))
                        .clipShape(Capsule())
                }
                
                Divider()
                    .overlay(RSMSTheme.border.opacity(0.5))
                
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(RSMSTheme.surfaceTertiary)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            )
                        Text(associateName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    Spacer()
                    if let notes = appointment.notes, !notes.isEmpty {
                        Image(systemName: "note.text")
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(RSMSTheme.surfacePrimary)
                    .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Cycle Count Section
    private var cycleCountSection: some View {
        CycleCountSectionView(cycleCountVM: cycleCountVM)
    }

    private func statusColor(for status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled: return RSMSTheme.primary
        case .confirmed: return RSMSTheme.info
        case .inProgress: return RSMSTheme.warning
        case .completed: return RSMSTheme.success
        case .cancelled: return RSMSTheme.danger
        case .noShow: return RSMSTheme.textTertiary
        }
    }
}
