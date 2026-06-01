//
//  DataStore.swift
//  RSMS
//
//  Centralised data repository powered by Supabase PostgREST.
//  Provides async CRUD for every table in the schema.
//  Injected into the SwiftUI environment at app level.
//

import SwiftUI

/// Single source of truth for all domain data.
///
/// Each table has a local cache (`var`) that is populated on fetch
/// and updated optimistically on mutations, keeping the UI reactive.
@Observable
final class DataStore {

    let api = SupabaseClient.shared

    // ══════════════════════════════════════════════════════════
    // MARK: - Local Caches
    // ══════════════════════════════════════════════════════════

    // ── Core ────────────────────────────────────────────
    var stores: [Store] = []
    var users: [UserProfile] = []

    // ── Boutique Manager ────────────────────────────────
    var dashboardSummaries: [DashboardSummary] = []
    var staffShifts: [StaffShift] = []
    var salesGoals: [SalesGoal] = []
    var commissions: [Commission] = []
    var performanceMetrics: [PerformanceMetric] = []
    var lookbooks: [Lookbook] = []
    var complianceChecks: [ComplianceCheck] = []
    var clientEvents: [ClientEvent] = []
    var eventInvitations: [EventInvitation] = []

    // ── Sales Associate / Clienteling ───────────────────
    var clients: [ClientProfile] = [] {
            didSet {
                recalculateVIPTiers()
            }
        }
    var clientAnniversaries: [ClientAnniversary] = []
    var wishlistItems: [WishlistItem] = []
    var appointments: [Appointment] = []
    var aiRecommendations: [AIRecommendation] = []
    var lookBuilderOutfits: [LookBuilderOutfit] = []

    // ── POS / Carts ────────────────────────────────────
    var universalCarts: [UniversalCart] = []
    var universalCartItems: [UniversalCartItem] = []
    
    // ── Approval Workflow ──────────────────────────────
    var discountApprovalRequests: [DiscountApprovalRequest] = []
    var appNotifications: [AppNotification] = []
    var discounts: [Discount] = []
    var transactions: [Transaction] = [] {
            didSet {
                recalculateVIPTiers()
            }
        }
    var orders: [Order] = []
    var tenders: [Tender] = []
    var giftReceipts: [GiftReceipt] = []
    var exchangeReturns: [ExchangeReturn] = []
    private var isRecalculating = false

        func recalculateVIPTiers() {
            guard !isRecalculating else { return }
            isRecalculating = true
            defer { isRecalculating = false }
            
            for index in clients.indices {
                let client = clients[index]
                let completedTxns = transactions.filter { $0.clientId == client.id && $0.status == .completed }
                let ltv = completedTxns.reduce(0.0) { $0 + $1.totalAmount }
                
                let calculatedTier: VIPTier
                if ltv >= 1000000 {
                    calculatedTier = .prive
                } else if ltv >= 500000 {
                    calculatedTier = .platinum
                } else if ltv >= 150000 {
                    calculatedTier = .gold
                } else if ltv >= 50000 {
                    calculatedTier = .silver
                } else {
                    calculatedTier = .standard
                }
                
                if clients[index].vipTier != calculatedTier {
                    clients[index].vipTier = calculatedTier
                }
            }
        }
    var exchangeReturnItems: [ExchangeReturnItem] = []

    // ── Inventory ──────────────────────────────────────
    var products: [Product] = []
    var stockItems: [StockItem] = []
    var rfidScanRecords: [RFIDScanRecord] = []
    var inventoryVariances: [InventoryVariance] = []
    var inventoryMovements: [InventoryMovement] = []
    var movementItems: [MovementItem] = []
    var cycleCounts: [CycleCount] = []
    var auditTrails: [AuditTrail] = []
    var serialCaptures: [SerialCapture] = []
    var authCertificates: [AuthCertificate] = []
    var shrinkageAnalytics: [ShrinkageAnalytics] = []

    // ── Omnichannel ────────────────────────────────────
    var omnichannelOrders: [OmnichannelOrder] = []
    var shipFromStoreSlips: [ShipFromStoreSlip] = []

    // ══════════════════════════════════════════════════════════
    // MARK: - Convenience Lookups
    // ══════════════════════════════════════════════════════════

    func store(by id: UUID) -> Store?          { stores.first { $0.id == id } }
    func user(by id: UUID) -> UserProfile?     { users.first { $0.id == id } }
    func product(by id: UUID) -> Product?      { products.first { $0.id == id } }
    func client(by id: UUID) -> ClientProfile? { clients.first { $0.id == id } }

    func storeName(for id: UUID) -> String     { store(by: id)?.name ?? "Unknown Store" }
    func userName(for id: UUID) -> String      { user(by: id)?.fullName ?? "Unknown" }
    func productName(for id: UUID) -> String   { product(by: id)?.name ?? "Unknown Product" }
    func clientName(for id: UUID) -> String    { client(by: id)?.fullName ?? "Unknown Client" }

    // ══════════════════════════════════════════════════════════
    // MARK: - stores
    // ══════════════════════════════════════════════════════════

    func fetchStores() async throws {
        let fetched: [Store] = try await api.fetch("stores")
        if fetched.isEmpty {
            var seeded: [Store] = []
            for store in Store.all {
                do {
                    let created: Store = try await api.insert("stores", record: store)
                    seeded.append(created)
                } catch {
                    print("[RSMS Debug] Error seeding store \(store.name): \(error.localizedDescription)")
                }
            }
            stores = seeded
        } else {
            stores = fetched
        }
    }

    func fetchStore(id: UUID) async throws -> Store {
        try await api.fetchById("stores", id: id)
    }

    @discardableResult
    func createStore(_ store: Store) async throws -> Store {
        let created: Store = try await api.insert("stores", record: store)
        stores.append(created)
        return created
    }

    func updateStore(_ store: Store) async throws {
        try await api.update("stores", id: store.id, record: store)
        if let i = stores.firstIndex(where: { $0.id == store.id }) { stores[i] = store }
    }

    func deleteStore(id: UUID) async throws {
        try await api.delete("stores", id: id)
        stores.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - user_profiles
    // ══════════════════════════════════════════════════════════

    func fetchUsers(storeId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let sid = storeId { query["store_id"] = "eq.\(sid)" }
        users = try await api.fetch("user_profiles", query: query)
    }

    func fetchUser(id: UUID) async throws -> UserProfile {
        try await api.fetchById("user_profiles", id: id)
    }

    @discardableResult
    func createUser(_ user: UserProfile) async throws -> UserProfile {
        let created: UserProfile = try await api.insert("user_profiles", record: user)
        users.append(created)
        return created
    }

    func updateUser(_ user: UserProfile) async throws {
        try await api.update("user_profiles", id: user.id, record: user)
        if let i = users.firstIndex(where: { $0.id == user.id }) { users[i] = user }
    }
    
    func updateEmployeeProfile(_ profile: UserProfile) async throws {
        // Explicitly update only the allowed (editable) fields of the user_profiles table.
        // This avoids write permissions or RLS violations on locked columns like role or store_id.
        let payload = UserProfileUpdatePayload(
            phone: profile.phone,
            avatarURL: profile.avatarURL,
            updatedAt: Date()
        )
        
        do {
            try await api.update("user_profiles", id: profile.id, record: payload)
        } catch {
            print("[DataStore] Profile update failed (possibly because row doesn't exist). Attempting to auto-insert: \(error.localizedDescription)")
            // Auto-create/insert the user profile in the database if it doesn't exist yet
            try await api.insert("user_profiles", record: profile)
        }
        
        // Ensure local consistency by checking if already fetched
        if let i = users.firstIndex(where: { $0.id == profile.id }) { 
            users[i] = profile 
        } else {
            users.append(profile)
        }
    }

    func deleteUser(id: UUID) async throws {
        try await api.delete("user_profiles", id: id)
        users.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - products
    // ══════════════════════════════════════════════════════════

    func fetchProducts() async throws {
        products = try await api.fetch("products")
    }

    func fetchProduct(id: UUID) async throws -> Product {
        try await api.fetchById("products", id: id)
    }

    @discardableResult
    func createProduct(_ product: Product) async throws -> Product {
        let created: Product = try await api.insert("products", record: product)
        products.append(created)
        return created
    }

    func updateProduct(_ product: Product) async throws {
        try await api.update("products", id: product.id, record: product)
        if let i = products.firstIndex(where: { $0.id == product.id }) { products[i] = product }
    }

    func deleteProduct(id: UUID) async throws {
        try await api.delete("products", id: id)
        products.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - dashboard_summaries
    // ══════════════════════════════════════════════════════════

    func fetchDashboardSummaries(storeId: UUID) async throws {
        dashboardSummaries = try await api.fetch("dashboard_summaries", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createDashboardSummary(_ summary: DashboardSummary) async throws -> DashboardSummary {
        let created: DashboardSummary = try await api.insert("dashboard_summaries", record: summary)
        dashboardSummaries.append(created)
        return created
    }

    func updateDashboardSummary(_ summary: DashboardSummary) async throws {
        try await api.update("dashboard_summaries", id: summary.id, record: summary)
        if let i = dashboardSummaries.firstIndex(where: { $0.id == summary.id }) { dashboardSummaries[i] = summary }
    }

    func deleteDashboardSummary(id: UUID) async throws {
        try await api.delete("dashboard_summaries", id: id)
        dashboardSummaries.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - staff_shifts
    // ══════════════════════════════════════════════════════════

    func fetchStaffShifts(storeId: UUID) async throws {
        staffShifts = try await api.fetch("staff_shifts", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createStaffShift(_ shift: StaffShift) async throws -> StaffShift {
        let created: StaffShift = try await api.insert("staff_shifts", record: shift)
        staffShifts.append(created)
        return created
    }

    func updateStaffShift(_ shift: StaffShift) async throws {
        try await api.update("staff_shifts", id: shift.id, record: shift)
        if let i = staffShifts.firstIndex(where: { $0.id == shift.id }) { staffShifts[i] = shift }
    }

    func deleteStaffShift(id: UUID) async throws {
        try await api.delete("staff_shifts", id: id)
        staffShifts.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - sales_goals
    // ══════════════════════════════════════════════════════════

    func fetchSalesGoals(storeId: UUID) async throws {
        salesGoals = try await api.fetch("sales_goals", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createSalesGoal(_ goal: SalesGoal) async throws -> SalesGoal {
        let created: SalesGoal = try await api.insert("sales_goals", record: goal)
        salesGoals.append(created)
        return created
    }

    func updateSalesGoal(_ goal: SalesGoal) async throws {
        try await api.update("sales_goals", id: goal.id, record: goal)
        if let i = salesGoals.firstIndex(where: { $0.id == goal.id }) { salesGoals[i] = goal }
    }

    func deleteSalesGoal(id: UUID) async throws {
        try await api.delete("sales_goals", id: id)
        salesGoals.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - commissions
    // ══════════════════════════════════════════════════════════

    func fetchCommissions(staffId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let sid = staffId { query["staff_id"] = "eq.\(sid)" }
        commissions = try await api.fetch("commissions", query: query)
    }

    @discardableResult
    func createCommission(_ c: Commission) async throws -> Commission {
        let created: Commission = try await api.insert("commissions", record: c)
        commissions.append(created)
        return created
    }

    func updateCommission(_ c: Commission) async throws {
        try await api.update("commissions", id: c.id, record: c)
        if let i = commissions.firstIndex(where: { $0.id == c.id }) { commissions[i] = c }
    }

    func deleteCommission(id: UUID) async throws {
        try await api.delete("commissions", id: id)
        commissions.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - performance_metrics
    // ══════════════════════════════════════════════════════════

    func fetchPerformanceMetrics(storeId: UUID) async throws {
        performanceMetrics = try await api.fetch("performance_metrics", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createPerformanceMetric(_ m: PerformanceMetric) async throws -> PerformanceMetric {
        let created: PerformanceMetric = try await api.insert("performance_metrics", record: m)
        performanceMetrics.append(created)
        return created
    }

    func updatePerformanceMetric(_ m: PerformanceMetric) async throws {
        try await api.update("performance_metrics", id: m.id, record: m)
        if let i = performanceMetrics.firstIndex(where: { $0.id == m.id }) { performanceMetrics[i] = m }
    }

    func deletePerformanceMetric(id: UUID) async throws {
        try await api.delete("performance_metrics", id: id)
        performanceMetrics.removeAll { $0.id == id }
    }



    // ══════════════════════════════════════════════════════════
    // MARK: - lookbooks
    // ══════════════════════════════════════════════════════════

    func fetchLookbooks() async throws {
        lookbooks = try await api.fetch("lookbooks")
    }

    @discardableResult
    func createLookbook(_ l: Lookbook) async throws -> Lookbook {
        let created: Lookbook = try await api.insert("lookbooks", record: l)
        lookbooks.append(created)
        return created
    }

    @discardableResult
    func updateLookbook(_ l: Lookbook) async throws -> Lookbook {
        let updated: Lookbook = try await api.update("lookbooks", id: l.id, record: l)
        if let i = lookbooks.firstIndex(where: { $0.id == updated.id }) { lookbooks[i] = updated }
        return updated
    }

    func deleteLookbook(id: UUID) async throws {
        try await api.delete("lookbooks", id: id)
        lookbooks.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - compliance_checks
    // ══════════════════════════════════════════════════════════

    func fetchComplianceChecks(storeId: UUID) async throws {
        complianceChecks = try await api.fetch("compliance_checks", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createComplianceCheck(_ c: ComplianceCheck) async throws -> ComplianceCheck {
        let created: ComplianceCheck = try await api.insert("compliance_checks", record: c)
        complianceChecks.append(created)
        return created
    }

    func updateComplianceCheck(_ c: ComplianceCheck) async throws {
        try await api.update("compliance_checks", id: c.id, record: c)
        if let i = complianceChecks.firstIndex(where: { $0.id == c.id }) { complianceChecks[i] = c }
    }

    func deleteComplianceCheck(id: UUID) async throws {
        try await api.delete("compliance_checks", id: id)
        complianceChecks.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - client_events
    // ══════════════════════════════════════════════════════════

    func fetchClientEvents(storeId: UUID) async throws {
        clientEvents = try await api.fetch("client_events", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createClientEvent(_ e: ClientEvent) async throws -> ClientEvent {
        let created: ClientEvent = try await api.insert("client_events", record: e)
        clientEvents.append(created)
        return created
    }

    func updateClientEvent(_ e: ClientEvent) async throws {
        try await api.update("client_events", id: e.id, record: e)
        if let i = clientEvents.firstIndex(where: { $0.id == e.id }) { clientEvents[i] = e }
    }

    func deleteClientEvent(id: UUID) async throws {
        try await api.delete("client_events", id: id)
        clientEvents.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - event_invitations
    // ══════════════════════════════════════════════════════════

    func fetchEventInvitations(eventId: UUID) async throws {
        eventInvitations = try await api.fetch("event_invitations", query: ["event_id": "eq.\(eventId)"])
    }

    @discardableResult
    func createEventInvitation(_ inv: EventInvitation) async throws -> EventInvitation {
        let created: EventInvitation = try await api.insert("event_invitations", record: inv)
        eventInvitations.append(created)
        return created
    }

    func updateEventInvitation(_ inv: EventInvitation) async throws {
        try await api.update("event_invitations", id: inv.id, record: inv)
        if let i = eventInvitations.firstIndex(where: { $0.id == inv.id }) { eventInvitations[i] = inv }
    }

    func deleteEventInvitation(id: UUID) async throws {
        try await api.delete("event_invitations", id: id)
        eventInvitations.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - client_profiles
    // ══════════════════════════════════════════════════════════

    func fetchClients() async throws {
        clients = try await api.fetch("client_profiles")
    }

    func fetchClient(id: UUID) async throws -> ClientProfile {
        try await api.fetchById("client_profiles", id: id)
    }

    @discardableResult
    func createClient(_ c: ClientProfile) async throws -> ClientProfile {
        let created: ClientProfile = try await api.insert("client_profiles", record: c)
        clients.append(created)
        return created
    }

    func updateClient(_ c: ClientProfile) async throws {
        try await api.update("client_profiles", id: c.id, record: c)
        if let i = clients.firstIndex(where: { $0.id == c.id }) { clients[i] = c }
    }

    func deleteClient(id: UUID) async throws {
        let cid = id.uuidString

        // ── STEP 1: Fetch ALL related records directly from the backend ──────────────
        // IMPORTANT: Do NOT filter from local in-memory arrays. Those arrays may be
        // empty if the user has never navigated to those screens in this session.
        // Querying the backend directly guarantees we find every FK-constrained row.

        let appts:         [Appointment]             = (try? await api.fetch("appointments",               query: ["client_id": "eq.\(cid)"])) ?? []
        let anns:          [ClientAnniversary]        = (try? await api.fetch("client_anniversaries",       query: ["client_id": "eq.\(cid)"])) ?? []
        let wishlists:     [WishlistItem]             = (try? await api.fetch("wishlist_items",             query: ["client_id": "eq.\(cid)"])) ?? []
        let aiRecs:        [AIRecommendation]         = (try? await api.fetch("ai_recommendations",         query: ["client_id": "eq.\(cid)"])) ?? []
        let invitations:   [EventInvitation]          = (try? await api.fetch("event_invitations",          query: ["client_id": "eq.\(cid)"])) ?? []
        let dars:          [DiscountApprovalRequest]  = (try? await api.fetch("discount_approval_requests", query: ["client_id": "eq.\(cid)"])) ?? []
        let outfits:       [LookBuilderOutfit]        = (try? await api.fetch("look_builder_outfits",       query: ["client_id": "eq.\(cid)"])) ?? []
        let regularOrders: [Order]                   = (try? await api.fetch("orders",                     query: ["client_id": "eq.\(cid)"])) ?? []

        // Transaction chain — fetch child records using PostgREST `in` filter
        let trans: [Transaction] = (try? await api.fetch("transactions", query: ["client_id": "eq.\(cid)"])) ?? []
        var tnds:       [Tender]             = []
        var greceipts:  [GiftReceipt]        = []
        var exreturns:  [ExchangeReturn]     = []
        var comms:      [Commission]         = []
        var exrItems:   [ExchangeReturnItem] = []
        if !trans.isEmpty {
            let tList = trans.map { $0.id.uuidString }.joined(separator: ",")
            tnds      = (try? await api.fetch("tenders",          query: ["transaction_id":          "in.(\(tList))"])) ?? []
            greceipts = (try? await api.fetch("gift_receipts",    query: ["transaction_id":          "in.(\(tList))"])) ?? []
            exreturns = (try? await api.fetch("exchange_returns", query: ["original_transaction_id": "in.(\(tList))"])) ?? []
            comms     = (try? await api.fetch("commissions",      query: ["transaction_id":          "in.(\(tList))"])) ?? []
            if !exreturns.isEmpty {
                let erList = exreturns.map { $0.id.uuidString }.joined(separator: ",")
                exrItems = (try? await api.fetch("exchange_return_items", query: ["exchange_return_id": "in.(\(erList))"])) ?? []
            }
        }

        // Cart chain
        let carts: [UniversalCart] = (try? await api.fetch("universal_carts", query: ["client_id": "eq.\(cid)"])) ?? []
        var cartItems: [UniversalCartItem] = []
        if !carts.isEmpty {
            let cList = carts.map { $0.id.uuidString }.joined(separator: ",")
            cartItems = (try? await api.fetch("universal_cart_items", query: ["cart_id": "in.(\(cList))"])) ?? []
        }

        // Omnichannel chain
        let omniOrders: [OmnichannelOrder] = (try? await api.fetch("omnichannel_orders", query: ["client_id": "eq.\(cid)"])) ?? []
        var slips: [ShipFromStoreSlip] = []
        if !omniOrders.isEmpty {
            let oList = omniOrders.map { $0.id.uuidString }.joined(separator: ",")
            slips = (try? await api.fetch("ship_from_store_slips", query: ["order_id": "in.(\(oList))"])) ?? []
        }

        // ── STEP 2: Delete from backend in strict reverse-dependency order ────────────
        for item in slips         { try? await api.delete("ship_from_store_slips",       id: item.id) }
        for item in omniOrders    { try? await api.delete("omnichannel_orders",          id: item.id) }
        for item in regularOrders { try? await api.delete("orders",                      id: item.id) }
        for item in exrItems      { try? await api.delete("exchange_return_items",       id: item.id) }
        for item in exreturns     { try? await api.delete("exchange_returns",            id: item.id) }
        for item in greceipts     { try? await api.delete("gift_receipts",               id: item.id) }
        for item in tnds          { try? await api.delete("tenders",                     id: item.id) }
        for item in comms         { try? await api.delete("commissions",                 id: item.id) }
        for item in trans         { try? await api.delete("transactions",                id: item.id) }
        for item in cartItems     { try? await api.delete("universal_cart_items",        id: item.id) }
        for item in dars          { try? await api.delete("discount_approval_requests",  id: item.id) }
        for item in carts         { try? await api.delete("universal_carts",             id: item.id) }
        for item in invitations   { try? await api.delete("event_invitations",           id: item.id) }
        for item in aiRecs        { try? await api.delete("ai_recommendations",          id: item.id) }
        for item in wishlists     { try? await api.delete("wishlist_items",              id: item.id) }
        for item in anns          { try? await api.delete("client_anniversaries",        id: item.id) }
        for item in appts         { try? await api.delete("appointments",                id: item.id) }
        for item in outfits       { try? await api.delete("look_builder_outfits",        id: item.id) }

        // ── STEP 3: Delete the client — throws if backend refuses ─────────────────────
        try await api.delete("client_profiles", id: id)

        // ── STEP 4: Update local cache only after confirmed backend deletion ──────────
        await MainActor.run {
            let tIds   = Set(trans.map      { $0.id })
            let cIds   = Set(carts.map      { $0.id })
            let erIds  = Set(exreturns.map  { $0.id })
            let omniIds = Set(omniOrders.map { $0.id })

            shipFromStoreSlips.removeAll       { omniIds.contains($0.orderId) }
            omnichannelOrders.removeAll        { $0.clientId == id }
            self.orders.removeAll              { $0.clientId == id }
            exchangeReturnItems.removeAll      { erIds.contains($0.exchangeReturnId) }
            exchangeReturns.removeAll          { tIds.contains($0.originalTransactionId) }
            giftReceipts.removeAll             { tIds.contains($0.transactionId) }
            tenders.removeAll                  { tIds.contains($0.transactionId) }
            commissions.removeAll              { tIds.contains($0.transactionId) }
            transactions.removeAll             { $0.clientId == id }
            universalCartItems.removeAll       { cIds.contains($0.cartId) }
            discountApprovalRequests.removeAll { $0.clientId == id }
            universalCarts.removeAll           { $0.clientId == id }
            eventInvitations.removeAll         { $0.clientId == id }
            aiRecommendations.removeAll        { $0.clientId == id }
            wishlistItems.removeAll            { $0.clientId == id }
            clientAnniversaries.removeAll      { $0.clientId == id }
            appointments.removeAll             { $0.clientId == id }
            lookBuilderOutfits.removeAll       { $0.clientId == id }
            clients.removeAll                  { $0.id == id }
        }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - client_anniversaries
    // ══════════════════════════════════════════════════════════

    func fetchClientAnniversaries(clientId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let cid = clientId { query["client_id"] = "eq.\(cid)" }
        clientAnniversaries = try await api.fetch("client_anniversaries", query: query)
    }

    @discardableResult
    func createClientAnniversary(_ a: ClientAnniversary) async throws -> ClientAnniversary {
        let created: ClientAnniversary = try await api.insert("client_anniversaries", record: a)
        clientAnniversaries.append(created)
        return created
    }

    func updateClientAnniversary(_ a: ClientAnniversary) async throws {
        try await api.update("client_anniversaries", id: a.id, record: a)
        if let i = clientAnniversaries.firstIndex(where: { $0.id == a.id }) { clientAnniversaries[i] = a }
    }

    func deleteClientAnniversary(id: UUID) async throws {
        try await api.delete("client_anniversaries", id: id)
        clientAnniversaries.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - wishlist_items
    // ══════════════════════════════════════════════════════════

    func fetchWishlistItems(clientId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let cid = clientId { query["client_id"] = "eq.\(cid)" }
        wishlistItems = try await api.fetch("wishlist_items", query: query)
    }

    @discardableResult
    func createWishlistItem(_ w: WishlistItem) async throws -> WishlistItem {
        // Optimistic UI update
        await MainActor.run {
            if !wishlistItems.contains(where: { $0.id == w.id }) {
                wishlistItems.append(w)
            }
        }
        
        do {
            let created: WishlistItem = try await api.insert("wishlist_items", record: w)
            return created
        } catch {
            // Revert on failure
            await MainActor.run {
                wishlistItems.removeAll { $0.id == w.id }
            }
            throw error
        }
    }

    func deleteWishlistItem(id: UUID) async throws {
        // Optimistic UI update
        var removedItem: WishlistItem?
        await MainActor.run {
            if let index = wishlistItems.firstIndex(where: { $0.id == id }) {
                removedItem = wishlistItems.remove(at: index)
            }
        }
        
        do {
            try await api.delete("wishlist_items", id: id)
        } catch {
            // Revert on failure
            if let item = removedItem {
                await MainActor.run {
                    if !wishlistItems.contains(where: { $0.id == id }) {
                        wishlistItems.append(item)
                    }
                }
            }
            throw error
        }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - appointments
    // ══════════════════════════════════════════════════════════

    func fetchAppointments(storeId: UUID? = nil, associateId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let sid = storeId { query["store_id"] = "eq.\(sid)" }
        if let aid = associateId { query["associate_id"] = "eq.\(aid)" }
        appointments = try await api.fetch("appointments", query: query)
    }

    @discardableResult
    func createAppointment(_ a: Appointment) async throws -> Appointment {
        let created: Appointment = try await api.insert("appointments", record: a)
        appointments.append(created)
        return created
    }

    func updateAppointment(_ a: Appointment) async throws {
        try await api.update("appointments", id: a.id, record: a)
        if let i = appointments.firstIndex(where: { $0.id == a.id }) { appointments[i] = a }
    }

    func deleteAppointment(id: UUID) async throws {
        try await api.delete("appointments", id: id)
        appointments.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - ai_recommendations
    // ══════════════════════════════════════════════════════════

    func fetchAIRecommendations(clientId: UUID) async throws {
        aiRecommendations = try await api.fetch("ai_recommendations", query: ["client_id": "eq.\(clientId)"])
    }

    @discardableResult
    func createAIRecommendation(_ r: AIRecommendation) async throws -> AIRecommendation {
        let created: AIRecommendation = try await api.insert("ai_recommendations", record: r)
        aiRecommendations.append(created)
        return created
    }

    func updateAIRecommendation(_ r: AIRecommendation) async throws {
        try await api.update("ai_recommendations", id: r.id, record: r)
        if let i = aiRecommendations.firstIndex(where: { $0.id == r.id }) { aiRecommendations[i] = r }
    }

    func deleteAIRecommendation(id: UUID) async throws {
        try await api.delete("ai_recommendations", id: id)
        aiRecommendations.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - look_builder_outfits
    // ══════════════════════════════════════════════════════════

    func fetchLookBuilderOutfits(associateId: UUID) async throws {
        lookBuilderOutfits = try await api.fetch("look_builder_outfits", query: ["associate_id": "eq.\(associateId)"])
    }

    @discardableResult
    func createLookBuilderOutfit(_ o: LookBuilderOutfit) async throws -> LookBuilderOutfit {
        let created: LookBuilderOutfit = try await api.insert("look_builder_outfits", record: o)
        lookBuilderOutfits.append(created)
        return created
    }

    func updateLookBuilderOutfit(_ o: LookBuilderOutfit) async throws {
        try await api.update("look_builder_outfits", id: o.id, record: o)
        if let i = lookBuilderOutfits.firstIndex(where: { $0.id == o.id }) { lookBuilderOutfits[i] = o }
    }

    func deleteLookBuilderOutfit(id: UUID) async throws {
        try await api.delete("look_builder_outfits", id: id)
        lookBuilderOutfits.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - universal_carts
    // ══════════════════════════════════════════════════════════

    func fetchUniversalCarts(associateId: UUID? = nil, type: CartType? = nil) async throws {
        var query: [String: String] = [:]
        if let aid = associateId { query["associate_id"] = "eq.\(aid)" }
        if let t = type { query["type"] = "eq.\(t.rawValue)" }
        universalCarts = try await api.fetch("universal_carts", query: query)
    }

    @discardableResult
    func createUniversalCart(_ c: UniversalCart) async throws -> UniversalCart {
        let created: UniversalCart = try await api.insert("universal_carts", record: c)
        universalCarts.append(created)
        return created
    }

    func updateUniversalCart(_ c: UniversalCart) async throws {
        try await api.update("universal_carts", id: c.id, record: c)
        if let i = universalCarts.firstIndex(where: { $0.id == c.id }) { universalCarts[i] = c }
    }

    func deleteUniversalCart(id: UUID) async throws {
        try await api.delete("universal_carts", id: id)
        await MainActor.run {
            universalCarts.removeAll { $0.id == id }
        }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - universal_cart_items
    // ══════════════════════════════════════════════════════════

    func fetchUniversalCartItems(cartId: UUID) async throws {
        universalCartItems = try await api.fetch("universal_cart_items", query: ["cart_id": "eq.\(cartId)"])
    }

    @discardableResult
    func createUniversalCartItem(_ item: UniversalCartItem) async throws -> UniversalCartItem {
        let created: UniversalCartItem = try await api.insert("universal_cart_items", record: item)
        universalCartItems.append(created)
        return created
    }

    func updateUniversalCartItem(_ item: UniversalCartItem) async throws {
        try await api.update("universal_cart_items", id: item.id, record: item)
        if let i = universalCartItems.firstIndex(where: { $0.id == item.id }) { universalCartItems[i] = item }
    }

    func deleteUniversalCartItem(id: UUID) async throws {
        try await api.delete("universal_cart_items", id: id)
        await MainActor.run {
            universalCartItems.removeAll { $0.id == id }
        }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - discounts
    // ══════════════════════════════════════════════════════════

    func fetchDiscounts() async throws {
        discounts = try await api.fetch("discounts")
    }

    @discardableResult
    func createDiscount(_ d: Discount) async throws -> Discount {
        let created: Discount = try await api.insert("discounts", record: d)
        discounts.append(created)
        return created
    }

    func updateDiscount(_ d: Discount) async throws {
        try await api.update("discounts", id: d.id, record: d)
        if let i = discounts.firstIndex(where: { $0.id == d.id }) { discounts[i] = d }
    }

    func deleteDiscount(id: UUID) async throws {
        try await api.delete("discounts", id: id)
        discounts.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - transactions
    // ══════════════════════════════════════════════════════════

    func fetchTransactions(storeId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let sid = storeId { query["store_id"] = "eq.\(sid)" }
        transactions = try await api.fetch("transactions", query: query)
    }

    @discardableResult
    func createTransaction(_ t: Transaction) async throws -> Transaction {
        let created: Transaction = try await api.insert("transactions", record: t)
        transactions.append(created)
        return created
    }

    func updateTransaction(_ t: Transaction) async throws {
        try await api.update("transactions", id: t.id, record: t)
        if let i = transactions.firstIndex(where: { $0.id == t.id }) { transactions[i] = t }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - orders
    // ══════════════════════════════════════════════════════════

    func fetchOrders(storeId: UUID) async throws {
        // NOTE: If orders need fetching by store, they may need to join with transactions.
        // Assuming we fetch by client or all for now.
    }

    @discardableResult
    func createOrder(_ o: Order) async throws -> Order {
        let created: Order = try await api.insert("orders", record: o)
        orders.append(created)
        return created
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - tenders
    // ══════════════════════════════════════════════════════════

    func fetchTenders(transactionId: UUID) async throws {
        tenders = try await api.fetch("tenders", query: ["transaction_id": "eq.\(transactionId)"])
    }

    @discardableResult
    func createTender(_ t: Tender) async throws -> Tender {
        let created: Tender = try await api.insert("tenders", record: t)
        tenders.append(created)
        return created
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - gift_receipts
    // ══════════════════════════════════════════════════════════

    func fetchGiftReceipts(transactionId: UUID) async throws {
        giftReceipts = try await api.fetch("gift_receipts", query: ["transaction_id": "eq.\(transactionId)"])
    }

    @discardableResult
    func createGiftReceipt(_ g: GiftReceipt) async throws -> GiftReceipt {
        let created: GiftReceipt = try await api.insert("gift_receipts", record: g)
        giftReceipts.append(created)
        return created
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - exchange_returns
    // ══════════════════════════════════════════════════════════

    func fetchExchangeReturns(storeId: UUID) async throws {
        exchangeReturns = try await api.fetch("exchange_returns", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createExchangeReturn(_ er: ExchangeReturn) async throws -> ExchangeReturn {
        let created: ExchangeReturn = try await api.insert("exchange_returns", record: er)
        exchangeReturns.append(created)
        return created
    }

    func updateExchangeReturn(_ er: ExchangeReturn) async throws {
        try await api.update("exchange_returns", id: er.id, record: er)
        if let i = exchangeReturns.firstIndex(where: { $0.id == er.id }) { exchangeReturns[i] = er }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - exchange_return_items
    // ══════════════════════════════════════════════════════════

    func fetchExchangeReturnItems(exchangeReturnId: UUID) async throws {
        exchangeReturnItems = try await api.fetch("exchange_return_items", query: ["exchange_return_id": "eq.\(exchangeReturnId)"])
    }

    @discardableResult
    func createExchangeReturnItem(_ item: ExchangeReturnItem) async throws -> ExchangeReturnItem {
        let created: ExchangeReturnItem = try await api.insert("exchange_return_items", record: item)
        exchangeReturnItems.append(created)
        return created
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - stock_items
    // ══════════════════════════════════════════════════════════

    func fetchStockItems(storeId: UUID? = nil) async throws {
        if let id = storeId {
            stockItems = try await api.fetch("stock_items", query: ["store_id": "eq.\(id)"])
        } else {
            stockItems = try await api.fetch("stock_items")
        }
    }

    @discardableResult
    func createStockItem(_ s: StockItem) async throws -> StockItem {
        let created: StockItem = try await api.insert("stock_items", record: s)
        stockItems.append(created)
        return created
    }

    @discardableResult
    func receiveStock(
        productId: UUID,
        storeId: UUID,
        quantity: Int,
        location: String,
        rfidTag: String? = nil
    ) async throws -> StockItem {
        let normalizedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedLocation = normalizedLocation.isEmpty ? nil : normalizedLocation

        if let existing = stockItems.first(where: { $0.productId == productId && $0.storeId == storeId }) {
            let updated = StockItem(
                id: existing.id,
                productId: existing.productId,
                storeId: existing.storeId,
                quantity: existing.quantity + max(quantity, 1),
                rfidTag: existing.rfidTag ?? rfidTag,
                location: resolvedLocation ?? existing.location,
                status: .available,
                lastScannedAt: .now,
                updatedAt: .now
            )
            try await updateStockItem(updated)
            return updated
        }

        let created = StockItem(
            id: UUID(),
            productId: productId,
            storeId: storeId,
            quantity: max(quantity, 1),
            rfidTag: rfidTag,
            location: resolvedLocation,
            status: .available,
            lastScannedAt: .now,
            updatedAt: .now
        )
        return try await createStockItem(created)
    }

    func updateStockItem(_ s: StockItem) async throws {
        try await api.update("stock_items", id: s.id, record: s)
        if let i = stockItems.firstIndex(where: { $0.id == s.id }) { stockItems[i] = s }
    }

    func deleteStockItem(id: UUID) async throws {
        try await api.delete("stock_items", id: id)
        stockItems.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - rfid_scan_records
    // ══════════════════════════════════════════════════════════

    func fetchRFIDScanRecords(storeId: UUID) async throws {
        rfidScanRecords = try await api.fetch("rfid_scan_records", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createRFIDScanRecord(_ r: RFIDScanRecord) async throws -> RFIDScanRecord {
        let created: RFIDScanRecord = try await api.insert("rfid_scan_records", record: r)
        rfidScanRecords.append(created)
        return created
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - inventory_variances
    // ══════════════════════════════════════════════════════════

    func fetchInventoryVariances(storeId: UUID) async throws {
        inventoryVariances = try await api.fetch("inventory_variances", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createInventoryVariance(_ v: InventoryVariance) async throws -> InventoryVariance {
        let created: InventoryVariance = try await api.insert("inventory_variances", record: v)
        inventoryVariances.append(created)
        return created
    }

    func updateInventoryVariance(_ v: InventoryVariance) async throws {
        try await api.update("inventory_variances", id: v.id, record: v)
        if let i = inventoryVariances.firstIndex(where: { $0.id == v.id }) { inventoryVariances[i] = v }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - inventory_movements
    // ══════════════════════════════════════════════════════════

    func fetchInventoryMovements(type: MovementType? = nil) async throws {
        var query: [String: String] = [:]
        if let t = type { query["type"] = "eq.\(t.rawValue)" }
        inventoryMovements = try await api.fetch("inventory_movements", query: query)
    }

    @discardableResult
    func createInventoryMovement(_ m: InventoryMovement) async throws -> InventoryMovement {
        let created: InventoryMovement = try await api.insert("inventory_movements", record: m)
        inventoryMovements.append(created)
        return created
    }

    func updateInventoryMovement(_ m: InventoryMovement) async throws {
        try await api.update("inventory_movements", id: m.id, record: m)
        if let i = inventoryMovements.firstIndex(where: { $0.id == m.id }) { inventoryMovements[i] = m }
    }

    func deleteInventoryMovement(id: UUID) async throws {
        try await api.delete("inventory_movements", id: id)
        inventoryMovements.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - movement_items
    // ══════════════════════════════════════════════════════════

    func fetchMovementItems(movementId: UUID) async throws {
        let fetched: [MovementItem] = try await api.fetch("movement_items", query: ["movement_id": "eq.\(movementId)"])
        // Merge fetched items into cache (don't wipe items for other movements)
        let fetchedIds = Set(fetched.map { $0.id })
        movementItems.removeAll { $0.movementId == movementId && !fetchedIds.contains($0.id) }
        for item in fetched {
            if let i = movementItems.firstIndex(where: { $0.id == item.id }) {
                movementItems[i] = item
            } else {
                movementItems.append(item)
            }
        }
    }

    @discardableResult
    func createMovementItem(_ item: MovementItem) async throws -> MovementItem {
        let created: MovementItem = try await api.insert("movement_items", record: item)
        movementItems.append(created)
        return created
    }

    func deleteMovementItem(id: UUID) async throws {
        try await api.delete("movement_items", id: id)
        movementItems.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - cycle_counts
    // ══════════════════════════════════════════════════════════

    func fetchCycleCounts(storeId: UUID) async throws {
        cycleCounts = try await api.fetch("cycle_counts", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createCycleCount(_ c: CycleCount) async throws -> CycleCount {
        let created: CycleCount = try await api.insert("cycle_counts", record: c)
        cycleCounts.append(created)
        return created
    }

    func updateCycleCount(_ c: CycleCount) async throws {
        try await api.update("cycle_counts", id: c.id, record: c)
        if let i = cycleCounts.firstIndex(where: { $0.id == c.id }) { cycleCounts[i] = c }
    }

    func deleteCycleCount(id: UUID) async throws {
        try await api.delete("cycle_counts", id: id)
        cycleCounts.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - audit_trails
    // ══════════════════════════════════════════════════════════

    func fetchAuditTrails(storeId: UUID) async throws {
        auditTrails = try await api.fetch("audit_trails", query: ["store_id": "eq.\(storeId)"])
    }

    @discardableResult
    func createAuditTrail(_ a: AuditTrail) async throws -> AuditTrail {
        let created: AuditTrail = try await api.insert("audit_trails", record: a)
        auditTrails.append(created)
        return created
    }

    /// Fire-and-forget audit logging (pushes to Supabase in background).
    func logAudit(storeId: UUID, action: String, entityType: String, entityId: UUID, performedBy: UUID, details: String? = nil) {
        let entry = AuditTrail(id: UUID(), storeId: storeId, action: action, entityType: entityType, entityId: entityId, performedBy: performedBy, timestamp: .now, details: details)
        auditTrails.append(entry)
        Task { try? await api.insert("audit_trails", record: entry) as AuditTrail }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - serial_captures
    // ══════════════════════════════════════════════════════════

    func fetchSerialCaptures(productId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let pid = productId { query["product_id"] = "eq.\(pid)" }
        serialCaptures = try await api.fetch("serial_captures", query: query)
    }

    @discardableResult
    func createSerialCapture(_ s: SerialCapture) async throws -> SerialCapture {
        let created: SerialCapture = try await api.insert("serial_captures", record: s)
        serialCaptures.append(created)
        return created
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - auth_certificates
    // ══════════════════════════════════════════════════════════

    func fetchAuthCertificates(productId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let pid = productId { query["product_id"] = "eq.\(pid)" }
        authCertificates = try await api.fetch("auth_certificates", query: query)
    }

    @discardableResult
    func createAuthCertificate(_ c: AuthCertificate) async throws -> AuthCertificate {
        let created: AuthCertificate = try await api.insert("auth_certificates", record: c)
        authCertificates.append(created)
        return created
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - shrinkage_analytics
    // ══════════════════════════════════════════════════════════

    func fetchShrinkageAnalytics(storeId: UUID) async throws {
        shrinkageAnalytics = try await api.fetch("shrinkage_analytics", query: ["store_id": "eq.\(storeId)"])
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - omnichannel_orders
    // ══════════════════════════════════════════════════════════

    func fetchOmnichannelOrders(storeId: UUID? = nil, type: OmnichannelOrderType? = nil) async throws {
        var query: [String: String] = [:]
        if let sid = storeId { query["store_id"] = "eq.\(sid)" }
        if let t = type { query["type"] = "eq.\(t.rawValue)" }
        omnichannelOrders = try await api.fetch("omnichannel_orders", query: query)
    }

    @discardableResult
    func createOmnichannelOrder(_ o: OmnichannelOrder) async throws -> OmnichannelOrder {
        let created: OmnichannelOrder = try await api.insert("omnichannel_orders", record: o)
        omnichannelOrders.append(created)
        return created
    }

    func updateOmnichannelOrder(_ o: OmnichannelOrder) async throws {
        try await api.update("omnichannel_orders", id: o.id, record: o)
        if let i = omnichannelOrders.firstIndex(where: { $0.id == o.id }) { omnichannelOrders[i] = o }
    }

    func deleteOmnichannelOrder(id: UUID) async throws {
        try await api.delete("omnichannel_orders", id: id)
        omnichannelOrders.removeAll { $0.id == id }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - ship_from_store_slips
    // ══════════════════════════════════════════════════════════

    func fetchShipFromStoreSlips(storeId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let sid = storeId { query["store_id"] = "eq.\(sid)" }
        shipFromStoreSlips = try await api.fetch("ship_from_store_slips", query: query)
    }

    @discardableResult
    func createShipFromStoreSlip(_ s: ShipFromStoreSlip) async throws -> ShipFromStoreSlip {
        let created: ShipFromStoreSlip = try await api.insert("ship_from_store_slips", record: s)
        shipFromStoreSlips.append(created)
        return created
    }

    func updateShipFromStoreSlip(_ s: ShipFromStoreSlip) async throws {
        try await api.update("ship_from_store_slips", id: s.id, record: s)
        if let i = shipFromStoreSlips.firstIndex(where: { $0.id == s.id }) { shipFromStoreSlips[i] = s }
    }

    @MainActor
    func clearAllCaches() {
        stores = []
        users = []
        dashboardSummaries = []
        staffShifts = []
        salesGoals = []
        commissions = []
        performanceMetrics = []
        //planograms = []
        lookbooks = []
        complianceChecks = []
        clientEvents = []
        eventInvitations = []
        clients = []
        clientAnniversaries = []
        wishlistItems = []
        appointments = []
        aiRecommendations = []
        lookBuilderOutfits = []
        universalCarts = []
        universalCartItems = []
        discounts = []
        transactions = []
        tenders = []
        giftReceipts = []
        exchangeReturns = []
        exchangeReturnItems = []
        products = []
        stockItems = []
        rfidScanRecords = []
        inventoryVariances = []
        inventoryMovements = []
        movementItems = []
        cycleCounts = []
        auditTrails = []
        serialCaptures = []
        authCertificates = []
        shrinkageAnalytics = []
        omnichannelOrders = []
        shipFromStoreSlips = []
        discountApprovalRequests = []
        appNotifications = []
        orders = []
    }
}
