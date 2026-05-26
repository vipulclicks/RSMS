import SwiftUI
import Observation

@Observable
class SalesGoalViewModel {
    var activeGoals: [SalesGoal] = []
    var availableStaff: [UserProfile] = []
    
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
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataStore.fetchSalesGoals(storeId: storeId)
            self.activeGoals = dataStore.salesGoals
            
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
                if let i = activeGoals.firstIndex(where: { $0.id == updatedGoal.id }) {
                    withAnimation(.spring) {
                        activeGoals[i] = updatedGoal
                    }
                }
                resetDraft()
            } catch {
                print("Failed to update goal: \(error)")
                self.errorMessage = "Failed to update goal: \(error.localizedDescription)"
            }
        } else {
            // Create new goal
            let newGoal = SalesGoal(
                id: UUID(),
                staffId: staff.id,
                storeId: storeId,
                targetAmount: draftAmount,
                achievedAmount: 0.0,
                period: draftPeriod,
                startDate: startDate,
                endDate: endDate,
                createdAt: .now
            )
            
            do {
                try await dataStore.createSalesGoal(newGoal)
                withAnimation(.spring) {
                    activeGoals.insert(newGoal, at: 0)
                }
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
