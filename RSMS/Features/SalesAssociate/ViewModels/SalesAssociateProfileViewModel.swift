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
    
    // Lists for drill-down views
    var todayTransactionsList: [Transaction] = []
    var todayAppointmentsList: [Appointment] = []
    
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
        // Today's Sales
        let todayTransactions = dataStore.transactions.filter {
            $0.associateId == staffId &&
            Calendar.current.isDateInToday($0.createdAt) &&
            $0.status == .completed
        }
        self.todayTransactionsList = todayTransactions
        
        let todaySalesTotal = todayTransactions.reduce(0.0) { $0 + $1.totalAmount }
        if todaySalesTotal > 0 {
            self.todaySales = "₹\(Int(todaySalesTotal).formatted())"
        } else {
            self.todaySales = "₹0"
        }

        // Appointments Handled (Today)
        let todayAppointments = dataStore.appointments.filter { 
            $0.associateId == staffId && 
            Calendar.current.isDateInToday($0.dateTime)
        }
        self.todayAppointmentsList = todayAppointments
        self.appointmentsCount = todayAppointments.filter { $0.status == .completed }.count

        // Shift Timing from staff shifts
        if let shift = dataStore.staffShifts.first(where: { $0.staffId == staffId }) {
            let roleName = shift.role.replacingOccurrences(of: "_", with: " ").capitalized
            self.shiftTiming = "\(roleName) Shift (\(shift.startTime) - \(shift.endTime))"
        } else {
            self.shiftTiming = "Not Assigned"
        }

        // Monthly goal target progress
        if let monthlyGoal = dataStore.salesGoals.first(where: { $0.staffId == staffId && $0.period == .monthly }) {
            self.salesGoalsTarget = "₹\(Int(monthlyGoal.targetAmount).formatted())"
            self.salesGoalsAchieved = "₹\(Int(monthlyGoal.achievedAmount).formatted())"
            self.salesGoalsPercentage = monthlyGoal.targetAmount > 0 ? (monthlyGoal.achievedAmount / monthlyGoal.targetAmount) : 0.0
        } else {
            self.salesGoalsTarget = "₹0"
            self.salesGoalsAchieved = "₹0"
            self.salesGoalsPercentage = 0.0
        }
        
        // Department & Reporting Manager
        if let user = dataStore.users.first(where: { $0.id == staffId }) {
            if user.role == .salesAssociate {
                self.department = "Sales Floor"
            } else {
                self.department = user.role.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
            }
        }
        
        if let manager = dataStore.users.first(where: { $0.storeId == storeId && $0.role == .boutiqueManager }) {
            self.reportingManager = manager.fullName
            self.commissionApprover = manager.fullName
        } else {
            self.reportingManager = "Pending Assignment"
            self.commissionApprover = "Pending Assignment"
        }
        
        // Commission
        let totalCommissions = dataStore.commissions.filter { $0.staffId == staffId && $0.status == .approved }.reduce(0.0) { $0 + $1.amount }
        if totalCommissions > 0 {
            self.commissionEarned = "₹\(Int(totalCommissions).formatted())"
        } else {
            self.commissionEarned = "₹0"
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
