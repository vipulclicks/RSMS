//
//  ServiceCenterTrackingViewModel.swift
//  RSMS
//
//  Created by Antigravity on 2026-06-03.
//

import SwiftUI
import Observation

// MARK: - UI Enums

enum ServiceRequestStatus: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case dispatched = "Dispatched"
    case inService = "In Service"
    case waitingParts = "Waiting Parts"
    case qualityCheck = "Quality Check"
    case readyForReturn = "Ready for Return"
    case completed = "Completed"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .pending: return RSMSTheme.warning
        case .dispatched: return RSMSTheme.info
        case .inService: return RSMSTheme.gold
        case .waitingParts: return RSMSTheme.danger
        case .qualityCheck: return RSMSTheme.gold.opacity(0.8)
        case .readyForReturn: return RSMSTheme.success.opacity(0.8)
        case .completed: return RSMSTheme.success
        }
    }
}

enum ServicePriority: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .low: return RSMSTheme.success
        case .medium: return RSMSTheme.warning
        case .high: return RSMSTheme.gold
        case .urgent: return RSMSTheme.danger
        }
    }
}

enum ServiceIssueType: String, CaseIterable, Identifiable {
    case mechanicalRepair = "Mechanical Repair"
    case damage = "Damage"
    case polishing = "Polishing"
    case batteryReplacement = "Battery Replacement"
    case strapReplacement = "Strap Replacement"
    case qualityInspection = "Quality Inspection"
    case other = "Other"
    
    var id: String { rawValue }
}

// MARK: - ViewModel

@Observable
class ServiceCenterTrackingViewModel {
    
    var isShowingNewRequestModal = false
    var isShowingRequestDetails = false
    var selectedRequest: ServiceRequest?
    
    // Form fields
    var newProductSearch = ""
    var selectedProduct: Product?
    var newSku = ""
    var newSerialNumber = ""
    var newCategory = "Watches"
    var newCustomerName = ""
    
    var newIsUnderWarranty = true
    var newIssueType: ServiceIssueType = .mechanicalRepair
    var newPriority: ServicePriority = .medium
    var newIssueDescription = ""
    
    // Search & Filter
    var searchText = ""
    var filterStatus: ServiceRequestStatus? = nil
    
    // Products & Categories
    var products: [Product] = []
    var availableCategories: [String] = ["Watches", "Jewelry", "Handbags"]
    
    var searchResults: [Product] {
        guard !newProductSearch.isEmpty else { return [] }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(newProductSearch) ||
            $0.sku.localizedCaseInsensitiveContains(newProductSearch)
        }.prefix(8).map { $0 }
    }
    
    var isSubmitting = false
    var errorMessage: String? = nil
    var showErrorAlert = false
    
    init() {}
    
    func getStatus(for request: ServiceRequest) -> ServiceRequestStatus {
        ServiceRequestStatus(rawValue: request.status) ?? .pending
    }
    
    func getStage(for activity: ServiceActivity) -> ServiceRequestStatus {
        ServiceRequestStatus(rawValue: activity.stage) ?? .pending
    }
    
    func pendingRepairsCount(dataStore: DataStore) -> Int {
        dataStore.serviceRequests.filter { getStatus(for: $0) == .pending || getStatus(for: $0) == .dispatched }.count
    }
    
    func inServiceCount(dataStore: DataStore) -> Int {
        dataStore.serviceRequests.filter { getStatus(for: $0) == .inService || getStatus(for: $0) == .waitingParts || getStatus(for: $0) == .qualityCheck }.count
    }
    
    func readyForReturnCount(dataStore: DataStore) -> Int {
        dataStore.serviceRequests.filter { getStatus(for: $0) == .readyForReturn }.count
    }
    
    func completedCount(dataStore: DataStore) -> Int {
        dataStore.serviceRequests.filter { getStatus(for: $0) == .completed }.count
    }
    
    func filteredRequests(dataStore: DataStore) -> [ServiceRequest] {
        var requests = dataStore.serviceRequests
        
        if let status = filterStatus {
            requests = requests.filter { getStatus(for: $0) == status }
        }
        
        if !searchText.isEmpty {
            requests = requests.filter {
                $0.requestId.localizedCaseInsensitiveContains(searchText) ||
                $0.productName.localizedCaseInsensitiveContains(searchText) ||
                $0.sku.localizedCaseInsensitiveContains(searchText) ||
                $0.serialNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by newest first
        return requests.sorted { $0.dispatchDate > $1.dispatchDate }
    }
    
    func sortedActivities(dataStore: DataStore) -> [ServiceActivity] {
        dataStore.serviceActivities.sorted { $0.timestamp > $1.timestamp }
    }
    
    func resetForm() {
        newProductSearch = ""
        selectedProduct = nil
        newSku = ""
        newSerialNumber = ""
        newCategory = availableCategories.first ?? "Watches"
        newCustomerName = ""
        newIsUnderWarranty = true
        newIssueType = .mechanicalRepair
        newPriority = .medium
        newIssueDescription = ""
    }
    
    func submitNewRequest(dataStore: DataStore, storeId: UUID) async {
        isSubmitting = true
        
        let newRequestId = "SRX-\(Int.random(in: 1000...9999))"
        
        let pName = selectedProduct?.name ?? (newProductSearch.isEmpty ? "Unknown Product" : newProductSearch)
        let pSku = selectedProduct?.sku ?? (newSku.isEmpty ? "SKU-TBD" : newSku)
        let pId = selectedProduct?.id
        
        let request = ServiceRequest(
            id: UUID(),
            storeId: storeId,
            requestId: newRequestId,
            productId: pId,
            productName: pName,
            sku: pSku,
            serialNumber: newSerialNumber.isEmpty ? "SN-TBD" : newSerialNumber,
            category: newCategory,
            customerName: newCustomerName,
            boutiqueName: "Boutique", // Could pull from store name
            serviceCenterName: "Internal Service", // Defaulting as logistics was removed
            dispatchDate: Date(),
            expectedReturnDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            isUnderWarranty: newIsUnderWarranty,
            issueType: newIssueType.rawValue,
            priority: newPriority.rawValue,
            status: ServiceRequestStatus.pending.rawValue,
            issueDescription: newIssueDescription,
            courierProvider: nil,
            trackingId: nil,
            isInsured: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let activity = ServiceActivity(
            id: UUID(),
            requestId: newRequestId,
            productName: pName,
            serviceCenter: "Internal Service",
            stage: ServiceRequestStatus.pending.rawValue,
            timestamp: Date()
        )
        
        do {
            try await dataStore.createServiceRequest(request)
            try await dataStore.createServiceActivity(activity)
            
            await MainActor.run {
                isShowingNewRequestModal = false
                isSubmitting = false
                resetForm()
            }
        } catch {
            print("[ServiceCenterTrackingViewModel] Error saving new request: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                isSubmitting = false
            }
        }
    }
    
    // MARK: - Update Status
    
    func updateRequestStatus(request: ServiceRequest, newStatus: ServiceRequestStatus, dataStore: DataStore) async {
        var updatedRequest = request
        // In Swift, since it's a struct with let properties, we need a helper or just recreate it.
        // Wait, the struct has `let` for all properties.
        // We'll create a new ServiceRequest with updated status and updatedAt.
        let newReq = ServiceRequest(
            id: request.id,
            storeId: request.storeId,
            requestId: request.requestId,
            productId: request.productId,
            productName: request.productName,
            sku: request.sku,
            serialNumber: request.serialNumber,
            category: request.category,
            customerName: request.customerName,
            boutiqueName: request.boutiqueName,
            serviceCenterName: request.serviceCenterName,
            dispatchDate: request.dispatchDate,
            expectedReturnDate: request.expectedReturnDate,
            isUnderWarranty: request.isUnderWarranty,
            issueType: request.issueType,
            priority: request.priority,
            status: newStatus.rawValue,
            issueDescription: request.issueDescription,
            courierProvider: request.courierProvider,
            trackingId: request.trackingId,
            isInsured: request.isInsured,
            createdAt: request.createdAt,
            updatedAt: Date()
        )
        
        let activity = ServiceActivity(
            id: UUID(),
            requestId: request.requestId,
            productName: request.productName,
            serviceCenter: request.serviceCenterName,
            stage: newStatus.rawValue,
            timestamp: Date()
        )
        
        do {
            try await dataStore.updateServiceRequest(newReq)
            try await dataStore.createServiceActivity(activity)
            
            await MainActor.run {
                self.selectedRequest = newReq
            }
        } catch {
            print("[ServiceCenterTrackingViewModel] Error updating status: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    func loadData(dataStore: DataStore, storeId: UUID) async {
        do {
            try await dataStore.fetchServiceRequests(storeId: storeId)
        } catch {
            print("[ServiceCenterTrackingViewModel] Error loading requests: \(error.localizedDescription)")
        }
        
        do {
            try await dataStore.fetchServiceActivities()
        } catch {
            print("[ServiceCenterTrackingViewModel] Error loading activities: \(error.localizedDescription)")
        }
        
        do {
            try await dataStore.fetchProducts()
            print("[ServiceCenterTrackingViewModel] Successfully fetched products. Count: \(dataStore.products.count)")
        } catch {
            print("[ServiceCenterTrackingViewModel] Error loading products: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            self.products = dataStore.products
            print("[ServiceCenterTrackingViewModel] Set self.products to \(self.products.count) items")
            let cats = Array(Set(dataStore.products.map { $0.category })).sorted()
            if !cats.isEmpty {
                self.availableCategories = cats
                if !cats.contains(self.newCategory) {
                    self.newCategory = cats[0]
                }
            }
        }
    }
}
