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
                ForEach([GoalPeriod.daily, .weekly, .monthly, .quarterly], id: \.self) { period in
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
            }
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
    let period: GoalPeriod
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    @State private var amount: Double? = nil
    @State private var rate: Double = 5.0
    @State private var status: CommissionStatus = .pending
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Performance Summary") {
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
                    .padding(.vertical, 8)
                }
                
                Section("Commission Details") {
                    HStack {
                        Text("Amount (₹)")
                        Spacer()
                        TextField("0.00", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Rate")
                            Spacer()
                            Text("\(Int(rate))%")
                                .foregroundStyle(RSMSTheme.gold)
                                .fontWeight(.medium)
                        }
                        Slider(value: $rate, in: 1...20, step: 1)
                            .tint(RSMSTheme.gold)
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(CommissionStatus.allCases, id: \.self) { s in
                            Text(s.rawValue.capitalized).tag(s)
                        }
                    }
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(RSMSTheme.danger)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Assign Commission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        Task { await saveCommission() }
                    }
                    .disabled(isSubmitting || amount == nil || (amount ?? 0) <= 0)
                }
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .padding()
                            .background(RSMSTheme.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
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
