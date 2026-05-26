import SwiftUI
import Observation
import Charts

@Observable
class StaffProfileViewModel {
    let staff: UserProfile
    var salesGoals: [SalesGoal] = []
    var commissions: [Commission] = []
    
    var isLoading = false
    var errorMessage: String?
    
    init(staff: UserProfile) {
        self.staff = staff
    }
    
    @MainActor
    func load(dataStore: DataStore) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataStore.fetchSalesGoals(storeId: staff.storeId ?? UUID()) // Using storeId from staff or fallback
            // We need to fetch commissions. The dataStore might not have a function to fetch all commissions by store,
            // or maybe it does. Let's fetch transactions first which fetch commissions internally?
            try await dataStore.fetchTransactions(storeId: staff.storeId ?? UUID())
            try await dataStore.fetchCommissions(staffId: staff.id)
            
            // Filter data for this staff
            self.salesGoals = dataStore.salesGoals.filter { $0.staffId == staff.id }
            self.commissions = dataStore.commissions.filter { $0.staffId == staff.id }
            
        } catch {
            print("StaffProfileViewModel load error: \(error)")
            self.errorMessage = "Failed to load profile data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Derived properties for Charts
    var currentMonthlyGoal: SalesGoal? {
        salesGoals.first { $0.period == .monthly }
    }
    
    var goalAchievementPercentage: Double {
        guard let goal = currentMonthlyGoal, goal.targetAmount > 0 else { return 0 }
        return min(1.0, goal.achievedAmount / goal.targetAmount)
    }
    
    // For Bar Chart: History of achieved vs target (mocked as the actual goals for now, since we only store current period per staff in reality unless they have past dates. We'll plot all their goals)
    var chartGoalsData: [SalesGoal] {
        salesGoals.sorted { $0.createdAt < $1.createdAt }
    }
    
    // For Line Chart: Commission over time
    var chartCommissionData: [Commission] {
        commissions.sorted { $0.createdAt < $1.createdAt }
    }
}
