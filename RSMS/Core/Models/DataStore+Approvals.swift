//
//  DataStore+Approvals.swift
//  RSMS
//

import Foundation

extension DataStore {
    
    // MARK: - Discount Approval Requests
    
    @MainActor
    func fetchDiscountApprovalRequests() async throws {
        self.discountApprovalRequests = try await api.fetch("discount_approval_requests")
    }
    
    @MainActor
    func createApprovalRequest(
        cartId: UUID,
        clientId: UUID,
        associateId: UUID,
        discountType: DiscountType,
        discountValue: Double,
        cartTotal: Double,
        reason: String?
    ) async throws -> DiscountApprovalRequest {
        
        let request = DiscountApprovalRequest(
            id: UUID(),
            cartId: cartId,
            clientId: clientId,
            associateId: associateId,
            managerId: nil, // To be assigned when a manager acts on it
            discountType: discountType,
            discountValue: discountValue,
            cartTotal: cartTotal,
            reasonForDiscount: reason,
            status: .pending,
            createdAt: Date(),
            decisionDate: nil,
            managerNotes: nil
        )
        
        // Database sync
        do {
            _ = try await api.insert("discount_approval_requests", record: request)
        } catch {
            print("Supabase insert failed for discount_approval_requests: \(error)")
        }
        
        // Optimistic update
        self.discountApprovalRequests.append(request)
        
        // Notify all Boutique Managers in the same store
        // (For simplicity in this mock, we just create a notification targeting the first manager we find, or we could add a generic "store_managers" recipient ID)
        if let manager = self.users.first(where: { $0.role == .boutiqueManager }) {
            try await createNotification(
                recipientId: manager.id,
                title: "Discount Approval Requested",
                message: "A \(discountType == .percentage ? "\(Int(discountValue))%" : "₹\(Int(discountValue))") discount requires approval.",
                type: .approvalRequest,
                relatedEntityId: request.id
            )
        }
        
        return request
    }
    
    @MainActor
    func updateApprovalRequestStatus(
        requestId: UUID,
        managerId: UUID,
        newStatus: DiscountApprovalStatus,
        managerNotes: String?
    ) async throws {
        guard let index = self.discountApprovalRequests.firstIndex(where: { $0.id == requestId }) else { return }
        
        self.discountApprovalRequests[index].status = newStatus
        self.discountApprovalRequests[index].managerId = managerId
        self.discountApprovalRequests[index].decisionDate = Date()
        self.discountApprovalRequests[index].managerNotes = managerNotes
        
        let request = self.discountApprovalRequests[index]
        
        // Database sync
        do {
            try await api.update("discount_approval_requests", id: requestId, record: request)
        } catch {
            print("Supabase update failed for discount_approval_requests: \(error)")
        }
        
        // Notify the Associate
        try await createNotification(
            recipientId: request.associateId,
            title: newStatus == .approved ? "Discount Approved" : "Discount Rejected",
            message: newStatus == .approved ? "Your discount request has been approved." : "Your discount request was rejected: \(managerNotes ?? "No reason provided")",
            type: .approvalDecision,
            relatedEntityId: request.id // Linking to request, which links to cart
        )
    }
    
    @MainActor
    func deleteApprovalRequest(id: UUID) async throws {
        do {
            try await api.delete("discount_approval_requests", id: id)
        } catch {
            print("Supabase delete failed for discount_approval_requests: \(error)")
        }
        self.discountApprovalRequests.removeAll(where: { $0.id == id })
    }
    
    // MARK: - Notifications
    
    @MainActor
    func fetchAppNotifications() async throws {
        do {
            let fetched: [AppNotification] = try await api.fetch("app_notifications")
            // Merge: keep any locally-created notifications that haven't been persisted yet
            let localOnlyNotifications = self.appNotifications.filter { local in
                !fetched.contains(where: { $0.id == local.id })
            }
            self.appNotifications = fetched + localOnlyNotifications
        } catch {
            print("[DataStore] ⚠️ Failed to fetch app_notifications from Supabase: \(error)")
            print("[DataStore] ℹ️ Keeping \(self.appNotifications.count) locally cached notifications. If this persists, check RLS SELECT policies on app_notifications table.")
            // Keep existing local notifications instead of wiping them
        }
    }
    
    @MainActor
    func createNotification(
        recipientId: UUID,
        title: String,
        message: String,
        type: NotificationType,
        relatedEntityId: UUID
    ) async throws {
        let notification = AppNotification(
            id: UUID(),
            recipientId: recipientId,
            title: title,
            message: message,
            type: type,
            relatedEntityId: relatedEntityId,
            isRead: false,
            createdAt: Date()
        )
        
        do {
            _ = try await api.insert("app_notifications", record: notification)
        } catch {
            print("[DataStore] ⚠️ Supabase insert failed for app_notifications (type: \(type.rawValue), recipient: \(recipientId)): \(error)")
            print("[DataStore] ℹ️ If this is an RLS or constraint error, verify the app_notifications table allows INSERT for the current role and that the 'type' column accepts '\(type.rawValue)'.")
        }
        // Always append locally so the notification is visible within the current session
        self.appNotifications.append(notification)
    }
    
    @MainActor
    func markNotificationAsRead(id: UUID) async throws {
        if let index = self.appNotifications.firstIndex(where: { $0.id == id }) {
            self.appNotifications[index].isRead = true
            let notification = self.appNotifications[index]
            do {
                try await api.update("app_notifications", id: id, record: notification)
            } catch {
                print("Supabase update failed for app_notifications: \(error)")
            }
        }
    }
    
    @MainActor
    func deleteNotification(id: UUID) async throws {
        do {
            try await api.delete("app_notifications", id: id)
        } catch {
            print("Supabase delete failed for app_notifications: \(error)")
        }
        self.appNotifications.removeAll(where: { $0.id == id })
    }
}
