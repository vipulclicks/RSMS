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
    
    struct DailyStoreSales: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
    }
    private(set) var previousDaysSales: [DailyStoreSales] = []
    private(set) var salesIncrementPercentage: Double = 0.0
    
    struct ChartSalesData: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
    }
    private(set) var chartSalesData: [ChartSalesData] = []
    
    struct StaffSales: Identifiable {
        let id: UUID
        let staffName: String
        let totalSales: Double
    }
    
    var todaySalesByStaff: [StaffSales] {
        var salesDict: [UUID: Double] = [:]
        for txn in todayTransactions {
            salesDict[txn.associateId, default: 0] += txn.totalAmount
        }
        
        return salesDict.map { (associateId, total) in
            let staff = allAssociates.first { $0.id == associateId }
            let name = staff?.fullName ?? "Unknown"
            return StaffSales(id: associateId, staffName: name, totalSales: total)
        }.sorted { $0.totalSales > $1.totalSales }
    }
    
    // Period filter for Sales Progress
    var selectedPeriod: GoalPeriod = .monthly {
        didSet { recalculateForPeriod() }
    }
    /// All currently-active goals (cached after fetch so we can re-filter without a network call)
    private var allActiveGoals: [SalesGoal] = []
    
    // Cached data for recalculation
    private var allAssociates: [UserProfile] = []
    private var allTransactions: [Transaction] = []
    
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
            
            // Fetch users
            try await dataStore.fetchUsers(storeId: storeId)
            self.allAssociates = dataStore.users.filter { $0.role == .salesAssociate }
            let associateIds = Set(self.allAssociates.map { $0.id })
            
            // Fetch all transactions
            try await dataStore.fetchTransactions(storeId: storeId)
            self.allTransactions = dataStore.transactions.filter {
                $0.status == .completed && associateIds.contains($0.associateId)
            }
            
            // A) Today's Sales
            self.todayTransactions = self.allTransactions.filter {
                Calendar.current.isDateInToday($0.createdAt)
            }
            self.todaySales = self.todayTransactions.reduce(0.0) { $0 + $1.totalAmount }
            
            let now = Date()
            
            // Calculate previous days sales and increment
            let cal = Calendar.current
            var dailyHistory: [DailyStoreSales] = []
            for i in (0..<7).reversed() {
                if let d = cal.date(byAdding: .day, value: -i, to: now) {
                    let start = cal.startOfDay(for: d)
                    let end = cal.date(byAdding: .day, value: 1, to: start)!
                    let dailyTotal = self.allTransactions.filter { $0.createdAt >= start && $0.createdAt < end }.reduce(0.0) { $0 + $1.totalAmount }
                    dailyHistory.append(DailyStoreSales(date: start, amount: dailyTotal))
                }
            }
            self.previousDaysSales = dailyHistory
            
            
            // B) Sales Target — fetch all goals, cache them
            try await dataStore.fetchSalesGoals(storeId: storeId)
            self.allActiveGoals = dataStore.salesGoals.filter {
                $0.storeId == storeId
            }
            
            // C) Sales Progress
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
            
            // F) Fetch Dashboard Summaries
            try await dataStore.fetchDashboardSummaries(storeId: storeId)
            try? await dataStore.fetchDiscountApprovalRequests()
            try? await dataStore.fetchAppNotifications()
            
            // G) Top Selling Category
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
    func simulateStockDrop() {}
    
    func reorderItem(for productId: UUID) {
        self.lowStockAlerts.removeAll { $0.product.id == productId }
        self.lowStockAlertCount = self.lowStockAlerts.count
    }
    
    // MARK: - Debug / Cleanup
    func resetSalesGoals(dataStore: DataStore, storeId: UUID) async {
        do {
            try await dataStore.fetchSalesGoals(storeId: storeId)
            for goal in dataStore.salesGoals {
                try await dataStore.deleteSalesGoal(id: goal.id)
            }
            
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
            
            await load(dataStore: dataStore, storeId: storeId)
        } catch {
            print("Failed to reset sales goals: \(error)")
            self.errorMessage = "Failed to reset goals: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Period Recalculation
    
    private(set) var hasGoalsForPeriod: Bool = true
    private(set) var periodAchievedAmount: Double = 0.0
    private(set) var goalAssociateCount: Int = 0
    
    struct AssociateSalesProgress: Identifiable {
        let id = UUID()
        let associateId: UUID
        let associateName: String
        let achievedAmount: Double
        let targetAmount: Double?
        
        var progressPercentage: Double {
            guard let target = targetAmount, target > 0 else { return 0.0 }
            return min(1.0, achievedAmount / target)
        }
    }
    private(set) var periodAssociateProgress: [AssociateSalesProgress] = []
    
    private func startDate(for period: GoalPeriod) -> Date {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .daily: return cal.startOfDay(for: now)
        case .weekly: return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .monthly: return cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        case .quarterly: 
            let month = cal.component(.month, from: now)
            let quarterMonth = ((month - 1) / 3) * 3 + 1
            return cal.date(from: DateComponents(year: cal.component(.year, from: now), month: quarterMonth, day: 1)) ?? now
        }
    }
    
    private func recalculateForPeriod() {
        let periodGoals = allActiveGoals.filter { $0.period == selectedPeriod }
        
        let periodStart = startDate(for: selectedPeriod)
        
        let txsInPeriod = allTransactions.filter { $0.createdAt >= periodStart }
        
        // Sum of all transactions in this period (regardless of who made them) for the store overall progress
        self.periodAchievedAmount = txsInPeriod.reduce(0.0) { $0 + $1.totalAmount }
        
        // Compute associate-level progress using actual transactions for the period
        var progressList: [AssociateSalesProgress] = []
        var validTargetsSum = 0.0
        var associatesWithGoals = 0
        
        for associate in allAssociates {
            // Find the LATEST goal for this period for this associate
            let goal = periodGoals
                .filter { $0.staffId == associate.id }
                .sorted { $0.createdAt > $1.createdAt }
                .first
            
            if let target = goal?.targetAmount {
                validTargetsSum += target
                associatesWithGoals += 1
            }
            
            // Calculate actual sales in this period
            let associateTransactions = allTransactions.filter { 
                $0.associateId == associate.id && $0.createdAt >= periodStart 
            }
            let actualSales = associateTransactions.reduce(0.0) { $0 + $1.totalAmount }
            
            // If they have a goal OR they made sales in this period, show them
            if goal != nil || actualSales > 0 {
                progressList.append(AssociateSalesProgress(
                    associateId: associate.id,
                    associateName: associate.fullName,
                    achievedAmount: actualSales, // Use actual calculated sales for accuracy across periods
                    targetAmount: goal?.targetAmount
                ))
            }
        }
        
        self.hasGoalsForPeriod = associatesWithGoals > 0
        self.goalAssociateCount = associatesWithGoals
        self.salesTarget = validTargetsSum
        
        if salesTarget > 0 {
            self.salesProgress = min(1.0, periodAchievedAmount / salesTarget)
        } else {
            self.salesProgress = 0.0
        }
        
        self.periodAssociateProgress = progressList.sorted { $0.achievedAmount > $1.achievedAmount }
        
        // Compute Historical Sales for the Chart
        var newChartData: [ChartSalesData] = []
        let cal = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .weekly:
            // Last 7 weeks
            for i in (0..<7).reversed() {
                if let d = cal.date(byAdding: .weekOfYear, value: -i, to: now),
                   let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: d)) {
                    let endOfWeek = cal.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
                    let total = allTransactions.filter { $0.createdAt >= startOfWeek && $0.createdAt < endOfWeek }.reduce(0.0) { $0 + $1.totalAmount }
                    newChartData.append(ChartSalesData(date: startOfWeek, amount: total))
                }
            }
        case .monthly:
            // Jan to Dec of current year
            let currentYear = cal.component(.year, from: now)
            for month in 1...12 {
                if let startOfMonth = cal.date(from: DateComponents(year: currentYear, month: month, day: 1)) {
                    let endOfMonth = cal.date(byAdding: .month, value: 1, to: startOfMonth)!
                    let total = allTransactions.filter { $0.createdAt >= startOfMonth && $0.createdAt < endOfMonth }.reduce(0.0) { $0 + $1.totalAmount }
                    newChartData.append(ChartSalesData(date: startOfMonth, amount: total))
                }
            }
        default:
            break
        }
        self.chartSalesData = newChartData
        
        // Calculate Dynamic Increment Percentage
        var currentSales: Double = 0
        var previousSales: Double = 0
        
        if selectedPeriod == .monthly {
            let currentMonth = cal.component(.month, from: now)
            if currentMonth >= 1 && currentMonth <= 12 {
                currentSales = newChartData[currentMonth - 1].amount
                previousSales = currentMonth > 1 ? newChartData[currentMonth - 2].amount : 0.0
            }
        } else if selectedPeriod == .weekly {
            if newChartData.count >= 2 {
                currentSales = newChartData[newChartData.count - 1].amount
                previousSales = newChartData[newChartData.count - 2].amount
            }
        }
        
        if previousSales > 0 {
            self.salesIncrementPercentage = ((currentSales - previousSales) / previousSales) * 100
        } else if currentSales > 0 {
            self.salesIncrementPercentage = 100.0
        } else {
            self.salesIncrementPercentage = 0.0
        }
    }
}
