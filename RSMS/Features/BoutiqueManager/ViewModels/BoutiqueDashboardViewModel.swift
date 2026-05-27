//
//  BoutiqueDashboardViewModel.swift
//  RSMS
//

import SwiftUI
import Observation

struct LowStockAlert: Identifiable {
    let id: UUID
    let product: Product
    let stockItem: StockItem
}

@Observable
final class BoutiqueDashboardViewModel {

    // MARK: - KPIs Data
    private(set) var todaySales: Double = 0.0
    private(set) var salesTarget: Double = 0.0
    private(set) var salesProgress: Double = 0.0
    private(set) var appointmentCount: Int = 0
    private(set) var lowStockAlertCount: Int = 0
    private(set) var topSellingCategory: String? = nil
    private(set) var shifts: [StaffShift] = []

    // Internal collections (useful if UI wants to display lists later)
    private(set) var todayTransactions: [Transaction] = []
    private(set) var lowStockAlerts: [LowStockAlert] = []
    
    // Period filter for Sales Progress
    var selectedPeriod: GoalPeriod = .monthly {
        didSet { recalculateForPeriod() }
    }
    /// All currently-active goals (cached after fetch so we can re-filter without a network call)
    private var allActiveGoals: [SalesGoal] = []
    
    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Data Loading
    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch stores first so storeName lookup works
            try await dataStore.fetchStores()
            
            // A) Today's Sales
            try await dataStore.fetchUsers(storeId: storeId)
            let associateIds = Set(dataStore.users.filter { $0.role == .salesAssociate }.map { $0.id })
            
            try await dataStore.fetchTransactions(storeId: storeId)
            self.todayTransactions = dataStore.transactions.filter {
                $0.status == .completed && 
                Calendar.current.isDateInToday($0.createdAt) &&
                associateIds.contains($0.associateId)
            }
            self.todaySales = self.todayTransactions.reduce(0.0) { $0 + $1.totalAmount }
            
            // B) Sales Target — fetch all goals, cache them, then filter by selected period
            try await dataStore.fetchSalesGoals(storeId: storeId)
            let now = Date()
            self.allActiveGoals = dataStore.salesGoals.filter {
                $0.storeId == storeId && $0.startDate <= now && $0.endDate >= now
            }
            
            // C) Sales Progress — calculated for the currently selected period
            recalculateForPeriod()
            
            // D) Appointments Count & Clients
            try await dataStore.fetchAppointments(storeId: storeId)
            try await dataStore.fetchClients()
            self.appointmentCount = dataStore.appointments.filter {
                Calendar.current.isDateInToday($0.dateTime)
            }.count
            
            // E) Low Stock Alerts
            try await dataStore.fetchStockItems(storeId: storeId)
            let lowStockItems = dataStore.stockItems.filter {
                $0.quantity < 5 && $0.status == .available
            }
            if dataStore.products.isEmpty {
                try await dataStore.fetchProducts()
            }
            self.lowStockAlerts = lowStockItems.compactMap { item in
                guard let product = dataStore.products.first(where: { $0.id == item.productId }) else { return nil }
                return LowStockAlert(id: item.id, product: product, stockItem: item)
            }
            self.lowStockAlertCount = self.lowStockAlerts.count
            
            // F) Fetch Dashboard Summaries (for targets if needed)
            try await dataStore.fetchDashboardSummaries(storeId: storeId)
            
            // G) Top Selling Category (Client-Side Computation)
            self.topSellingCategory = try await computeTopCategory(dataStore: dataStore)
            
            // H) Staff On Shift Today
            try await dataStore.fetchStaffShifts(storeId: storeId)
            let todaysShifts = dataStore.staffShifts.filter {
                Calendar.current.isDateInToday($0.shiftDate)
            }
            self.shifts = todaysShifts
            
        } catch {
            print("Failed to load dashboard data: \(error)")
            self.errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func computeTopCategory(dataStore: DataStore) async throws -> String? {
        guard !todayTransactions.isEmpty else { return nil }
        
        // We need products to resolve categories
        if dataStore.products.isEmpty {
            try await dataStore.fetchProducts()
        }
        
        var categoryCounts: [String: Int] = [:]
        
        for transaction in todayTransactions {
            try await dataStore.fetchUniversalCartItems(cartId: transaction.cartId)
            
            for item in dataStore.universalCartItems {
                if let product = dataStore.products.first(where: { $0.id == item.productId }) {
                    categoryCounts[product.category, default: 0] += item.quantity
                }
            }
        }
        
        return categoryCounts.max { a, b in a.value < b.value }?.key
    }

    // MARK: - Formatting Helpers

    var formattedDate: String {
        RSMSDateFormatter.fullDate.string(from: .now)
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹0"
    }
    
    // MARK: - Actions
    func simulateStockDrop() {
        // Simulation disabled in prod environment
    }
    
    func reorderItem(for productId: UUID) {
        // Implement reorder logic via DataStore movement request
        // For now, optimistically remove from alerts
        self.lowStockAlerts.removeAll { $0.product.id == productId }
        self.lowStockAlertCount = self.lowStockAlerts.count
    }
    
    // MARK: - Debug / Cleanup
    func resetSalesGoals(dataStore: DataStore, storeId: UUID) async {
        do {
            try await dataStore.fetchSalesGoals(storeId: storeId)
            // 1. Delete all existing goals for this store
            for goal in dataStore.salesGoals {
                try await dataStore.deleteSalesGoal(id: goal.id)
            }
            
            // 2. Fetch staff to assign a fresh goal to the first associate found
            try await dataStore.fetchUsers(storeId: storeId)
            let associates = dataStore.users.filter { $0.role == .salesAssociate }
            if let firstAssociate = associates.first {
                let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
                let endOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
                
                let newGoal = SalesGoal(
                    id: UUID(),
                    staffId: firstAssociate.id,
                    storeId: storeId,
                    targetAmount: 7000.0,
                    achievedAmount: 0.0,
                    period: .monthly,
                    startDate: startOfMonth,
                    endDate: endOfMonth,
                    createdAt: Date()
                )
                try await dataStore.createSalesGoal(newGoal)
            }
            
            // 3. Reload everything
            await load(dataStore: dataStore, storeId: storeId)
        } catch {
            print("Failed to reset sales goals: \(error)")
            self.errorMessage = "Failed to reset goals: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Period Recalculation
    
    /// Whether any goals exist for the currently selected period
    private(set) var hasGoalsForPeriod: Bool = true
    /// The total achieved amount across all associates for the selected period
    private(set) var periodAchievedAmount: Double = 0.0
    /// How many associates have a goal set for this period
    private(set) var goalAssociateCount: Int = 0
    
    /// Re-filters the cached active goals by the currently selected period
    /// and recalculates salesTarget + salesProgress without a network call.
    private func recalculateForPeriod() {
        let filtered = allActiveGoals.filter { $0.period == selectedPeriod }
        self.hasGoalsForPeriod = !filtered.isEmpty
        self.goalAssociateCount = filtered.count
        self.salesTarget = filtered.reduce(0.0) { $0 + $1.targetAmount }
        self.periodAchievedAmount = filtered.reduce(0.0) { $0 + $1.achievedAmount }
        
        if salesTarget > 0 {
            self.salesProgress = min(1.0, periodAchievedAmount / salesTarget)
        } else {
            self.salesProgress = 0.0
        }
    }
}
