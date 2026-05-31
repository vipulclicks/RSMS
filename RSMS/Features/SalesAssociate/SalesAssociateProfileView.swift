//
//  SalesAssociateProfileView.swift
//  RSMS
//
//  A beautiful, premium, and minimal Profile screen for Sales Associates.
//  Adheres to Apple HIG, KISS principles, and the RSMS luxury theme.
//

import SwiftUI

struct SalesAssociateProfileView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = SalesAssociateProfileViewModel()
    
    @State private var showLogoutConfirmation = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if let user = appViewModel.currentUser {
                        // 1. Profile Header Card
                        profileHeaderCard(user: user)
                        
                        // 1.5 Shift Timing Banner
                        shiftTimingBanner()
                        
                        // 2. Performance Snapshot
                        performanceSnapshotSection()
                        
                        // 3. Commission & Goals Progress
                        commissionAndGoalsSection(user: user)
                        
                        // 4. Personal Information (Grouped List Style)
                        personalInformationSection(user: user)
                        
                        // 5. Device & Session Metadata
                        deviceAndSessionSection()
                        
                        // 6. Sign Out Button
                        signOutButton()
                        
                    } else {
                        ContentUnavailableView("User Session Expired", systemImage: "person.crop.circle.badge.exclamationmark")
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 20)
                .padding(.vertical, 24)
                .frame(maxWidth: horizontalSizeClass == .regular ? 650 : .infinity)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await refreshData()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                appViewModel.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your current session will be cleared securely.")
        }
        .task {
            await refreshData()
        }
        .onAppear {
            // Re-fetch shifts each time the tab appears (lightweight)
            // so the shift banner stays in sync even if another view
            // has already loaded older data into the DataStore cache.
            Task {
                guard let user = appViewModel.currentUser else { return }
                try? await appViewModel.dataStore.fetchStaffShifts(storeId: user.storeId ?? UUID())
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() async {
        guard let user = appViewModel.currentUser else { return }
        let storeId = user.storeId ?? UUID()
        
        async let shifts: ()? = try? appViewModel.dataStore.fetchStaffShifts(storeId: storeId)
        async let goals: ()? = try? appViewModel.dataStore.fetchSalesGoals(storeId: storeId)
        async let comms: ()? = try? appViewModel.dataStore.fetchCommissions(staffId: user.id)
        async let txns: ()? = try? appViewModel.dataStore.fetchTransactions(storeId: storeId)
        async let users: ()? = try? appViewModel.dataStore.fetchUsers(storeId: storeId)
        
        let _ = await (shifts, goals, comms, txns, users)
        
        viewModel.setup(
            dataStore: appViewModel.dataStore,
            staffId: user.id,
            storeId: storeId
        )
    }
    
    // MARK: - Subviews
    
    private func profileHeaderCard(user: UserProfile) -> some View {
        let storeName = user.storeId.map { appViewModel.dataStore.storeName(for: $0) } ?? "Unknown Store"
        let initials = user.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()
        
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.primaryGradient)
                    .frame(width: 80, height: 80)
                
                Text(initials)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 4) {
                Text(user.fullName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                let employeeId = "EMP-\(user.id.uuidString.prefix(8).uppercased())"
                Text("ID: \(employeeId)")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    
            }
            
            HStack(spacing: 12) {
                // Role Badge
                Text(user.role.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.cream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.primary, in: Capsule())
                
                // Boutique Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.primary)
                    Text(storeName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
    }
    
    private func shiftTimingBanner() -> some View {
        // Compute shift directly from the DataStore (reactive via @Observable)
        // instead of a cached snapshot in the ViewModel
        let currentShiftText: String = {
            guard let user = appViewModel.currentUser else { return "Not Assigned" }
            let todayShifts = appViewModel.dataStore.staffShifts.filter { shift in
                shift.staffId == user.id && Calendar.current.isDateInToday(shift.shiftDate)
            }
            if let shift = todayShifts.first {
                let roleName = shift.role.replacingOccurrences(of: "_", with: " ").capitalized
                return "\(roleName) Shift (\(shift.startTime) - \(shift.endTime))"
            }
            return "Not Assigned"
        }()
        
        return HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundStyle(RSMSTheme.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Shift")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                Text(currentShiftText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.primary.opacity(0.3), lineWidth: 1))
        )
        .shadow(color: RSMSTheme.primary.opacity(0.1), radius: 8, y: 2)
    }
    
    private func performanceSnapshotSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Snapshot")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            HStack(spacing: 16) {
                // Today's Sales
                NavigationLink(destination: SalesAssociateDailySalesView(transactions: viewModel.todayTransactionsList)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "indianrupeesign.circle.fill")
                                .foregroundStyle(RSMSTheme.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        Text(viewModel.todaySales)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Today's Sales")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(RSMSTheme.surfacePrimary)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                
                // Appointments
                NavigationLink(destination: SalesAssociateDailyAppointmentsView(appointments: viewModel.todayAppointmentsList)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "calendar.circle.fill")
                                .foregroundStyle(RSMSTheme.info)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        Text("\(viewModel.appointmentsCount)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Appointments Handled")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(RSMSTheme.surfacePrimary)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func personalInformationSection(user: UserProfile) -> some View {
        let department: String = {
            if user.role == .salesAssociate { return "Sales Floor" }
            return user.role.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }()
        
        let reportingManager: String = {
            if let storeId = user.storeId, let manager = appViewModel.dataStore.users.first(where: { $0.storeId == storeId && $0.role == .boutiqueManager }) {
                return manager.fullName
            }
            return "Pending Assignment"
        }()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Personal Information")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            VStack(spacing: 0) {
                infoRow(label: "Email", value: user.email, icon: "envelope")
                Divider().background(RSMSTheme.divider)
                infoRow(label: "Phone", value: user.phone ?? "Not Provided", icon: "phone")
                Divider().background(RSMSTheme.divider)
                infoRow(label: "Department", value: department, icon: "briefcase")
                Divider().background(RSMSTheme.divider)
                infoRow(label: "Reporting Manager", value: reportingManager, icon: "person.2")
            }
            .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
        }
    }
    
    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(RSMSTheme.textSecondary)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func commissionAndGoalsSection(user: UserProfile) -> some View {
        let totalCommissions = appViewModel.dataStore.commissions.filter { $0.staffId == user.id && $0.status == .approved }.reduce(0.0) { $0 + $1.amount }
        let commissionEarned = totalCommissions > 0 ? "₹\(Int(totalCommissions).formatted())" : "₹0"
        
        let commissionApprover: String = {
            if let storeId = user.storeId, let manager = appViewModel.dataStore.users.first(where: { $0.storeId == storeId && $0.role == .boutiqueManager }) {
                return manager.fullName
            }
            return "Pending Assignment"
        }()
        
        let salesGoalsTarget: String
        let salesGoalsAchieved: String
        let salesGoalsPercentage: Double
        
        if let monthlyGoal = appViewModel.dataStore.salesGoals.first(where: { $0.staffId == user.id && $0.period == .monthly }) {
            salesGoalsTarget = "₹\(Int(monthlyGoal.targetAmount).formatted())"
            salesGoalsAchieved = "₹\(Int(monthlyGoal.achievedAmount).formatted())"
            salesGoalsPercentage = monthlyGoal.targetAmount > 0 ? (monthlyGoal.achievedAmount / monthlyGoal.targetAmount) : 0.0
        } else {
            salesGoalsTarget = "₹0"
            salesGoalsAchieved = "₹0"
            salesGoalsPercentage = 0.0
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Compensation & Targets")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            VStack(spacing: 20) {
                // Commission row
                HStack(spacing: 12) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(RSMSTheme.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Commission Earned")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text(commissionEarned)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Approved By")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Text(commissionApprover)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                }
                
                Divider().background(RSMSTheme.divider)
                
                // Goals progress row
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Monthly Sales Target Progress")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Spacer()
                        Text("\(Int(salesGoalsPercentage * 100))%")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RSMSTheme.primary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                               .fill(RSMSTheme.divider)
                               .frame(height: 10)
                            Capsule()
                               .fill(RSMSTheme.primaryGradient)
                               .frame(width: geo.size.width * salesGoalsPercentage, height: 10)
                        }
                    }
                    .frame(height: 10)
                    
                    HStack {
                        Text("\(salesGoalsAchieved) achieved")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Spacer()
                        Text("Target: \(salesGoalsTarget)")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
            .padding(20)
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.02), radius: 10, y: 2)
        }
    }
    
    private func deviceAndSessionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Last Login")
                Spacer()
                Text(viewModel.lastLoginTime)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
        }
        .font(.caption)
        .foregroundStyle(RSMSTheme.textSecondary)
        .padding(.horizontal, 16)
    }
    
    private func signOutButton() -> some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack {
                Spacer()
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.semibold)
                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(RSMSTheme.primary, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: RSMSTheme.primary.opacity(0.15), radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Sign Out")
    }
}

// MARK: - Preview

#Preview {
    let vm = AppViewModel()
    vm.currentUser = .previewAssociate
    return NavigationStack {
        SalesAssociateProfileView()
            .environment(vm)
    }
}
