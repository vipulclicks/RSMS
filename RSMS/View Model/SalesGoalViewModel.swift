import SwiftUI
import Observation

@Observable
class SalesGoalViewModel {
    // MARK: - App State
    var activeGoals: [SalesGoal] = [SalesGoal.preview]
    var availableStaff: [UserProfile] = UserProfile.all.filter { $0.role == .salesAssociate }
    
    // MARK: - Draft Form State
    var draftSelectedStaff: UserProfile?
    var draftAmount: Double = 0.0
    var draftPeriod: GoalPeriod = .monthly
    var draftStartDate: Date = .now
    var draftEndDate: Date = .now.addingTimeInterval(30 * 86400)
    
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
    func saveNewGoal(storeId: UUID) {
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
        
        withAnimation(.spring) {
            activeGoals.insert(newGoal, at: 0)
        }
        
        resetDraft()
    }
    
    func resetDraft() {
        draftSelectedStaff = nil
        draftAmount = 0.0
        draftPeriod = .monthly
        draftStartDate = .now
        draftEndDate = .now.addingTimeInterval(30 * 86400)
    }
}
