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
    @State private var vm = ShiftScheduleViewModel()
    @State private var showAddSheet = false
    @State private var selectedStatus: ShiftStatus? = nil
    @State private var selectedRole: String? = nil
    @Namespace private var animation

    private let roles = ["Back Office", "Cashier", "Floor", "VIP Lounge"]

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
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                    .padding(.top, 16)
                
                summaryStrip
                
                filterSection
                
                shiftsList
                
                salesGoalsSection
                    .padding(.top, 24)
                    
                commissionPayoutsSection
                    .padding(.top, 12)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 60)
        }
        .background(RSMSTheme.backgroundGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(RSMSTheme.primaryDark)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(RSMSTheme.border, lineWidth: 1))
                        .shadow(color: RSMSTheme.textPrimary.opacity(0.1), radius: 6, x: 0, y: 3)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddShiftView(vm: vm)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            Text("Today's Shifts")
                .font(.system(size: 34, weight: .heavy, design: .default))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            Text(dateString)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textSecondary)
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
                .fill(.ultraThinMaterial)
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
            GridItem(.adaptive(minimum: 400, maximum: .infinity), spacing: 24)
        ]
        
        return VStack(spacing: 20) {
            if filteredShifts.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(filteredShifts) { shift in
                        ShiftCardView(shift: shift, vm: vm)
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

    // MARK: - Sales Goals & Commissions
    private var salesGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SALES GOALS & COMMISSIONS")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.primary)
            
            VStack(spacing: 0) {
                ForEach(vm.salesGoals.indices, id: \.self) { index in
                    salesGoalRow(vm.salesGoals[index], index: index)
                    if index < vm.salesGoals.count - 1 {
                        Divider().overlay(RSMSTheme.border)
                    }
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(RSMSTheme.border, lineWidth: 1))
        }
    }
    
    private func salesGoalRow(_ goal: SalesGoal, index: Int) -> some View {
        let name = vm.getStaffName(for: goal.staffId)
        let initials = name.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
        let progress = goal.targetAmount > 0 ? goal.achievedAmount / goal.targetAmount : 0
        let color = index == 0 ? RSMSTheme.success : (index == 1 ? RSMSTheme.warning : RSMSTheme.info)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        let goalFormatted = formatter.string(from: NSNumber(value: goal.targetAmount)) ?? ""
        let achievedFormatted = formatter.string(from: NSNumber(value: goal.achievedAmount)) ?? ""

        return HStack(alignment: .top, spacing: 20) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.surfaceTertiary)
                    .frame(width: 50, height: 50)
                Text(initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Goal: \(goalFormatted)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(achievedFormatted)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("\(Int(progress * 100))% achieved")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(color)
                    }
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(RSMSTheme.surfaceTertiary)
                        Capsule()
                            .fill(color)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(24)
    }

    // MARK: - Commission Payouts
    private var commissionPayoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("COMMISSION PAYOUTS — MAY 2026")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.primary)
            
            VStack(spacing: 0) {
                ForEach(vm.commissions.indices, id: \.self) { index in
                    commissionRow(vm.commissions[index])
                    if index < vm.commissions.count - 1 {
                        Divider().overlay(RSMSTheme.border).padding(.horizontal, 24)
                    }
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(RSMSTheme.border, lineWidth: 1))
        }
    }
    
    private func commissionRow(_ payout: Commission) -> some View {
        let name = vm.getStaffName(for: payout.staffId)
        let isPending = payout.status == .pending
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        let amountFormatted = formatter.string(from: NSNumber(value: payout.amount)) ?? ""

        return HStack {
            Text(name)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            Spacer()
            
            Text("+ \(amountFormatted)")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding(.trailing, 24)
            
            Text(isPending ? "Pending" : "Added to salary")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isPending ? RSMSTheme.warning : RSMSTheme.success)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isPending ? RSMSTheme.warning.opacity(0.15) : RSMSTheme.success.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isPending ? RSMSTheme.warning.opacity(0.3) : RSMSTheme.success.opacity(0.3), lineWidth: 1))
        }
        .padding(24)
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
    let shift: StaffShift
    let vm: ShiftScheduleViewModel

    var body: some View {
        let name = vm.getStaffName(for: shift.staffId)
        let status = vm.status(for: shift)
        let progress = vm.progress(for: shift)

        VStack(spacing: 0) {
            // Main Content
            HStack(alignment: .center, spacing: 20) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(RSMSTheme.surfaceTertiary)
                        .frame(width: 60, height: 60)
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

            // Minimalist Progress Bar
            if status != .upcoming {
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(RSMSTheme.surfaceTertiary)
                            Capsule()
                                .fill(statusColor(for: status))
                                .frame(width: max(0, geo.size.width * progress))
                        }
                    }
                    .frame(height: 4)
                    .clipShape(Capsule())
                    
                    HStack {
                        Text("Progress")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(statusColor(for: status))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

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
                    withAnimation { vm.removeShift(shift) }
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
            .background(.regularMaterial)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: RSMSTheme.border, radius: 20, x: 0, y: 10)
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
    let vm: ShiftScheduleViewModel

    @State private var staffId: UUID = UserProfile.all.first?.id ?? UUID()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600 * 8)
    @State private var selectedRole: String = "floor"
    @State private var notes: String = ""

    private let availableRoles = ["floor", "cashier", "back_office", "vip_lounge"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Staff Member") {
                    Picker("Select Staff", selection: $staffId) {
                        ForEach(UserProfile.all) { user in
                            Text(user.fullName).tag(user.id)
                        }
                    }
                    .tint(RSMSTheme.primaryDark)
                }

                Section("Shift Timing") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Role") {
                    Picker("Assigned Role", selection: $selectedRole) {
                        ForEach(availableRoles, id: \.self) { role in
                            Text(role.replacingOccurrences(of: "_", with: " ").capitalized).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(RSMSTheme.primaryDark)
                }

                Section("Notes") {
                    TextField("Optional instructions...", text: $notes)
                }
            }
            .navigationTitle("New Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveShift()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.primaryDark)
                }
            }
        }
    }

    private func saveShift() {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        
        let newShift = StaffShift(
            id: UUID(),
            staffId: staffId,
            storeId: UUID(),
            shiftDate: Date(),
            startTime: f.string(from: startTime),
            endTime: f.string(from: endTime),
            role: selectedRole,
            notes: notes.isEmpty ? nil : notes
        )
        withAnimation {
            vm.addShift(newShift)
        }
    }
}

#Preview {
    NavigationStack {
        ShiftMonitorView()
    }
}

