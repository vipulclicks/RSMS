import SwiftUI
import Observation

@Observable
class SalesGoalViewModel {
    /// Live reference to the shared DataStore — makes `activeGoals` reactive
    private var dataStore: DataStore?
    private var storeId: UUID?
    
    var availableStaff: [UserProfile] = []
    
    // MARK: - Reactive Goals (computed from dataStore)
    
    /// Reads directly from `dataStore.salesGoals` so that any update
    /// (including optimistic writes from POSCheckoutViewModel) is
    /// reflected immediately via @Observable observation.
    var activeGoals: [SalesGoal] {
        guard let ds = dataStore, let id = storeId else { return [] }
        return ds.salesGoals.filter { $0.storeId == id }
    }
    
    // MARK: - Draft Form State
    var draftSelectedStaff: UserProfile?
    var draftAmount: Double = 0.0
    var draftPeriod: GoalPeriod = .monthly
    var draftStartDate: Date = .now
    var draftEndDate: Date = .now.addingTimeInterval(30 * 86400)
    
    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    
    var isUpdating: Bool {
        guard let staff = draftSelectedStaff else { return false }
        return activeGoals.contains(where: { $0.staffId == staff.id && $0.period == draftPeriod })
    }
    
    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        self.dataStore = dataStore
        self.storeId = storeId
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataStore.fetchSalesGoals(storeId: storeId)
            try await dataStore.fetchTransactions(storeId: storeId)
            
            try await dataStore.fetchUsers(storeId: storeId)
            self.availableStaff = dataStore.users.filter { $0.role == .salesAssociate }
            
        } catch {
            print("Failed to load sales goals: \(error)")
            self.errorMessage = "Failed to load sales goals: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Smart Pre-fill Logic
    func loadPreviousGoal() {
        guard let staff = draftSelectedStaff else { return }
        
        let previousGoal = activeGoals.first { $0.staffId == staff.id && $0.period == draftPeriod }
        
        if let previousGoal {
            self.draftAmount = previousGoal.targetAmount
        } else {
            self.draftAmount = 0.0
        }
    }
    
    // MARK: - Actions
    @MainActor
    func saveNewGoal(dataStore: DataStore, storeId: UUID) async {
        guard let staff = draftSelectedStaff, draftAmount > 0 else { return }
        
        let startDate = draftStartDate
        let endDate: Date
        
        // Added quarterly back in!
        switch draftPeriod {
        case .daily:     endDate = startDate.addingTimeInterval(1 * 86400)
        case .weekly:    endDate = startDate.addingTimeInterval(7 * 86400)
        case .monthly:   endDate = startDate.addingTimeInterval(30 * 86400)
        case .quarterly: endDate = startDate.addingTimeInterval(90 * 86400)
        }
        
        if let existingGoal = activeGoals.first(where: { $0.staffId == staff.id && $0.period == draftPeriod }) {
            // Update existing goal
            let updatedGoal = SalesGoal(
                id: existingGoal.id,
                staffId: existingGoal.staffId,
                storeId: existingGoal.storeId,
                targetAmount: draftAmount,
                achievedAmount: existingGoal.achievedAmount,
                period: existingGoal.period,
                startDate: existingGoal.startDate,
                endDate: existingGoal.endDate,
                createdAt: existingGoal.createdAt
            )
            
            do {
                try await dataStore.updateSalesGoal(updatedGoal)
                // No local mutation needed — computed property reads from dataStore.salesGoals
                // which is already updated by dataStore.updateSalesGoal()
                resetDraft()
            } catch {
                print("Failed to update goal: \(error)")
                self.errorMessage = "Failed to update goal: \(error.localizedDescription)"
            }
        } else {
            // Calculate existing sales in this period for this staff
            // so we don't start at 0 if the goal is created mid-month.
            let existingTransactions = dataStore.transactions.filter {
                $0.storeId == storeId &&
                $0.associateId == staff.id &&
                $0.status == .completed &&
                $0.createdAt >= startDate &&
                $0.createdAt <= endDate
            }
            let initialAchievedAmount = existingTransactions.reduce(0.0) { $0 + $1.totalAmount }
            
            // Create new goal
            let newGoal = SalesGoal(
                id: UUID(),
                staffId: staff.id,
                storeId: storeId,
                targetAmount: draftAmount,
                achievedAmount: initialAchievedAmount,
                period: draftPeriod,
                startDate: startDate,
                endDate: endDate,
                createdAt: .now
            )
            
            do {
                try await dataStore.createSalesGoal(newGoal)
                // No local mutation needed — computed property reads from dataStore.salesGoals
                // which is already updated by dataStore.createSalesGoal()
                resetDraft()
            } catch {
                print("Failed to save goal: \(error)")
                self.errorMessage = "Failed to save goal: \(error.localizedDescription)"
            }
        }
    }
    
    func resetDraft() {
        draftSelectedStaff = nil
        draftAmount = 0.0
        draftPeriod = .monthly
        draftStartDate = .now
        draftEndDate = .now.addingTimeInterval(30 * 86400)
    }
}
