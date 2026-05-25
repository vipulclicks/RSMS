//
//  SalesAssociateProfileViewModel.swift
//  RSMS
//
//  ViewModel for managing the Sales Associate Profile screen.
//  Aligned with iOS 17+ Observation framework.
//

import SwiftUI
import Foundation

@Observable
final class SalesAssociateProfileViewModel {
    // MARK: - Mock Performance Statistics
    var todaySales: String = "₹2,34,500"
    var appointmentsCount: Int = 4
    
    // MARK: - User Information Extensions
    var department: String = "High Jewelry & Haute Couture"
    var shiftTiming: String = "Morning Shift (09:00 AM - 06:00 PM)"
    var reportingManager: String = "Sophie Martin"
    
    // MARK: - Commission & Goals
    var commissionEarned: String = "₹45,200"
    var commissionApprover: String = "Sophie Martin"
    var salesGoalsAchieved: String = "₹8,50,000"
    var salesGoalsTarget: String = "₹10,00,000"
    var salesGoalsPercentage: Double = 0.85

    func setup(dataStore: DataStore, staffId: UUID, storeId: UUID) {
        // Today's Sales from daily sales goal target
        if let dailyGoal = dataStore.salesGoals.first(where: { $0.staffId == staffId && $0.period == .daily }) {
            self.todaySales = "₹\(Int(dailyGoal.targetAmount).formatted())"
        } else {
            self.todaySales = "₹2,34,500"
        }

        // Appointments Handled (count of completed appointments)
        let completedCount = dataStore.appointments.filter { $0.associateId == staffId && $0.status == .completed }.count
        if completedCount > 0 {
            self.appointmentsCount = completedCount
        } else {
            self.appointmentsCount = 4
        }

        // Shift Timing from staff shifts
        if let shift = dataStore.staffShifts.first(where: { $0.staffId == staffId }) {
            let roleName = shift.role.replacingOccurrences(of: "_", with: " ").capitalized
            self.shiftTiming = "\(roleName) Shift (\(shift.startTime) - \(shift.endTime))"
        }

        // Monthly goal target progress
        if let monthlyGoal = dataStore.salesGoals.first(where: { $0.staffId == staffId && $0.period == .monthly }) {
            self.salesGoalsTarget = "₹\(Int(monthlyGoal.targetAmount).formatted())"
            self.salesGoalsAchieved = "₹\(Int(monthlyGoal.achievedAmount).formatted())"
            self.salesGoalsPercentage = monthlyGoal.targetAmount > 0 ? (monthlyGoal.achievedAmount / monthlyGoal.targetAmount) : 0.0
        }
    }
    
    // MARK: - Device & Session Information
    var currentDevice: String {
        #if targetEnvironment(simulator)
        return "iOS Simulator"
        #else
        return UIDevice.current.name
        #endif
    }
    
    var lastLoginTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        // Simulate a recent login time from earlier today
        let calendar = Calendar.current
        let today = Date()
        if let mockLoginDate = calendar.date(bySettingHour: 8, minute: 32, second: 0, of: today) {
            return formatter.string(from: mockLoginDate)
        }
        return formatter.string(from: today)
    }
    
    let appVersion: String = "1.2.0 (Build 42)"
    
    // MARK: - Preferences
    var pushNotificationsEnabled: Bool = true
    var emailNotificationsEnabled: Bool = true
    var biometricsEnabled: Bool = true
    var privacyConsentGiven: Bool = true
}
