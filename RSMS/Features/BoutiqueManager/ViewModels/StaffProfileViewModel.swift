import SwiftUI
import Observation
import Charts

struct DailySales: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct DailyCommission: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

@Observable
class StaffProfileViewModel {
    let staff: UserProfile
    /// Live reference to the shared DataStore — makes `salesGoals` reactive
    private var dataStore: DataStore?
    var commissions: [Commission] = []
    
    var isLoading = false
    var errorMessage: String?
    
    var shiftTiming: String = "Not Assigned"
    
    init(staff: UserProfile) {
        self.staff = staff
    }
    
    /// Reads directly from `dataStore.salesGoals` so that any update
    /// (including optimistic writes from POSCheckoutViewModel) is
    /// reflected immediately via @Observable observation.
    var salesGoals: [SalesGoal] {
        dataStore?.salesGoals.filter { $0.staffId == staff.id } ?? []
    }
    
    @MainActor
    func load(dataStore: DataStore) async {
        self.dataStore = dataStore
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataStore.fetchSalesGoals(storeId: staff.storeId ?? UUID()) // Using storeId from staff or fallback
            // We need to fetch commissions. The dataStore might not have a function to fetch all commissions by store,
            // or maybe it does. Let's fetch transactions first which fetch commissions internally?
            try await dataStore.fetchTransactions(storeId: staff.storeId ?? UUID())
            try await dataStore.fetchCommissions(staffId: staff.id)
            try await dataStore.fetchStaffShifts(storeId: staff.storeId ?? UUID())
            
            // Filter commissions for this staff (commissions are not computed because
            // they are fetched per-staff, not per-store, so the dataStore array may
            // contain commissions from different fetch calls)
            self.commissions = dataStore.commissions.filter { $0.staffId == staff.id }
            
            // Current Shift
            if let shift = dataStore.staffShifts.first(where: { $0.staffId == staff.id && Calendar.current.isDateInToday($0.shiftDate) }) {
                let roleName = shift.role.replacingOccurrences(of: "_", with: " ").capitalized
                self.shiftTiming = "\(roleName) Shift (\(shift.startTime) - \(shift.endTime))"
            } else {
                self.shiftTiming = "Not Assigned"
            }
            
        } catch {
            print("StaffProfileViewModel load error: \(error)")
            self.errorMessage = "Failed to load profile data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Derived properties for Charts
    var currentMonthlyGoal: SalesGoal? {
        return salesGoals
            .filter { $0.period == .monthly }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    var computedAchievedAmount: Double {
        guard let goal = currentMonthlyGoal, let ds = dataStore else { return 0 }
        let cal = Calendar.current
        let now = Date()
        let currentMonth = cal.component(.month, from: now)
        let currentYear = cal.component(.year, from: now)
        
        let existingTransactions = ds.transactions.filter {
            $0.associateId == staff.id &&
            $0.status == .completed &&
            cal.component(.month, from: $0.createdAt) == currentMonth &&
            cal.component(.year, from: $0.createdAt) == currentYear
        }
        return existingTransactions.reduce(0.0) { $0 + $1.totalAmount }
    }
    
    var goalAchievementPercentage: Double {
        guard let goal = currentMonthlyGoal, goal.targetAmount > 0 else { return 0 }
        return min(1.0, computedAchievedAmount / goal.targetAmount)
    }
    
    var rawGoalAchievementPercentage: Double {
        guard let goal = currentMonthlyGoal, goal.targetAmount > 0 else { return 0 }
        return computedAchievedAmount / goal.targetAmount
    }
    
    // For Bar Chart: History of achieved vs target (mocked as the actual goals for now, since we only store current period per staff in reality unless they have past dates. We'll plot all their goals)
    var chartGoalsData: [SalesGoal] {
        salesGoals.sorted { $0.createdAt < $1.createdAt }
    }
    
    var dailySalesData: [DailySales] {
        guard let ds = dataStore else { return [] }
        let cal = Calendar.current
        let now = Date()
        
        var result: [DailySales] = []
        for i in (0..<7).reversed() {
            if let date = cal.date(byAdding: .day, value: -i, to: now) {
                let startOfDay = cal.startOfDay(for: date)
                let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let daySales = ds.transactions.filter {
                    $0.associateId == staff.id &&
                    $0.status == .completed &&
                    $0.createdAt >= startOfDay &&
                    $0.createdAt < endOfDay
                }.reduce(0.0) { $0 + $1.totalAmount }
                
                result.append(DailySales(date: startOfDay, amount: daySales))
            }
        }
        return result
    }
    
    struct CommissionListItem: Identifiable {
        let id: UUID
        let transactionDate: Date
        let transactionAmount: Double
        let commissionEarned: Double
        let status: CommissionStatus
    }
    
    var commissionList: [CommissionListItem] {
        guard let ds = dataStore else { return [] }
        return commissions.compactMap { commission in
            // Find the associated transaction
            guard let txn = ds.transactions.first(where: { $0.id == commission.transactionId }) else { return nil }
            return CommissionListItem(
                id: commission.id,
                transactionDate: txn.createdAt,
                transactionAmount: txn.totalAmount,
                commissionEarned: commission.amount,
                status: commission.status
            )
        }.sorted { $0.transactionDate > $1.transactionDate }
    }
    
    var dailyCommissionData: [DailyCommission] {
        let cal = Calendar.current
        let now = Date()
        
        var result: [DailyCommission] = []
        for i in (0..<7).reversed() {
            if let date = cal.date(byAdding: .day, value: -i, to: now) {
                let startOfDay = cal.startOfDay(for: date)
                let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let dayCommission = commissions.filter {
                    $0.createdAt >= startOfDay && $0.createdAt < endOfDay
                }.reduce(0.0) { $0 + $1.amount }
                
                result.append(DailyCommission(date: startOfDay, amount: dayCommission))
            }
        }
        return result
    }
}
