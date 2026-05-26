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
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cycle Counts")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Physical verification of stock levels")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()

                if cycleCountVM.openMismatches > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("\(cycleCountVM.openMismatches) Mismatch\(cycleCountVM.openMismatches == 1 ? "" : "es")")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(RSMSTheme.danger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(RSMSTheme.danger.opacity(0.1)))
                }
            }

            // KPI Cards Row
            cycleCountKPIRow

            // Pending Items
            if !cycleCountVM.pendingItems.isEmpty {
                cycleCountPendingList
            } else {
                cycleCountAllClear
            }

            // Verified / Checked toggle
            if !cycleCountVM.checkedItems.isEmpty {
                cycleCountCheckedSection
            }
        }
    }

    // MARK: Cycle Count KPI Row
    private var cycleCountKPIRow: some View {
        HStack(spacing: 14) {
            cycleCountKPICard(
                icon: "shippingbox.fill",
                value: "\(cycleCountVM.totalInventory)",
                label: "Total Inventory",
                color: RSMSTheme.gold
            )
            cycleCountKPICard(
                icon: "clock.badge.exclamationmark.fill",
                value: "\(cycleCountVM.pendingItems.count)",
                label: "Pending Checks",
                color: RSMSTheme.warning
            )
            cycleCountKPICard(
                icon: "exclamationmark.triangle.fill",
                value: "\(cycleCountVM.openMismatches)",
                label: "Mismatches",
                color: cycleCountVM.openMismatches > 0 ? RSMSTheme.danger : RSMSTheme.success
            )
        }
    }

    private func cycleCountKPICard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: Cycle Count Pending List
    private var cycleCountPendingList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PENDING VERIFICATION")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Text("\(cycleCountVM.pendingItems.count) items")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(cycleCountVM.pendingItems.prefix(6).enumerated()), id: \.element.id) { index, item in
                    Button {
                        cycleCountVM.enteredCount = "\(item.expectedQty)"
                        cycleCountVM.itemToCount = item
                    } label: {
                        cycleCountPendingRow(item)
                    }
                    .buttonStyle(.plain)

                    if index < min(cycleCountVM.pendingItems.count, 6) - 1 {
                        Rectangle()
                            .fill(RSMSTheme.divider)
                            .frame(height: 0.5)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(RSMSTheme.surfacePrimary)
                    .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(RSMSTheme.warning.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func cycleCountPendingRow(_ item: CycleCountItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.warning.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(RSMSTheme.warning)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.product.sku)
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("·")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("Expected: \(item.expectedQty)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                if let last = item.lastChecked {
                    Text("Last checked \(last.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.warning.opacity(0.8))
                } else {
                    Text("Never verified")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.danger.opacity(0.8))
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.gold.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Cycle Count All Clear
    private var cycleCountAllClear: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(RSMSTheme.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("All products verified")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("No cycle counts overdue")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(RSMSTheme.success.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: Cycle Count Checked Section
    private var cycleCountCheckedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showCheckedItems.toggle()
                }
            } label: {
                HStack {
                    Text("VERIFIED THIS PERIOD")
                        .font(.caption.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(RSMSTheme.gold)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(cycleCountVM.checkedItems.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.success)
                        Image(systemName: showCheckedItems ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)

            if showCheckedItems {
                VStack(spacing: 0) {
                    ForEach(Array(cycleCountVM.checkedItems.prefix(10).enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(RSMSTheme.success.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(RSMSTheme.success)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.product.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                    .lineLimit(1)
                                Text(item.product.sku)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }

                            Spacer(minLength: 0)

                            if let date = item.lastChecked {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(RSMSTheme.success.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if index < min(cycleCountVM.checkedItems.count, 10) - 1 {
                            Rectangle()
                                .fill(RSMSTheme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(RSMSTheme.surfacePrimary)
                        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(RSMSTheme.success.opacity(0.2), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: Cycle Count Sheet
    private func cycleCountSheet(for item: CycleCountItem) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Product header
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(RSMSTheme.gold.opacity(0.12))
                                .frame(width: 64, height: 64)
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 28))
                                .foregroundStyle(RSMSTheme.gold)
                        }
                        Text(item.product.name)
                            .font(.headline.bold())
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(item.product.sku)
                            .font(.caption.monospaced())
                            .foregroundStyle(RSMSTheme.gold)
                    }
                    .padding(.top, 8)

                    // Expected vs entry
                    VStack(spacing: 0) {
                        HStack {
                            Text("System Qty")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Spacer()
                            Text("\(item.expectedQty) units")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        Rectangle().fill(RSMSTheme.divider).frame(height: 0.5).padding(.horizontal, 16)

                        HStack {
                            Text("Actual Count")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Spacer()
                            TextField("0", text: $cycleCountVM.enteredCount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.title3.bold())
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))

                    // Variance preview
                    if let actual = Int(cycleCountVM.enteredCount), actual != item.expectedQty {
                        let diff = actual - item.expectedQty
                        HStack(spacing: 8) {
                            Image(systemName: diff > 0 ? "plus.circle.fill" : "minus.circle.fill")
                                .foregroundStyle(diff > 0 ? RSMSTheme.success : RSMSTheme.danger)
                            Text("Variance of \(abs(diff)) will be logged as a mismatch")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(diff > 0 ? RSMSTheme.success : RSMSTheme.danger)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((diff > 0 ? RSMSTheme.success : RSMSTheme.danger).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Submit
                    Button {
                        guard let user = appVM.currentUser else { return }
                        Task {
                            await cycleCountVM.submitCount(
                                for: item,
                                dataStore: appVM.dataStore,
                                user: user
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if cycleCountVM.isSaving {
                                ProgressView().tint(RSMSTheme.background)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Submit Count")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RSMSTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(cycleCountVM.isSaving || cycleCountVM.enteredCount.isEmpty || appVM.currentUser == nil)
                }
                .padding(20)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ENTER COUNT")
                        .font(.system(.caption, design: .serif, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { cycleCountVM.itemToCount = nil }
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
