import SwiftUI
import Observation

@Observable
class LoanerProductManagementViewModel {
    
    // UI State
    var searchText = ""
    var isShowingNewAssignmentModal = false
    var isShowingAssignmentDetails = false
    var selectedAssignment: LoanerAssignment?
    var isSubmitting = false
    var errorMessage: String? = nil
    var showErrorAlert = false
    
    // Form State
    var newCustomerName = ""
    var newCustomerContact = ""
    var newCustomerEmail = ""
    var newRepairRequestId = ""
    var newOriginalProductDetails = ""
    
    var newLoanerProductSearch = ""
    var newSku = ""
    var newSerialNumber = ""
    var newCategory = "Watches"
    var newCondition: LoanerCondition = .excellent
    var newPriority = "Standard"
    
    var newSecurityDeposit: String = ""
    var newAgreementSigned = false
    var newExpectedReturnDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
    var newNotes = ""
    
    // Dependent Data
    var products: [Product] = []
    var availableCategories: [String] = ["Watches", "Jewelry", "Handbags"]
    var selectedProduct: Product?
    
    var searchResults: [Product] {
        guard !newLoanerProductSearch.isEmpty else { return [] }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(newLoanerProductSearch) ||
            $0.sku.localizedCaseInsensitiveContains(newLoanerProductSearch)
        }.prefix(8).map { $0 }
    }
    
    init() {}
    
    // MARK: - Analytics
    
    func availableLoanersCount(dataStore: DataStore) -> Int {
        // Mock logic: Total products minus assigned ones.
        // In real app, might filter products by a "loaner" flag.
        let assignedProductIds = Set(dataStore.loanerAssignments
            .filter { $0.status == LoanerStatus.assigned.rawValue || $0.status == LoanerStatus.overdue.rawValue }
            .compactMap { $0.loanerProductId })
        return products.filter { !assignedProductIds.contains($0.id) }.count
    }
    
    func assignedLoanersCount(dataStore: DataStore) -> Int {
        dataStore.loanerAssignments.filter { $0.status == LoanerStatus.assigned.rawValue }.count
    }
    
    func overdueReturnsCount(dataStore: DataStore) -> Int {
        dataStore.loanerAssignments.filter { $0.status == LoanerStatus.overdue.rawValue || ($0.status == LoanerStatus.assigned.rawValue && $0.expectedReturnDate < Date()) }.count
    }
    
    func returnedTodayCount(dataStore: DataStore) -> Int {
        let calendar = Calendar.current
        return dataStore.loanerAssignments.filter { 
            $0.status == LoanerStatus.returned.rawValue && 
            $0.actualReturnDate != nil && 
            calendar.isDateInToday($0.actualReturnDate!) 
        }.count
    }
    
    // MARK: - Filter Logic
    
    func filteredAssignments(dataStore: DataStore) -> [LoanerAssignment] {
        let sorted = dataStore.loanerAssignments.sorted(by: { $0.createdAt > $1.createdAt })
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter {
            $0.customerName.localizedCaseInsensitiveContains(searchText) ||
            $0.loanerProductName.localizedCaseInsensitiveContains(searchText) ||
            $0.assignmentId.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func sortedActivities(dataStore: DataStore) -> [LoanerActivity] {
        dataStore.loanerActivities.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    // MARK: - Status Updates
    
    func updateAssignmentStatus(assignment: LoanerAssignment, newStatus: LoanerStatus, dataStore: DataStore) async {
        let newAssignment = LoanerAssignment(
            id: assignment.id,
            assignmentId: assignment.assignmentId,
            storeId: assignment.storeId,
            customerName: assignment.customerName,
            customerContact: assignment.customerContact,
            customerEmail: assignment.customerEmail,
            repairRequestId: assignment.repairRequestId,
            originalProductDetails: assignment.originalProductDetails,
            loanerProductId: assignment.loanerProductId,
            loanerProductName: assignment.loanerProductName,
            sku: assignment.sku,
            serialNumber: assignment.serialNumber,
            category: assignment.category,
            condition: assignment.condition,
            securityDeposit: assignment.securityDeposit,
            agreementSigned: assignment.agreementSigned,
            priority: assignment.priority,
            status: newStatus.rawValue,
            notes: assignment.notes,
            assignmentDate: assignment.assignmentDate,
            expectedReturnDate: assignment.expectedReturnDate,
            actualReturnDate: newStatus == .returned ? Date() : assignment.actualReturnDate,
            createdAt: assignment.createdAt,
            updatedAt: Date()
        )
        
        let activity = LoanerActivity(
            id: UUID(),
            assignmentId: assignment.assignmentId,
            loanerProductName: assignment.loanerProductName,
            stage: newStatus.rawValue,
            notes: nil,
            timestamp: Date()
        )
        
        do {
            try await dataStore.updateLoanerAssignment(newAssignment)
            try await dataStore.createLoanerActivity(activity)
            
            await MainActor.run {
                self.selectedAssignment = newAssignment
            }
        } catch {
            print("[LoanerProductManagementViewModel] Error updating status: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    // MARK: - Submission
    
    func submitNewAssignment(dataStore: DataStore, storeId: UUID) async {
        isSubmitting = true
        
        let newAssignmentId = "LNR-\(Int.random(in: 1000...9999))"
        let pName = selectedProduct?.name ?? (newLoanerProductSearch.isEmpty ? "Unknown Product" : newLoanerProductSearch)
        let pSku = selectedProduct?.sku ?? (newSku.isEmpty ? "SKU-TBD" : newSku)
        let pId = selectedProduct?.id
        
        let depositValue = Double(newSecurityDeposit) ?? 0.0
        
        let assignment = LoanerAssignment(
            id: UUID(),
            assignmentId: newAssignmentId,
            storeId: storeId,
            customerName: newCustomerName,
            customerContact: newCustomerContact,
            customerEmail: newCustomerEmail.isEmpty ? nil : newCustomerEmail,
            repairRequestId: newRepairRequestId.isEmpty ? nil : newRepairRequestId,
            originalProductDetails: newOriginalProductDetails.isEmpty ? nil : newOriginalProductDetails,
            loanerProductId: pId,
            loanerProductName: pName,
            sku: pSku,
            serialNumber: newSerialNumber.isEmpty ? "SN-TBD" : newSerialNumber,
            category: newCategory,
            condition: newCondition.rawValue,
            securityDeposit: depositValue,
            agreementSigned: newAgreementSigned,
            priority: newPriority,
            status: LoanerStatus.assigned.rawValue,
            notes: newNotes.isEmpty ? nil : newNotes,
            assignmentDate: Date(),
            expectedReturnDate: newExpectedReturnDate,
            actualReturnDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let activity = LoanerActivity(
            id: UUID(),
            assignmentId: newAssignmentId,
            loanerProductName: pName,
            stage: LoanerStatus.assigned.rawValue,
            notes: "Initial Assignment",
            timestamp: Date()
        )
        
        do {
            try await dataStore.createLoanerAssignment(assignment)
            try await dataStore.createLoanerActivity(activity)
            
            await MainActor.run {
                isShowingNewAssignmentModal = false
                isSubmitting = false
                resetForm()
            }
        } catch {
            print("[LoanerProductManagementViewModel] Error saving new assignment: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                isSubmitting = false
            }
        }
    }
    
    // MARK: - Data Loading
    
    func loadData(dataStore: DataStore, storeId: UUID) async {
        do {
            try await dataStore.fetchLoanerAssignments(storeId: storeId)
        } catch {
            print("[LoanerProductManagementViewModel] Error loading assignments: \(error.localizedDescription)")
        }
        
        do {
            try await dataStore.fetchLoanerActivities()
        } catch {
            print("[LoanerProductManagementViewModel] Error loading activities: \(error.localizedDescription)")
        }
        
        do {
            try await dataStore.fetchProducts()
            print("[LoanerProductManagementViewModel] Successfully fetched products. Count: \(dataStore.products.count)")
        } catch {
            print("[LoanerProductManagementViewModel] Error loading products: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            self.products = dataStore.products
            let cats = Array(Set(dataStore.products.map { $0.category })).sorted()
            if !cats.isEmpty {
                self.availableCategories = cats
            }
        }
    }
    
    // MARK: - Helpers
    
    func resetForm() {
        newCustomerName = ""
        newCustomerContact = ""
        newCustomerEmail = ""
        newRepairRequestId = ""
        newOriginalProductDetails = ""
        newLoanerProductSearch = ""
        newSku = ""
        newSerialNumber = ""
        newSecurityDeposit = ""
        newAgreementSigned = false
        newExpectedReturnDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        newNotes = ""
        selectedProduct = nil
    }
    
    func getStatus(for assignment: LoanerAssignment) -> LoanerStatus {
        LoanerStatus(rawValue: assignment.status) ?? .available
    }
    
    func getStageColor(for stage: String) -> Color {
        switch stage {
        case LoanerStatus.available.rawValue: return RSMSTheme.success
        case LoanerStatus.assigned.rawValue: return RSMSTheme.info
        case LoanerStatus.overdue.rawValue: return RSMSTheme.danger
        case LoanerStatus.returned.rawValue: return RSMSTheme.primary
        case LoanerStatus.maintenance.rawValue: return RSMSTheme.gold
        default: return RSMSTheme.textTertiary
        }
    }
}
