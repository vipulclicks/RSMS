import SwiftUI

struct AppointmentsInventoryView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var dashboardVM = BoutiqueDashboardViewModel()

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
                    VStack(alignment: .leading, spacing: 32) {
                        appointmentsSection
                        inventorySection
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
            }
        }
    }

    // MARK: - Appointments Section
    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Today's Appointments", subtitle: "Scheduled clients for today")
            
            let todaysAppointments = appVM.dataStore.appointments.filter {
                Calendar.current.isDateInToday($0.dateTime)
            }.sorted { $0.dateTime < $1.dateTime }
            
            if todaysAppointments.isEmpty {
                Text("No appointments scheduled for today.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(todaysAppointments) { appointment in
                        let clientName = appVM.dataStore.clientName(for: appointment.clientId)
                        let associateName = appVM.dataStore.userName(for: appointment.associateId)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(clientName)
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Spacer()
                                StatusBadge(text: appointment.status.rawValue, color: statusColor(for: appointment.status))
                            }
                            
                            Divider().overlay(RSMSTheme.divider)
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Text(appointment.dateTime.formatted(date: .omitted, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Text("With \(associateName)")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            
                            if let notes = appointment.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                    .lineLimit(2)
                                    .padding(.top, 4)
                            }
                        }
                        .rsmsCard(padding: 16)
                    }
                }
            }
        }
    }

    // MARK: - Inventory Section
    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Low Stock Alerts", subtitle: "Items running low on stock")
            
            if dashboardVM.lowStockAlerts.isEmpty {
                Text("Inventory levels are healthy.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(dashboardVM.lowStockAlerts) { alert in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(alert.product.name)
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("Qty: \(alert.stockItem.quantity)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(RSMSTheme.danger)
                            }
                            
                            Text("SKU: \(alert.product.sku)")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                            Text(alert.product.category)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RSMSTheme.surfaceTertiary)
                                .clipShape(Capsule())
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                        }
                        .rsmsCard(padding: 16)
                    }
                }
            }
        }
    }
    
    private func statusColor(for status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled: return RSMSTheme.info
        case .confirmed: return RSMSTheme.info
        case .inProgress: return RSMSTheme.primary
        case .completed: return RSMSTheme.success
        case .cancelled: return RSMSTheme.danger
        case .noShow: return RSMSTheme.warning
        }
    }
}
