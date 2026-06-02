//
//  StaffManagementViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class StaffManagementViewModel {

    // MARK: - Data
    private(set) var shifts: [StaffShift] = []
    private(set) var commissions: [Commission] = []
    private(set) var metrics: [PerformanceMetric] = []
    
    private(set) var allStaff: [UserProfile] = []
    var salesAssociates: [UserProfile] {
        allStaff.filter { $0.role == .salesAssociate }
    }
    var inventoryControllers: [UserProfile] {
        allStaff.filter { $0.role == .inventoryController }
    }
    
    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Data Loading
    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataStore.fetchUsers(storeId: storeId)
            self.allStaff = dataStore.users.filter { $0.storeId == storeId }
            
            try await dataStore.fetchStaffShifts(storeId: storeId)
            self.shifts = dataStore.staffShifts.filter { Calendar.current.isDateInToday($0.shiftDate) }
            
            try await dataStore.fetchPerformanceMetrics(storeId: storeId)
            self.metrics = dataStore.performanceMetrics
            
            try await dataStore.fetchCommissions() 
            self.commissions = dataStore.commissions
            
        } catch {
            print("Failed to load shift planning data: \(error)")
            self.errorMessage = "Failed to load shift planning data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    // MARK: - Helpers

    func staffName(for id: UUID, dataStore: DataStore) -> String {
        dataStore.userName(for: id)
    }

    func roleBadgeColor(_ role: String) -> Color {
        switch role {
        case "floor":       return RSMSTheme.success
        case "cashier":     return RSMSTheme.info
        case "back_office": return RSMSTheme.warning
        case "sales_associate": return RSMSTheme.primary
        default:            return RSMSTheme.textSecondary
        }
    }

    func commissionColor(_ status: CommissionStatus) -> Color {
        switch status {
        case .pending:  return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .paid:     return RSMSTheme.info
        }
    }
}
