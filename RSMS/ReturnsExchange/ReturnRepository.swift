//
//  ReturnRepository.swift
//  RSMS
//

import Foundation

@MainActor
final class ReturnRepository {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    func fetchReturnRequests() async -> [POSReturnRequest] {
        do {
            let fetched: [POSReturnRequest] = try await SupabaseClient.shared.fetch("return_requests")
            dataStore.posReturnRequests = fetched
            return fetched
        } catch {
            print("[ReturnRepository] offline or error: \(error.localizedDescription)")
            return dataStore.posReturnRequests
        }
    }
    
    func createReturnRequest(_ request: POSReturnRequest) async throws {
        // Prevent duplicates
        if dataStore.posReturnRequests.contains(where: { $0.id == request.id }) {
            return
        }
        
        do {
            try await SupabaseClient.shared.insert("return_requests", record: request)
            dataStore.posReturnRequests.append(request)
        } catch {
            print("[ReturnRepository] Error inserting return: \(error.localizedDescription)")
            if isOfflineError(error) {
                print("[ReturnRepository] Queued return request \(request.id) offline")
                dataStore.posReturnRequests.append(request)
                dataStore.pendingReturnRequests.append(request)
            } else {
                throw error
            }
        }
        
        // Log Audit Log
        let audit = POSReturnAuditLog(
            requestId: request.id,
            requestType: "return",
            userId: request.associateId,
            userRole: "sales_associate",
            action: "Return Requested",
            previousStatus: nil,
            newStatus: request.status.rawValue
        )
        try await createAuditLog(audit)
    }
    
    func updateReturnRequest(_ request: POSReturnRequest, user: UserProfile, action: String, prevStatus: POSReturnStatus) async throws {
        do {
            try await SupabaseClient.shared.update("return_requests", id: request.id, record: request)
            if let idx = dataStore.posReturnRequests.firstIndex(where: { $0.id == request.id }) {
                dataStore.posReturnRequests[idx] = request
            }
        } catch {
            print("[ReturnRepository] Error updating return: \(error.localizedDescription)")
            if isOfflineError(error) {
                print("[ReturnRepository] Queued update for return request \(request.id) offline")
                if let idx = dataStore.posReturnRequests.firstIndex(where: { $0.id == request.id }) {
                    dataStore.posReturnRequests[idx] = request
                }
                dataStore.pendingReturnUpdates.removeAll { $0.id == request.id }
                dataStore.pendingReturnUpdates.append(request)
            } else {
                throw error
            }
        }
        
        let audit = POSReturnAuditLog(
            requestId: request.id,
            requestType: "return",
            userId: user.id,
            userRole: user.role.rawValue,
            action: action,
            previousStatus: prevStatus.rawValue,
            newStatus: request.status.rawValue
        )
        try await createAuditLog(audit)
    }
    
    func createAuditLog(_ audit: POSReturnAuditLog) async throws {
        do {
            try await SupabaseClient.shared.insert("returns_exchange_audit_logs", record: audit)
            dataStore.posReturnAuditLogs.append(audit)
        } catch {
            print("[ReturnRepository] Error creating audit log: \(error.localizedDescription)")
            if isOfflineError(error) {
                print("[ReturnRepository] Queued audit log \(audit.id) offline")
                dataStore.posReturnAuditLogs.append(audit)
                dataStore.pendingAuditLogs.append(audit)
            } else {
                throw error
            }
        }
    }
}

// MARK: - Offline Detection Helper

private func isOfflineError(_ error: Error) -> Bool {
    if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet, .timedOut, .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
            return true
        default:
            return false
        }
    }
    let nsErr = error as NSError
    if nsErr.domain == NSURLErrorDomain {
        return true
    }
    return false
}
