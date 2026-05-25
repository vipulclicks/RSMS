//
//  ShiftMonitorView.swift
//  RSMS
//
//  Boutique Manager — Today's Shift Monitor.
//  Ultra-premium Apple-style redesign using minimalistic luxury aesthetics.
//  Strictly adheres to the Ivory/Beige/Maroon theme. NO semantic greens/blues.
//

import SwiftUI

struct ShiftMonitorView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var vm = ShiftManagementViewModel()
    @State private var showAddSheet = false
    @State private var shiftToEdit: StaffShift? = nil
    @State private var selectedStatus: ShiftStatus? = nil
    @State private var selectedRole: String? = nil
    @Namespace private var animation

    private let roles = ["Back Office", "Cashier", "Floor", "VIP Lounge", "Sales Associate"]

    var filteredShifts: [StaffShift] {
        var result = vm.shifts
        if let status = selectedStatus {
            result = result.filter { vm.status(for: $0) == status }
        }
        if let role = selectedRole {
            let roleKey = role.replacingOccurrences(of: " ", with: "_").lowercased()
            result = result.filter { $0.role.lowercased() == roleKey }
        }
        return result
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading Shifts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.errorMessage {
                ContentUnavailableView(
                    "Error Loading Data",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        headerSection
                            .padding(.top, 16)
                        
                        summaryStrip
                        
                        filterSection
                        
                        shiftsList
                    }
                    .padding(.horizontal, 48)
                    .padding(.bottom, 60)
                }
                .background(RSMSTheme.backgroundGradient.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            shiftToEdit = nil
                            showAddSheet.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Add Shift")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    }
                }
                .sheet(isPresented: $showAddSheet) {
                    AddShiftView(vm: vm, shiftToEdit: shiftToEdit)
                }
            }
        }
        .task {
            if let storeId = appVM.currentStoreId {
                await vm.load(dataStore: appVM.dataStore, storeId: storeId)
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Shifts")
                .font(.system(size: 34, weight: .heavy, design: .default))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            HStack(spacing: 8) {
                Text(dateString)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(RSMSTheme.primary)
                        .frame(width: 6, height: 6)
                        .opacity(isBlinking ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isBlinking)
                    
                    Text("LIVE · \(clockString)")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(RSMSTheme.primary)
                }
                .onAppear { isBlinking = true }
            }
        }
    }
    
    @State private var isBlinking = false

    // MARK: - Summary Strip
    private var summaryStrip: some View {
        HStack(spacing: 16) {
            summaryCard(count: vm.activeCount, label: "Active", icon: "bolt.fill", highlight: RSMSTheme.primaryDark)
            summaryCard(count: vm.upcomingCount, label: "Upcoming", icon: "clock.fill", highlight: RSMSTheme.primary)
            summaryCard(count: vm.endedCount, label: "Ended", icon: "checkmark.circle.fill", highlight: RSMSTheme.textSecondary)
        }
    }

    private func summaryCard(count: Int, label: String, icon: String, highlight: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(highlight)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: RSMSTheme.border, radius: 15, x: 0, y: 5)
        )
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Status Tabs
            HStack(spacing: 24) {
                statusTab(title: "All", status: nil)
                ForEach(ShiftStatus.allCases, id: \.self) { status in
                    statusTab(title: status.rawValue, status: status)
                }
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Role Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    rolePill(title: "All Roles", isSelected: selectedRole == nil) {
                        withAnimation { selectedRole = nil }
                    }
                    ForEach(roles, id: \.self) { role in
                        rolePill(title: role, isSelected: selectedRole == role) {
                            withAnimation { selectedRole = role }
                        }
                    }
                }
            }
        }
    }

    private func statusTab(title: String, status: ShiftStatus?) -> some View {
        let isSelected = (selectedStatus == status)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedStatus = status
            }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                
                if isSelected {
                    Capsule()
                        .fill(RSMSTheme.primaryDark)
                        .frame(height: 3)
                        .matchedGeometryEffect(id: "statusLine", in: animation)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
            }
        }
    }

    private func rolePill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? RSMSTheme.primaryDark : RSMSTheme.surfacePrimary)
                )
                .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.textSecondary)
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Shifts List
    private var shiftsList: some View {
        let columns = [
            GridItem(.flexible(), spacing: 24),
            GridItem(.flexible(), spacing: 24)
        ]
        
        return VStack(spacing: 20) {
            if filteredShifts.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(filteredShifts) { shift in
                        ShiftCardView(shift: shift, vm: vm) {
                            shiftToEdit = shift
                            showAddSheet = true
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredShifts)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("No Shifts Found")
                .font(.title3.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("Try adjusting your filters or add a new shift to the roster.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }



    // MARK: - Helpers
    private var clockString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: vm.currentTime)
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: vm.currentTime)
    }
}

// MARK: - Shift Card View

struct ShiftCardView: View {
    @Environment(AppViewModel.self) private var appVM
    let shift: StaffShift
    let vm: ShiftManagementViewModel
    var onEdit: () -> Void

    var body: some View {
        let name = vm.getStaffName(for: shift.staffId, dataStore: appVM.dataStore)
        let status = vm.status(for: shift)
        let progress = vm.progress(for: shift)

        Button {
            onEdit()
        } label: {
            VStack(spacing: 0) {
                // Main Content
            HStack(alignment: .center, spacing: 20) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(RSMSTheme.surfaceTertiary)
                        .frame(width: 60, height: 60)
                        
                    Circle()
                        .stroke(RSMSTheme.border, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(statusColor(for: status), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        
                    Text(String(name.prefix(1)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(RSMSTheme.primaryDark)
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        
                        Spacer()
                        
                        Text(shift.role.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RSMSTheme.surfaceTertiary)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("\(shift.startTime) – \(shift.endTime)")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                        
                        Spacer()
                        
                        Text(status.rawValue.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(statusColor(for: status))
                    }
                }
            }
            .padding(24)

            // Minimalist Progress Bar removed in favor of circular avatar progress

            Divider().overlay(RSMSTheme.border)

            // Footer (Actions)
            HStack {
                if let notes = shift.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .lineLimit(1)
                } else {
                    Text("No additional notes.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .italic()
                }
                
                Spacer()

                Button(role: .destructive) {
                    Task {
                        await vm.deleteShift(shift, dataStore: appVM.dataStore)
                    }
                } label: {
                    Text("Remove")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(RSMSTheme.danger)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.danger.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(RSMSTheme.surfaceTertiary)
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: RSMSTheme.border, radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func statusColor(for status: ShiftStatus) -> Color {
        switch status {
        case .active: return RSMSTheme.primaryDark
        case .upcoming: return RSMSTheme.primary
        case .ended: return RSMSTheme.textSecondary
        }
    }
}

// MARK: - Add Shift View (Sheet)

struct AddShiftView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    let vm: ShiftManagementViewModel
    var shiftToEdit: StaffShift? = nil

    enum ShiftBlock: String, CaseIterable, Identifiable {
        case morning = "Morning (9:00 AM - 4:00 PM)"
        case evening = "Evening (4:00 PM - 11:00 PM)"
        var id: String { self.rawValue }
        var startStr: String { self == .morning ? "09:00" : "16:00" }
        var endStr: String { self == .morning ? "16:00" : "23:00" }
    }

    @State private var staffId: UUID? = nil
    @State private var selectedBlock: ShiftBlock = .morning
    @State private var selectedRole: String = "floor"
    @State private var notes: String = ""
    @State private var availableStaff: [UserProfile] = []

    private let availableRoles = ["floor", "cashier", "back_office", "vip_lounge", "sales_associate"]
    
    private var isOverlapping: Bool {
        guard let staffId = staffId else { return false }
        return vm.hasOverlap(for: staffId, startTimeStr: selectedBlock.startStr, endTimeStr: selectedBlock.endStr, excludingShiftId: shiftToEdit?.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(shiftToEdit == nil ? "New Shift" : "Edit Shift")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Spacer()
                
                // Invisible placeholder for balance
                Button("Cancel") {}.opacity(0)
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Form Card
                    VStack(alignment: .leading, spacing: 24) {
                        Label("SHIFT DETAILS", systemImage: "clock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .tracking(1)
                        
                        // Staff Member
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Staff Member *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                            Menu {
                                ForEach(availableStaff) { user in
                                    Button("\(user.fullName) (\(user.role.displayName))") { staffId = user.id }
                                }
                            } label: {
                                HStack {
                                    if let user = availableStaff.first(where: { $0.id == staffId }) {
                                        Text("\(user.fullName) (\(user.role.displayName))")
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                    } else {
                                        Text("Select Staff")
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                .padding()
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Role
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                            Menu {
                                ForEach(availableRoles, id: \.self) { role in
                                    Button(role.replacingOccurrences(of: "_", with: " ").capitalized) { selectedRole = role }
                                }
                            } label: {
                                HStack {
                                    Text(selectedRole.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                .padding()
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Shift Timing
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shift Timing *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                            Menu {
                                ForEach(ShiftBlock.allCases) { block in
                                    Button(block.rawValue) { selectedBlock = block }
                                }
                            } label: {
                                HStack {
                                    Text(selectedBlock.rawValue)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                .padding()
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                            TextField("Optional instructions...", text: $notes)
                                .padding()
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(24)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    
                    if isOverlapping {
                        Text("This staff member already has an overlapping shift.")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.danger)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Save Button
                    Button {
                        Task { await saveShift() }
                    } label: {
                        HStack {
                            Text(shiftToEdit == nil ? "Save Shift" : "Update Shift")
                        }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            (staffId == nil || isOverlapping) ? 
                            AnyShapeStyle(RSMSTheme.textTertiary) : 
                            AnyShapeStyle(RSMSTheme.primaryGradient)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: (staffId == nil || isOverlapping) ? .clear : RSMSTheme.primaryDark.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(staffId == nil || isOverlapping)
                }
                .padding(24)
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .task {
            if let storeId = appVM.currentStoreId {
                do {
                    try await appVM.dataStore.fetchUsers(storeId: storeId)
                    availableStaff = appVM.dataStore.users
                } catch {
                    print("Failed to load staff for AddShiftView: \(error)")
                }
            }
            
            if let edit = shiftToEdit {
                staffId = edit.staffId
                selectedRole = edit.role
                notes = edit.notes ?? ""
                
                if edit.startTime == "16:00" {
                    selectedBlock = .evening
                } else {
                    selectedBlock = .morning
                }
            }
        }
    }

    private func saveShift() async {
        guard let staffId = staffId else { return }
        
        if let edit = shiftToEdit {
            let updatedShift = StaffShift(
                id: edit.id,
                staffId: staffId,
                storeId: edit.storeId,
                shiftDate: edit.shiftDate,
                startTime: selectedBlock.startStr,
                endTime: selectedBlock.endStr,
                role: selectedRole,
                notes: notes.isEmpty ? nil : notes
            )
            await vm.updateShift(updatedShift, dataStore: appVM.dataStore)
        } else {
            let newShift = StaffShift(
                id: UUID(),
                staffId: staffId,
                storeId: appVM.currentStoreId ?? UUID(),
                shiftDate: Date(),
                startTime: selectedBlock.startStr,
                endTime: selectedBlock.endStr,
                role: selectedRole,
                notes: notes.isEmpty ? nil : notes
            )
            await vm.addShift(newShift, dataStore: appVM.dataStore)
        }
        
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ShiftMonitorView()
    }
}

