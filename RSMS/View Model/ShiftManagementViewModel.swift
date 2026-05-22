import SwiftUI
import Combine

enum ShiftStatus: String, CaseIterable {
    case active = "Active"
    case upcoming = "Upcoming"
    case ended = "Ended"
}

@Observable
class ShiftManagementViewModel {
    var shifts: [StaffShift] = []
    var salesGoals: [SalesGoal] = []
    var commissions: [Commission] = []
    
    // State
    var isLoading = false
    var errorMessage: String?
    
    // Timer to trigger UI updates for progress bars and live clocks
    var currentTime: Date = Date()
    
    init() {
        // Timer for progress bars and live clock updates
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }
    
    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataStore.fetchStaffShifts(storeId: storeId)
            self.shifts = dataStore.staffShifts.filter { Calendar.current.isDateInToday($0.shiftDate) }
            
            try await dataStore.fetchSalesGoals(storeId: storeId)
            self.salesGoals = dataStore.salesGoals
            
            try await dataStore.fetchCommissions()
            // In a real app we might filter commissions by storeId or specific staff,
            // but for now we'll take what's loaded.
            self.commissions = dataStore.commissions
        } catch {
            print("Failed to load shift monitor data: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func getStaffName(for staffId: UUID, dataStore: DataStore) -> String {
        return dataStore.userName(for: staffId)
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
    func removeShiftLocally(_ shift: StaffShift) {
        shifts.removeAll { $0.id == shift.id }
    }
    
    @MainActor
    func deleteShift(_ shift: StaffShift, dataStore: DataStore) async {
        do {
            try await dataStore.deleteStaffShift(id: shift.id)
            removeShiftLocally(shift)
        } catch {
            print("Failed to delete shift: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func addShift(_ shift: StaffShift, dataStore: DataStore) async {
        do {
            try await dataStore.createStaffShift(shift)
            withAnimation {
                shifts.append(shift)
            }
        } catch {
            print("Failed to create shift: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
}
