//
//  CommissionManagementView.swift
//  RSMS
//
//  Commission Management screen for Boutique Manager.
//

import SwiftUI

struct CommissionManagementView: View {
    @Environment(AppViewModel.self) private var appVM
    
    @State private var viewModel = CommissionManagementViewModel()
    @State private var selectedStaffForCommission: RankedAssociate? = nil
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Commission Data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.rankedAssociates.isEmpty {
                ContentUnavailableView(
                    "No Sales Associates",
                    systemImage: "person.3",
                    description: Text("No sales associates found for this store.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        headerBar
                        leaderboardSection
                    }
                    .padding(24)
                }
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Commission Management")
        .sheet(item: $selectedStaffForCommission) { associate in
            CommissionAssignSheet(
                staffId: associate.id,
                staffName: associate.profile.fullName,
                periodSales: associate.totalSales,
                targetAmount: associate.targetAmount,
                period: viewModel.selectedPeriod
            )
        }
        .task {
            if let storeId = appVM.currentStoreId {
                await viewModel.load(dataStore: appVM.dataStore, storeId: storeId)
            }
        }
    }
    
    // MARK: - Header Bar with Period Filters
    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Rankings")
                .font(.title3.weight(.bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            HStack(spacing: 8) {
                ForEach([GoalPeriod.weekly, .monthly], id: \.self) { period in
                    Button {
                        withAnimation(.snappy) {
                            viewModel.selectedPeriod = period
                            viewModel.recompute(dataStore: appVM.dataStore)
                        }
                    } label: {
                        Text(period.rawValue.capitalized)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.selectedPeriod == period
                                ? RSMSTheme.primaryDark
                                : RSMSTheme.surfaceSecondary
                            )
                            .foregroundStyle(
                                viewModel.selectedPeriod == period
                                ? RSMSTheme.cream
                                : RSMSTheme.textSecondary
                            )
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                
                Button {
                    Task { await recalculateAllCommissions() }
                } label: {
                    Text(isRecalculating ? "Recalculating..." : "Fix History")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.danger.opacity(0.1))
                        .foregroundStyle(RSMSTheme.danger)
                        .clipShape(Capsule())
                }
                .disabled(isRecalculating)
            }
        }
    }
    
    @State private var isRecalculating = false
    
    @MainActor
    private func recalculateAllCommissions() async {
        isRecalculating = true
        defer { isRecalculating = false }
        
        do {
            // 1. Fetch all transactions and commissions
            try await appVM.dataStore.fetchTransactions(storeId: appVM.currentStoreId)
            let allTxns = appVM.dataStore.transactions.sorted(by: { $0.createdAt < $1.createdAt })
            
            // 2. Delete all existing commissions (for testing/reset purposes)
            for commission in appVM.dataStore.commissions {
                try? await appVM.dataStore.deleteCommission(id: commission.id)
            }
            
            // 3. Recalculate
            var staffMonthlyTotals: [UUID: [String: Double]] = [:] // staffId -> [MonthYear: Total]
            
            for txn in allTxns {
                let monthYear = txn.createdAt.formatted(.dateTime.year().month())
                let currentMonthTotal = staffMonthlyTotals[txn.associateId]?[monthYear] ?? 0.0
                
                let tier1Threshold: Double = 1_000_000
                let tier2Threshold: Double = 2_000_000
                
                var remainingAmount = txn.totalAmount
                var currentAchieved = currentMonthTotal
                var commissionAmount: Double = 0.0
                
                if currentAchieved < tier1Threshold {
                    let amountInTier1 = min(remainingAmount, tier1Threshold - currentAchieved)
                    commissionAmount += amountInTier1 * 0.02
                    remainingAmount -= amountInTier1
                    currentAchieved += amountInTier1
                }
                
                if remainingAmount > 0 && currentAchieved < tier2Threshold {
                    let amountInTier2 = min(remainingAmount, tier2Threshold - currentAchieved)
                    commissionAmount += amountInTier2 * 0.03
                    remainingAmount -= amountInTier2
                    currentAchieved += amountInTier2
                }
                
                if remainingAmount > 0 {
                    commissionAmount += remainingAmount * 0.05
                }
                
                let effectiveRate = txn.totalAmount > 0 ? commissionAmount / txn.totalAmount : 0.0
                
                if commissionAmount > 0 {
                    let newCommission = Commission(
                        id: UUID(),
                        staffId: txn.associateId,
                        transactionId: txn.id,
                        amount: commissionAmount,
                        rate: effectiveRate,
                        status: .approved,
                        createdAt: txn.createdAt
                    )
                    try? await appVM.dataStore.createCommission(newCommission)
                }
                
                staffMonthlyTotals[txn.associateId, default: [:]][monthYear] = currentMonthTotal + txn.totalAmount
            }
            
            // Reload
            if let storeId = appVM.currentStoreId {
                await viewModel.load(dataStore: appVM.dataStore, storeId: storeId)
            }
            
        } catch {
            print("Error recalculating: \(error)")
        }
    }

    
    // MARK: - Leaderboard
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Sales Leaderboard",
                subtitle: "\(viewModel.rankedAssociates.count) associates · \(viewModel.selectedPeriod.rawValue.capitalized)"
            )
            
            ForEach(viewModel.rankedAssociates) { associate in
                leaderboardRow(associate)
            }
        }
    }
    
    private func leaderboardRow(_ associate: RankedAssociate) -> some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor(associate.rank).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                if associate.rank <= 3 {
                    Image(systemName: rankIcon(associate.rank))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(rankColor(associate.rank))
                } else {
                    Text("#\(associate.rank)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            
            // Profile
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Text(String(associate.profile.fullName.prefix(1)))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RSMSTheme.gold)
            }
            
            // Name & Achievement
            VStack(alignment: .leading, spacing: 6) {
                Text(associate.profile.fullName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(RSMSTheme.surfaceTertiary)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(rankColor(associate.rank))
                            .frame(width: geo.size.width * associate.achievementPercent)
                    }
                }
                .frame(height: 6)
                
                Text("\(Int(associate.achievementPercent * 100))% of target · \(viewModel.formatCurrency(associate.targetAmount))")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            Spacer()
            
            // Sales Amount
            VStack(alignment: .trailing, spacing: 6) {
                Text(viewModel.formatCurrency(associate.totalSales))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(RSMSTheme.gold)
                
                Button {
                    selectedStaffForCommission = associate
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Commission")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.primaryDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.primaryDark.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    
    // MARK: - Helpers
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return RSMSTheme.gold
        case 2: return RSMSTheme.info
        case 3: return RSMSTheme.success
        default: return RSMSTheme.textSecondary
        }
    }
    
    private func rankIcon(_ rank: Int) -> String {
        switch rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "star.fill"
        default: return "number"
        }
    }
}

// MARK: - Commission Assign Sheet (Standalone, no StaffManagementViewModel dependency)

struct CommissionAssignSheet: View {
    let staffId: UUID
    let staffName: String
    let periodSales: Double
    let targetAmount: Double
    let period: GoalPeriod
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    @State private var amount: Double? = nil
    @State private var rate: Double = 0.0 // Rate isn't explicitly used if amount is fixed, but let's keep for data struct
    @State private var status: CommissionStatus = .pending
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
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
                    .disabled(isSubmitting)
                
                Spacer()
                
                Text("Assign Commission")
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
                        Label("PERFORMANCE SUMMARY", systemImage: "chart.bar.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .tracking(1)
                            
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(staffName)
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text("\(period.rawValue.capitalized) Sales")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            Spacer()
                            Text(periodSales.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(RSMSTheme.gold)
                        }
                        .padding(16)
                        .background(RSMSTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Divider().overlay(RSMSTheme.border)
                        
                        Label("COMMISSION DETAILS", systemImage: "banknote.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .tracking(1)
                            
                        // Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Auto-Calculated Amount (₹)")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            Text(amount?.formatted(.currency(code: "INR").precision(.fractionLength(0))) ?? "₹0")
                                .font(.title3.weight(.bold))
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Rate hidden or replaced since it's tiered, we don't have a single rate.
                        
                        // Status
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                            Menu {
                                ForEach(CommissionStatus.allCases, id: \.self) { s in
                                    Button(s.rawValue.capitalized) { status = s }
                                }
                            } label: {
                                HStack {
                                    Text(status.rawValue.capitalized)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(RSMSTheme.danger)
                                .font(.callout)
                                .padding(.top, 8)
                        }
                    }
                    .padding(24)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    
                    // Save Button
                    Button {
                        Task { await saveCommission() }
                    } label: {
                        HStack {
                            Text(isSubmitting ? "Assigning..." : "Assign Commission")
                            if isSubmitting {
                                ProgressView().tint(.white).padding(.leading, 4)
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            (isSubmitting || amount == nil || (amount ?? 0) <= 0) ? 
                            AnyShapeStyle(RSMSTheme.textTertiary) : 
                            AnyShapeStyle(RSMSTheme.primaryGradient)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: (isSubmitting || amount == nil || (amount ?? 0) <= 0) ? .clear : RSMSTheme.primaryDark.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isSubmitting || amount == nil || (amount ?? 0) <= 0)
                }
                .padding(24)
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .onAppear {
            self.amount = calculateCommission(revenue: periodSales, target: targetAmount)
        }
    }
    
    private func calculateCommission(revenue: Double, target: Double) -> Double {
        // Example logic for a Tiered Escalator model
        let tier1Threshold = target * 0.8
        let tier2Threshold = target * 1.0
        
        if revenue <= tier1Threshold {
            return revenue * 0.02
        } else if revenue <= tier2Threshold {
            return (tier1Threshold * 0.02) + ((revenue - tier1Threshold) * 0.05)
        } else {
            return (tier1Threshold * 0.02) + 
                   ((tier2Threshold - tier1Threshold) * 0.05) + 
                   ((revenue - tier2Threshold) * 0.08)
        }
    }
    
    @MainActor
    private func saveCommission() async {
        guard let amount = amount, amount > 0 else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            try await appVM.dataStore.fetchTransactions(storeId: appVM.currentStoreId)
            let userTransaction = appVM.dataStore.transactions.first { $0.associateId == staffId }
            let transactionId = userTransaction?.id ?? UUID()
            
            let commission = Commission(
                id: UUID(),
                staffId: staffId,
                transactionId: transactionId,
                amount: amount,
                rate: rate / 100.0,
                status: status,
                createdAt: .now
            )
            
            try await appVM.dataStore.createCommission(commission)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
}

#Preview("Commission Management") {
    NavigationStack {
        CommissionManagementView()
            .environment(AppViewModel())
    }
}
