//
//  ExchangeRepository.swift
//  RSMS
//

import Foundation

@MainActor
final class ExchangeRepository {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    func fetchExchangeRequests() async -> [POSExchangeRequest] {
        do {
            let fetched: [POSExchangeRequest] = try await SupabaseClient.shared.fetch("exchange_requests")
            dataStore.posExchangeRequests = fetched
            return fetched
        } catch {
            print("[ExchangeRepository] offline or error: \(error.localizedDescription)")
            return dataStore.posExchangeRequests
        }
    }
    
    func createExchangeRequest(_ request: POSExchangeRequest) async throws {
        // Prevent duplicates
        if dataStore.posExchangeRequests.contains(where: { $0.id == request.id }) {
            return
        }
        
        do {
            try await SupabaseClient.shared.insert("exchange_requests", record: request)
            dataStore.posExchangeRequests.append(request)
        } catch {
            print("[ExchangeRepository] Error inserting exchange: \(error.localizedDescription)")
            if isOfflineError(error) {
                print("[ExchangeRepository] Queued exchange request \(request.id) offline")
                dataStore.posExchangeRequests.append(request)
                dataStore.pendingExchangeRequests.append(request)
            } else {
                throw error
            }
        }
        
        // Log Audit Log
        let audit = POSReturnAuditLog(
            requestId: request.id,
            requestType: "exchange",
            userId: request.associateId,
            userRole: "sales_associate",
            action: "Exchange Requested",
            previousStatus: nil,
            newStatus: request.status.rawValue
        )
        try await createAuditLog(audit)
    }
    
    func updateExchangeRequest(_ request: POSExchangeRequest, user: UserProfile, action: String, prevStatus: POSExchangeStatus) async throws {
        do {
            try await SupabaseClient.shared.update("exchange_requests", id: request.id, record: request)
            if let idx = dataStore.posExchangeRequests.firstIndex(where: { $0.id == request.id }) {
                dataStore.posExchangeRequests[idx] = request
            }
        } catch {
            print("[ExchangeRepository] Error updating exchange: \(error.localizedDescription)")
            if isOfflineError(error) {
                print("[ExchangeRepository] Queued update for exchange request \(request.id) offline")
                if let idx = dataStore.posExchangeRequests.firstIndex(where: { $0.id == request.id }) {
                    dataStore.posExchangeRequests[idx] = request
                }
                dataStore.pendingExchangeUpdates.removeAll { $0.id == request.id }
                dataStore.pendingExchangeUpdates.append(request)
            } else {
                throw error
            }
        }
        
        let audit = POSReturnAuditLog(
            requestId: request.id,
            requestType: "exchange",
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
            print("[ExchangeRepository] Error creating audit log: \(error.localizedDescription)")
            if isOfflineError(error) {
                print("[ExchangeRepository] Queued audit log \(audit.id) offline")
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
