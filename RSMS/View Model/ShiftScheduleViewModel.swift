import SwiftUI
import Combine

enum ShiftStatus: String, CaseIterable {
    case active = "Active"
    case upcoming = "Upcoming"
    case ended = "Ended"
}

@Observable
class ShiftScheduleViewModel {
    var shifts: [StaffShift] = []
    var salesGoals: [SalesGoal] = []
    var commissions: [Commission] = []
    
    // Timer to trigger UI updates for progress bars and live clocks
    var currentTime: Date = Date()
    
    init() {
        fetchTodayShifts()
        fetchGoalsAndCommissions()
        
        // Timer for progress bars and live clock updates
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }
    
    func fetchTodayShifts() {
        // Load mock shifts
        self.shifts = StaffShift.all
    }
    
    func fetchGoalsAndCommissions() {
        // Generating mock data using actual Models to match UI
        let users = UserProfile.all
        guard users.count >= 3 else { return }
        
        self.salesGoals = [
            SalesGoal(id: UUID(), staffId: users[0].id, storeId: UUID(), targetAmount: 180000, achievedAmount: 167200, period: .monthly, startDate: .now, endDate: .now, createdAt: .now),
            SalesGoal(id: UUID(), staffId: users[1].id, storeId: UUID(), targetAmount: 160000, achievedAmount: 138400, period: .monthly, startDate: .now, endDate: .now, createdAt: .now),
            SalesGoal(id: UUID(), staffId: users[2].id, storeId: UUID(), targetAmount: 140000, achievedAmount: 141000, period: .monthly, startDate: .now, endDate: .now, createdAt: .now)
        ]
        
        self.commissions = [
            Commission(id: UUID(), staffId: users[0].id, transactionId: UUID(), amount: 13360, rate: 0.05, status: .paid, createdAt: .now),
            Commission(id: UUID(), staffId: users[1].id, transactionId: UUID(), amount: 11920, rate: 0.05, status: .pending, createdAt: .now),
            Commission(id: UUID(), staffId: users[2].id, transactionId: UUID(), amount: 12050, rate: 0.05, status: .paid, createdAt: .now)
        ]
    }
    
    func getStaffName(for staffId: UUID) -> String {
        return UserProfile.all.first(where: { $0.id == staffId })?.fullName ?? "Unknown Staff"
    }
    
    // Status Logic
    func status(for shift: StaffShift) -> ShiftStatus {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: shift.startTime),
              let end = formatter.date(from: shift.endTime) else {
            return .upcoming
        }
        
        let now = self.currentTime
        let cal = Calendar.current
        
        // Construct today's dates for start and end
        let startToday = cal.date(bySettingHour: cal.component(.hour, from: start),
                                  minute: cal.component(.minute, from: start),
                                  second: 0, of: now) ?? now
        let endToday = cal.date(bySettingHour: cal.component(.hour, from: end),
                                minute: cal.component(.minute, from: end),
                                second: 0, of: now) ?? now
        
        if now < startToday {
            return .upcoming
        } else if now > endToday {
            return .ended
        } else {
            return .active
        }
    }
    
    func progress(for shift: StaffShift) -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: shift.startTime),
              let end = formatter.date(from: shift.endTime) else {
            return 0.0
        }
        
        let now = self.currentTime
        let cal = Calendar.current
        
        let startToday = cal.date(bySettingHour: cal.component(.hour, from: start), minute: cal.component(.minute, from: start), second: 0, of: now) ?? now
        let endToday = cal.date(bySettingHour: cal.component(.hour, from: end), minute: cal.component(.minute, from: end), second: 0, of: now) ?? now
        
        if now < startToday { return 0.0 }
        if now > endToday { return 1.0 }
        
        let totalDuration = endToday.timeIntervalSince(startToday)
        let elapsed = now.timeIntervalSince(startToday)
        return max(0.0, min(1.0, elapsed / totalDuration))
    }
    
    // Computed counts
    var activeCount: Int { shifts.filter { status(for: $0) == .active }.count }
    var upcomingCount: Int { shifts.filter { status(for: $0) == .upcoming }.count }
    var endedCount: Int { shifts.filter { status(for: $0) == .ended }.count }
    
    // Actions
    func removeShift(_ shift: StaffShift) {
        shifts.removeAll { $0.id == shift.id }
    }
    
    func addShift(_ shift: StaffShift) {
        shifts.append(shift)
    }
}
