//
//  CommissionManagementViewModel.swift
//  RSMS
//
//  ViewModel for the Commission Management screen.
//

import SwiftUI
import Observation

/// Represents a ranked sales associate with computed sales data.
struct RankedAssociate: Identifiable {
    let id: UUID
    let profile: UserProfile
    let totalSales: Double
    let targetAmount: Double
    let achievementPercent: Double
    var rank: Int
}

@Observable
final class CommissionManagementViewModel {
    
    // MARK: - Published Data
    private(set) var rankedAssociates: [RankedAssociate] = []
    private(set) var allTransactions: [Transaction] = []
    
    var selectedPeriod: GoalPeriod = .monthly
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Top Performer
    var topPerformer: RankedAssociate? {
        rankedAssociates.first
    }
    
    // MARK: - Data Loading
    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1) Fetch all users for this store
            try await dataStore.fetchUsers(storeId: storeId)
            let salesAssociates = dataStore.users.filter { $0.role == .salesAssociate }
            
            // 2) Fetch all transactions for this store
            try await dataStore.fetchTransactions(storeId: storeId)
            self.allTransactions = dataStore.transactions
            
            // 3) Fetch all sales goals for this store
            try await dataStore.fetchSalesGoals(storeId: storeId)
            
            // 4) Compute rankings
            computeRankings(
                associates: salesAssociates,
                transactions: dataStore.transactions,
                salesGoals: dataStore.salesGoals,
                period: selectedPeriod
            )
            
        } catch {
            print("CommissionManagementViewModel load error: \(error)")
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Recompute Rankings (when period changes)
    func recompute(dataStore: DataStore) {
        let salesAssociates = dataStore.users.filter { $0.role == .salesAssociate }
        computeRankings(
            associates: salesAssociates,
            transactions: allTransactions,
            salesGoals: dataStore.salesGoals,
            period: selectedPeriod
        )
    }
    
    // MARK: - Private Computation
    private func computeRankings(
        associates: [UserProfile],
        transactions: [Transaction],
        salesGoals: [SalesGoal],
        period: GoalPeriod
    ) {
        let calendar = Calendar.current
        let now = Date()
        
        // Determine date range for the selected period
        let startDate: Date
        switch period {
        case .daily:
            startDate = calendar.startOfDay(for: now)
        case .weekly:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarterly:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        }
        
        // Filter completed transactions within the period
        let periodTransactions = transactions.filter {
            $0.status == .completed && $0.createdAt >= startDate && $0.createdAt <= now
        }
        
        // Build ranked list
        var ranked: [RankedAssociate] = associates.map { associate in
            let staffTransactions = periodTransactions.filter { $0.associateId == associate.id }
            let totalSales = staffTransactions.reduce(0.0) { $0 + $1.totalAmount }
            
            // Find the matching goal for this period
            let matchingGoal = salesGoals.first {
                $0.staffId == associate.id && $0.period == period &&
                $0.startDate <= now && $0.endDate >= now
            }
            let targetAmount = matchingGoal?.targetAmount ?? 0.0
            let achievement = targetAmount > 0 ? min(1.0, totalSales / targetAmount) : 0.0
            
            return RankedAssociate(
                id: associate.id,
                profile: associate,
                totalSales: totalSales,
                targetAmount: targetAmount,
                achievementPercent: achievement,
                rank: 0
            )
        }
        
        // Sort by total sales descending
        ranked.sort { $0.totalSales > $1.totalSales }
        
        // Assign ranks
        for i in ranked.indices {
            ranked[i].rank = i + 1
        }
        
        self.rankedAssociates = ranked
    }
    
    // MARK: - Formatting Helpers
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹0"
    }
}
