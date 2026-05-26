import SwiftUI

struct AppointmentsInventoryView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var dashboardVM = BoutiqueDashboardViewModel()

    @State private var hasAppeared = false
    
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
                        
                        inventorySection
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

    // MARK: - Inventory Section
    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventory Operations")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Receive inbound stock and monitor low inventory.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                
                if !dashboardVM.lowStockAlerts.isEmpty {
                    HStack(spacing: 6) {
                        Circle().fill(RSMSTheme.danger).frame(width: 8, height: 8)
                        Text("\(dashboardVM.lowStockAlerts.count) Critical")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RSMSTheme.danger)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(RSMSTheme.danger.opacity(0.1)))
                }
            }

            receivingEntryCard
            
            if dashboardVM.lowStockAlerts.isEmpty {
                emptyInventoryState
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                    ForEach(dashboardVM.lowStockAlerts) { alert in
                        inventoryCard(for: alert)
                    }
                }
            }
        }
    }

    private var receivingEntryCard: some View {
        NavigationLink {
            InventoryReceivingView()
        } label: {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(RSMSTheme.primary.opacity(0.12))
                        .frame(width: 68, height: 68)
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Inventory Receiving & Put-Away")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Scan inbound stock, assign storage locations, and post updated quantities.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(RSMSTheme.primary)
            }
            .padding(22)
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
    
    private var emptyInventoryState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [RSMSTheme.success.opacity(0.1), RSMSTheme.success.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(RSMSTheme.success)
            }
            Text("Inventory Healthy")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("All products are currently well-stocked.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(RSMSTheme.surfacePrimary.opacity(0.5))
                .stroke(RSMSTheme.border.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func inventoryCard(for alert: LowStockAlert) -> some View {
        let isCritical = alert.stockItem.quantity == 0
        let accentColor = isCritical ? RSMSTheme.danger : RSMSTheme.warning
        
        return Button {
            // Action
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.surfaceTertiary)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: alert.product.category.lowercased() == "watches" ? "applewatch" : "sparkles")
                            .font(.system(size: 20))
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(alert.stockItem.quantity) left")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(accentColor)
                        Text("Low Stock")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accentColor.opacity(0.8))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.product.name)
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 6) {
                        Text("SKU:")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text(alert.product.sku)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .font(.caption)
                }
                Spacer()
                
                // Progress bar indicator
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(RSMSTheme.surfaceTertiary)
                            .frame(height: 6)
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width * CGFloat(max(0.1, Double(alert.stockItem.quantity) / 10.0)), height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(RSMSTheme.surfacePrimary)
                    .shadow(color: accentColor.opacity(0.08), radius: 15, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
