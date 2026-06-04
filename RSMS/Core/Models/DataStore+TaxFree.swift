//
//  DataStore+TaxFree.swift
//  RSMS
//

import Foundation

extension DataStore {
    
    // MARK: - Configurations
    
    @MainActor
    public func fetchTaxFreeConfigs() async throws {
        do {
            let fetched: [TaxFreeConfig] = try await api.fetch("tax_free_configurations")
            self.taxFreeConfigs = fetched
        } catch {
            print("[DataStore] ⚠️ Failed to fetch tax_free_configurations: \(error)")
            // Fallback: If no config exists, seed a default configurations list for existing stores
            if self.taxFreeConfigs.isEmpty {
                self.taxFreeConfigs = self.stores.map { store in
                    TaxFreeConfig(
                        storeId: store.id,
                        isEnabled: true,
                        minPurchaseAmount: 10000,
                        refundPercentage: 100,
                        serviceFee: 0,
                        eligibleCountries: ["United States", "United Kingdom", "Canada", "Singapore", "Japan", "France", "Germany"]
                    )
                }
            }
        }
    }
    
    @MainActor
    public func saveTaxFreeConfig(_ config: TaxFreeConfig) async throws {
        // Find if config already exists
        if let idx = self.taxFreeConfigs.firstIndex(where: { $0.id == config.id || $0.storeId == config.storeId }) {
            let existing = self.taxFreeConfigs[idx]
            var updated = config
            updated.id = existing.id
            
            do {
                try await api.update("tax_free_configurations", id: existing.id, record: updated)
            } catch {
                print("[DataStore] ⚠️ Failed to update tax_free_configurations in Supabase: \(error)")
            }
            self.taxFreeConfigs[idx] = updated
        } else {
            do {
                let created: TaxFreeConfig = try await api.insert("tax_free_configurations", record: config)
                self.taxFreeConfigs.append(created)
            } catch {
                print("[DataStore] ⚠️ Failed to insert tax_free_configurations to Supabase: \(error)")
                self.taxFreeConfigs.append(config)
            }
        }
    }
    
    @MainActor
    public func getTaxFreeConfig(for storeId: UUID) -> TaxFreeConfig {
        if let config = taxFreeConfigs.first(where: { $0.storeId == storeId }) {
            return config
        }
        // Return default configuration if none matches or is loaded
        let defaultConf = TaxFreeConfig(
            storeId: storeId,
            isEnabled: true,
            minPurchaseAmount: 10000,
            refundPercentage: 100,
            serviceFee: 0,
            eligibleCountries: ["United States", "United Kingdom", "Canada", "Singapore", "Japan", "France", "Germany"]
        )
        return defaultConf
    }
    
    // MARK: - Transactions
    
    @MainActor
    public func fetchTaxFreeTransactions() async throws {
        do {
            let fetched: [TaxFreeTransaction] = try await api.fetch("tax_free_transactions")
            self.taxFreeTransactions = fetched
        } catch {
            // print("[DataStore] ⚠️ Failed to fetch tax_free_transactions: \(error)")
        }
    }
    
    @MainActor
    public func createTaxFreeTransaction(_ txn: TaxFreeTransaction) async throws {
        do {
            let created: TaxFreeTransaction = try await api.insert("tax_free_transactions", record: txn)
            self.taxFreeTransactions.append(created)
        } catch {
            print("[DataStore] ⚠️ Failed to insert tax_free_transaction: \(error)")
            self.taxFreeTransactions.append(txn)
        }
    }
    
    @MainActor
    public func updateTaxFreeTransactionStatus(id: UUID, status: TaxFreeStatus, managerId: UUID) async throws {
        guard let idx = self.taxFreeTransactions.firstIndex(where: { $0.id == id }) else { return }
        var updated = self.taxFreeTransactions[idx]
        updated.status = status
        updated.updatedAt = Date()
        
        do {
            try await api.update("tax_free_transactions", id: id, record: updated)
        } catch {
            print("[DataStore] ⚠️ Failed to update tax_free_transaction status: \(error)")
        }
        self.taxFreeTransactions[idx] = updated
        
        // Log action in audit logs
        let audit = TaxFreeAudit(
            taxFreeTransactionId: id,
            userId: managerId,
            action: "Status updated to \(status.rawValue)"
        )
        try? await createTaxFreeAudit(audit)
    }
    
    // MARK: - Audits
    
    @MainActor
    public func fetchTaxFreeAudits() async throws {
        do {
            let fetched: [TaxFreeAudit] = try await api.fetch("tax_free_audits")
            self.taxFreeAudits = fetched
        } catch {
            print("[DataStore] ⚠️ Failed to fetch tax_free_audits: \(error)")
        }
    }
    
    @MainActor
    public func createTaxFreeAudit(_ audit: TaxFreeAudit) async throws {
        do {
            let created: TaxFreeAudit = try await api.insert("tax_free_audits", record: audit)
            self.taxFreeAudits.append(created)
        } catch {
            print("[DataStore] ⚠️ Failed to insert tax_free_audit: \(error)")
            self.taxFreeAudits.append(audit)
        }
    }
}
