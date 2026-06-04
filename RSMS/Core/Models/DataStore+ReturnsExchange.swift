//
//  DataStore+ReturnsExchange.swift
//  RSMS
//

import Foundation

extension DataStore {
    @MainActor
    public func fetchPOSReturnsExchanges() async {
        // Fetch user profiles to resolve inspector names
        do {
            try await fetchUsers()
        } catch {
            print("[DataStore] ⚠️ Failed to fetch user_profiles for returns/exchanges: \(error)")
        }

        do {
            let returns: [POSReturnRequest] = try await api.fetch("return_requests")
            self.posReturnRequests = returns
        } catch {
            print("[DataStore] ⚠️ Failed to fetch return_requests: \(error)")
        }
        
        do {
            let exchanges: [POSExchangeRequest] = try await api.fetch("exchange_requests")
            self.posExchangeRequests = exchanges
        } catch {
            print("[DataStore] ⚠️ Failed to fetch exchange_requests: \(error)")
        }
        
        do {
            let audits: [POSReturnAuditLog] = try await api.fetch("returns_exchange_audit_logs")
            self.posReturnAuditLogs = audits
        } catch {
            print("[DataStore] ⚠️ Failed to fetch returns_exchange_audit_logs: \(error)")
        }
        
        // Auto sync if online
        await syncPOSReturnsExchanges()
    }
    
    @MainActor
    public func syncPOSReturnsExchanges() async {
        guard !pendingReturnRequests.isEmpty || !pendingExchangeRequests.isEmpty ||
              !pendingReturnUpdates.isEmpty || !pendingExchangeUpdates.isEmpty ||
              !pendingAuditLogs.isEmpty else {
            return
        }
        
        print("[DataStore] 🔄 Syncing Returns & Exchanges offline requests...")
        
        // 1. Sync pending return requests
        var returnsSynced: [UUID] = []
        for req in pendingReturnRequests {
            do {
                try await api.insert("return_requests", record: req)
                returnsSynced.append(req.id)
            } catch {
                print("[DataStore] Return request \(req.id) sync failed: \(error)")
            }
        }
        pendingReturnRequests.removeAll { returnsSynced.contains($0.id) }
        
        // 2. Sync pending exchange requests
        var exchangesSynced: [UUID] = []
        for req in pendingExchangeRequests {
            do {
                try await api.insert("exchange_requests", record: req)
                exchangesSynced.append(req.id)
            } catch {
                print("[DataStore] Exchange request \(req.id) sync failed: \(error)")
            }
        }
        pendingExchangeRequests.removeAll { exchangesSynced.contains($0.id) }
        
        // 3. Sync pending return updates
        var returnUpdatesSynced: [UUID] = []
        for req in pendingReturnUpdates {
            do {
                try await api.update("return_requests", id: req.id, record: req)
                returnUpdatesSynced.append(req.id)
            } catch {
                print("[DataStore] Return update \(req.id) sync failed: \(error)")
            }
        }
        pendingReturnUpdates.removeAll { returnUpdatesSynced.contains($0.id) }
        
        // 4. Sync pending exchange updates
        var exchangeUpdatesSynced: [UUID] = []
        for req in pendingExchangeUpdates {
            do {
                try await api.update("exchange_requests", id: req.id, record: req)
                exchangeUpdatesSynced.append(req.id)
            } catch {
                print("[DataStore] Exchange update \(req.id) sync failed: \(error)")
            }
        }
        pendingExchangeUpdates.removeAll { exchangeUpdatesSynced.contains($0.id) }
        
        // 5. Sync pending audit logs
        var auditsSynced: [UUID] = []
        for log in pendingAuditLogs {
            do {
                try await api.insert("returns_exchange_audit_logs", record: log)
                auditsSynced.append(log.id)
            } catch {
                print("[DataStore] Audit log \(log.id) sync failed: \(error)")
            }
        }
        pendingAuditLogs.removeAll { auditsSynced.contains($0.id) }
    }
    
    @MainActor
    public func reconcileStockItem(
        productId: UUID,
        storeId: UUID,
        quantity: Int,
        status: StockStatus,
        location: String
    ) async throws {
        // Fetch fresh stock data to ensure we have latest
        try? await fetchStockItems(storeId: storeId)
        
        // Tiered matching: prefer exact, then relax to find the real stock record
        let exactMatch = stockItems.firstIndex(where: {
            $0.productId == productId &&
            $0.storeId == storeId &&
            $0.status == status &&
            $0.location == location
        })
        
        let statusMatch = stockItems.firstIndex(where: {
            $0.productId == productId &&
            $0.storeId == storeId &&
            $0.status == status
        })
        
        let broadMatch = stockItems.firstIndex(where: {
            $0.productId == productId &&
            $0.storeId == storeId
        })
        
        if let idx = exactMatch ?? statusMatch ?? broadMatch {
            let existing = stockItems[idx]
            let newQty = max(existing.quantity + quantity, 0)
            let updated = StockItem(
                id: existing.id,
                productId: existing.productId,
                storeId: existing.storeId,
                quantity: newQty,
                rfidTag: existing.rfidTag,
                location: existing.location ?? location,
                status: existing.status,
                lastScannedAt: Date(),
                updatedAt: Date()
            )
            try await updateStockItem(updated)
            print("[Reconcile] Updated stock for product \(productId): \(existing.quantity) → \(newQty)")
        } else {
            // No matching stock item at all — create a new one
            let newItem = StockItem(
                id: UUID(),
                productId: productId,
                storeId: storeId,
                quantity: max(quantity, 0),
                rfidTag: nil,
                location: location,
                status: status,
                lastScannedAt: Date(),
                updatedAt: Date()
            )
            try await createStockItem(newItem)
            print("[Reconcile] Created new stock item for product \(productId) with qty \(quantity)")
        }
    }
    
    @MainActor
    public func deletePOSReturnRequest(id: UUID) async throws {
        try await api.delete("return_requests", id: id)
        self.posReturnRequests.removeAll { $0.id == id }
    }
    
    @MainActor
    public func deletePOSExchangeRequest(id: UUID) async throws {
        try await api.delete("exchange_requests", id: id)
        self.posExchangeRequests.removeAll { $0.id == id }
    }
}

