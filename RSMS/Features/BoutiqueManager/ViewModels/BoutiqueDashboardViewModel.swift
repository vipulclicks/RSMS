//
//  BoutiqueDashboardViewModel.swift
//  RSMS
//

import SwiftUI
import Observation

struct LowStockAlert: Identifiable {
    let id: UUID
    let product: Product
    let stockItem: StockItem
}

@Observable
final class BoutiqueDashboardViewModel {

    // MARK: - KPIs Data
    private(set) var todaySales: Double = 0.0
    private(set) var salesTarget: Double = 0.0
    private(set) var salesProgress: Double = 0.0
    private(set) var appointmentCount: Int = 0
    private(set) var lowStockAlertCount: Int = 0
    private(set) var topSellingCategory: String? = nil
    private(set) var shifts: [StaffShift] = []

    // Internal collections (useful if UI wants to display lists later)
    private(set) var todayTransactions: [Transaction] = []
    private(set) var lowStockAlerts: [LowStockAlert] = []
    
    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Data Loading
    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch stores first so storeName lookup works
            try await dataStore.fetchStores()
            
            // A) Today's Sales
            try await dataStore.fetchUsers(storeId: storeId)
            let associateIds = Set(dataStore.users.filter { $0.role == .salesAssociate }.map { $0.id })
            
            try await dataStore.fetchTransactions(storeId: storeId)
            self.todayTransactions = dataStore.transactions.filter {
                $0.status == .completed && 
                Calendar.current.isDateInToday($0.createdAt) &&
                associateIds.contains($0.associateId)
            }
            self.todaySales = self.todayTransactions.reduce(0.0) { $0 + $1.totalAmount }
            
            // B) Sales Target
            try await dataStore.fetchSalesGoals(storeId: storeId)
            let activeGoal = dataStore.salesGoals.first {
                $0.storeId == storeId && $0.startDate <= Date() && $0.endDate >= Date()
            }
            self.salesTarget = activeGoal?.targetAmount ?? 0.0
            
            // C) Sales Progress
            if self.salesTarget > 0 {
                self.salesProgress = min(1.0, self.todaySales / self.salesTarget)
            } else {
                self.salesProgress = 0.0
            }
            
            // D) Appointments Count & Clients
            try await dataStore.fetchAppointments(storeId: storeId)
            try await dataStore.fetchClients()
            self.appointmentCount = dataStore.appointments.filter {
                Calendar.current.isDateInToday($0.dateTime)
            }.count
            
            // E) Low Stock Alerts
            try await dataStore.fetchStockItems(storeId: storeId)
            let lowStockItems = dataStore.stockItems.filter {
                $0.quantity < 5 && $0.status == .available
            }
            if dataStore.products.isEmpty {
                try await dataStore.fetchProducts()
            }
            self.lowStockAlerts = lowStockItems.compactMap { item in
                guard let product = dataStore.products.first(where: { $0.id == item.productId }) else { return nil }
                return LowStockAlert(id: item.id, product: product, stockItem: item)
            }
            self.lowStockAlertCount = self.lowStockAlerts.count
            
            // F) Fetch Dashboard Summaries (for targets if needed)
            try await dataStore.fetchDashboardSummaries(storeId: storeId)
            
            // G) Top Selling Category (Client-Side Computation)
            self.topSellingCategory = try await computeTopCategory(dataStore: dataStore)
            
            // H) Staff On Shift Today
            try await dataStore.fetchStaffShifts(storeId: storeId)
            let todaysShifts = dataStore.staffShifts.filter {
                Calendar.current.isDateInToday($0.shiftDate)
            }
            self.shifts = todaysShifts
            
        } catch {
            print("Failed to load dashboard data: \(error)")
            self.errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func computeTopCategory(dataStore: DataStore) async throws -> String? {
        guard !todayTransactions.isEmpty else { return nil }
        
        // We need products to resolve categories
        if dataStore.products.isEmpty {
            try await dataStore.fetchProducts()
        }
        
        var categoryCounts: [String: Int] = [:]
        
        for transaction in todayTransactions {
            try await dataStore.fetchUniversalCartItems(cartId: transaction.cartId)
            
            for item in dataStore.universalCartItems {
                if let product = dataStore.products.first(where: { $0.id == item.productId }) {
                    categoryCounts[product.category, default: 0] += item.quantity
                }
            }
        }
        
        return categoryCounts.max { a, b in a.value < b.value }?.key
    }

    // MARK: - Formatting Helpers

    var formattedDate: String {
        RSMSDateFormatter.fullDate.string(from: .now)
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹0"
    }
    
    // MARK: - Actions
    func simulateStockDrop() {
        // Simulation disabled in prod environment
    }
    
    func reorderItem(for productId: UUID) {
        // Implement reorder logic via DataStore movement request
        // For now, optimistically remove from alerts
        self.lowStockAlerts.removeAll { $0.product.id == productId }
        self.lowStockAlertCount = self.lowStockAlerts.count
    }
}
