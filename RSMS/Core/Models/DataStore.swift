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
    var inventorySourcingRequests: [InventorySourcingRequest] = []
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
    
    // ── Tax-Free Shopping ─────────────────────────────
    var taxFreeConfigs: [TaxFreeConfig] = []
    var taxFreeTransactions: [TaxFreeTransaction] = []
    var taxFreeAudits: [TaxFreeAudit] = []
    
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
    var serviceRequests: [ServiceRequest] = []
    var serviceActivities: [ServiceActivity] = []
    var loanerAssignments: [LoanerAssignment] = []
    var loanerActivities: [LoanerActivity] = []
    
    // ── Omnichannel ────────────────────────────────────
    var omnichannelOrders: [OmnichannelOrder] = []
    var shipFromStoreSlips: [ShipFromStoreSlip] = []
    var checkoutSessions: [CheckoutSession] = []
    var checkoutShippingAddresses: [CheckoutShippingAddress] = []
    var inventoryReservations: [InventoryReservation] = []
    
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

    func fetchEventInvitations(eventIds: [UUID]) async throws {
        guard !eventIds.isEmpty else {
            eventInvitations = []
            return
        }
        let ids = eventIds.map { $0.uuidString.lowercased() }.joined(separator: ",")
        eventInvitations = try await api.fetch("event_invitations", query: ["event_id": "in.(\(ids))"])
    }
    @discardableResult
    func createEventInvitation(_ inv: EventInvitation) async throws -> EventInvitation {
        let created: EventInvitation = try await api.insert("event_invitations", record: inv)
        eventInvitations.append(created)
        return created
    }

    @discardableResult
    func createEventInvitations(_ invitations: [EventInvitation]) async throws -> [EventInvitation] {
        let created: [EventInvitation] = try await api.insertMany("event_invitations", records: invitations)
        eventInvitations.removeAll { existing in
            created.contains { $0.id == existing.id }
        }
        eventInvitations.append(contentsOf: created)
        return created
    }

    func sendInviteEmails(invitationIds: [UUID]) async throws {
        struct SendInvitePayload: Encodable {
            let invitation_ids: [String]
        }
        let payload = SendInvitePayload(invitation_ids: invitationIds.map { $0.uuidString })
        try await api.invokeFunction("send_invite_email", body: payload)
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
        // 1. Gather all related items
        let appts = appointments.filter { $0.clientId == id }
        let anns = clientAnniversaries.filter { $0.clientId == id }
        let wishlists = wishlistItems.filter { $0.clientId == id }
        let ais = aiRecommendations.filter { $0.clientId == id }
        let invitations = eventInvitations.filter { $0.clientId == id }
        let carts = universalCarts.filter { $0.clientId == id }
        let trans = transactions.filter { $0.clientId == id }
        let orders = omnichannelOrders.filter { $0.clientId == id }
        let outfits = lookBuilderOutfits.filter { $0.clientId == id }
        
        // 2. Remove locally for instant UI update
        clients.removeAll { $0.id == id }
        appointments.removeAll { $0.clientId == id }
        clientAnniversaries.removeAll { $0.clientId == id }
        wishlistItems.removeAll { $0.clientId == id }
        aiRecommendations.removeAll { $0.clientId == id }
        eventInvitations.removeAll { $0.clientId == id }
        universalCarts.removeAll { $0.clientId == id }
        transactions.removeAll { $0.clientId == id }
        omnichannelOrders.removeAll { $0.clientId == id }
        lookBuilderOutfits.removeAll { $0.clientId == id }
        
        // 3. Delete from backend to prevent foreign key constraints from blocking the client delete
        for a in appts { try? await api.delete("appointments", id: a.id) }
        for a in anns { try? await api.delete("client_anniversaries", id: a.id) }
        for w in wishlists { try? await api.delete("wishlist_items", id: w.id) }
        for a in ais { try? await api.delete("ai_recommendations", id: a.id) }
        for i in invitations { try? await api.delete("event_invitations", id: i.id) }
        for c in carts { try? await api.delete("universal_carts", id: c.id) }
        for t in trans { try? await api.delete("transactions", id: t.id) }
        for o in orders { try? await api.delete("omnichannel_orders", id: o.id) }
        for o in outfits { try? await api.delete("look_builder_outfits", id: o.id) }
        
        // 4. Finally delete the client itself
        try? await api.delete("client_profiles", id: id)
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
        let fetched: [UniversalCartItem] = try await api.fetch("universal_cart_items", query: ["cart_id": "eq.\(cartId)"])
        await MainActor.run {
            self.universalCartItems.removeAll { $0.cartId == cartId }
            self.universalCartItems.append(contentsOf: fetched)
        }
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
    
    func fetchOrders(storeId: UUID? = nil) async throws {
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
        let fetched: [Tender] = try await api.fetch("tenders", query: ["transaction_id": "eq.\(transactionId)"])
        await MainActor.run {
            self.tenders.removeAll { $0.transactionId == transactionId }
            self.tenders.append(contentsOf: fetched)
        }
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
        let fetched: [GiftReceipt] = try await api.fetch("gift_receipts", query: ["transaction_id": "eq.\(transactionId)"])
        await MainActor.run {
            self.giftReceipts.removeAll { $0.transactionId == transactionId }
            self.giftReceipts.append(contentsOf: fetched)
        }
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
        do {
            if let id = storeId {
                stockItems = try await api.fetch("stock_items", query: ["store_id": "eq.\(id)"])
            } else {
                stockItems = try await api.fetch("stock_items")
            }
        } catch {
            print("FAILED TO FETCH STOCK ITEMS: \(error)")
            throw error
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

    /// Reserves stock for an outbound transfer, preventing double selling.
    func reserveStockForTransfer(productId: UUID, storeId: UUID, quantity: Int) async throws {
        // Fetch fresh to ensure we have the latest quantities
        let query = ["product_id": "eq.\(productId)", "store_id": "eq.\(storeId)"]
        let currentStock: [StockItem] = try await api.fetch("stock_items", query: query)
        
        guard let existing = currentStock.first(where: { $0.status == .available }), existing.quantity >= quantity else {
            throw NSError(domain: "DataStore", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Insufficient available stock to reserve for transfer."
            ])
        }
        
        // Deduct the requested quantity from available stock
        let updatedAvailable = StockItem(
            id: existing.id,
            productId: existing.productId,
            storeId: existing.storeId,
            quantity: existing.quantity - quantity, // Remove reserved quantity
            rfidTag: existing.rfidTag,
            location: existing.location,
            status: .available,
            lastScannedAt: existing.lastScannedAt,
            updatedAt: .now
        )
        try await updateStockItem(updatedAvailable)
        
        // Check if an inTransit record already exists for this product at this store
        if let existingInTransit = currentStock.first(where: { $0.status == .inTransit }) {
            let updatedInTransit = StockItem(
                id: existingInTransit.id,
                productId: existingInTransit.productId,
                storeId: existingInTransit.storeId,
                quantity: existingInTransit.quantity + quantity,
                rfidTag: existingInTransit.rfidTag,
                location: existingInTransit.location,
                status: .inTransit,
                lastScannedAt: existingInTransit.lastScannedAt,
                updatedAt: .now
            )
            try await updateStockItem(updatedInTransit)
        } else {
            // Create a new inTransit stock item for the reserved quantity
            let inTransitItem = StockItem(
                id: UUID(),
                productId: existing.productId,
                storeId: existing.storeId, // Stays at source store until received
                quantity: quantity,
                rfidTag: nil, // RFID transfers with the physical item
                location: "Transfer staging",
                status: .inTransit,
                lastScannedAt: .now,
                updatedAt: .now
            )
            try await createStockItem(inTransitItem)
        }
    }

    /// Permanently deducts stock (e.g. for a vendor return or adjustment)
    func deductStock(productId: UUID, storeId: UUID, quantity: Int) async throws {
        let query = ["product_id": "eq.\(productId)", "store_id": "eq.\(storeId)"]
        let currentStock: [StockItem] = try await api.fetch("stock_items", query: query)
        
        guard let existing = currentStock.first(where: { $0.status == .available }), existing.quantity >= quantity else {
            throw NSError(domain: "DataStore", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Insufficient available stock to deduct."
            ])
        }
        
        let updated = StockItem(
            id: existing.id,
            productId: existing.productId,
            storeId: existing.storeId,
            quantity: existing.quantity - quantity,
            rfidTag: existing.rfidTag,
            location: existing.location,
            status: existing.status,
            lastScannedAt: existing.lastScannedAt,
            updatedAt: .now
        )
        try await updateStockItem(updated)
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
    
    // ══════════════════════════════════════════════════════════
    // MARK: - BOPIS / Checkout Sessions
    // ══════════════════════════════════════════════════════════
    
    /// Reads the checkout server base URL from UserDefaults (set via gear icon in ShowroomCartView)
    private var checkoutServerBaseURL: String {
        UserDefaults.standard.string(forKey: "custom_checkout_base_url") ?? "http://localhost:3000"
    }
    
    func cartTotal(for cartId: UUID) -> Double {
        let items = universalCartItems.filter { $0.cartId == cartId }
        if !items.isEmpty {
            let subtotal = items.reduce(0.0) { total, item in
                let price = item.unitPrice ?? product(by: item.productId)?.price ?? 0.0
                return total + (price * Double(item.quantity))
            }
            return subtotal * 1.20 // Subtotal + 20% Tax
        }
        
        // Fallback to inventory reservations if cart was cleared
        if let session = checkoutSessions.first(where: { $0.cartId == cartId }) {
            let reservations = inventoryReservations.filter { $0.checkoutSessionId == session.id }
            let subtotal = reservations.reduce(0.0) { total, res in
                let price = product(by: res.productId)?.price ?? 0.0
                return total + (price * Double(res.quantity))
            }
            return subtotal * 1.20
        }
        return 0.0
    }
    
    func fetchCheckoutSessions() async throws {
#if DEBUG
        if let url = URL(string: "\(checkoutServerBaseURL)/api/checkout/sessions") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoder = JSONDecoder()
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let isoFormatterNoFractional = ISO8601DateFormatter()
                isoFormatterNoFractional.formatOptions = [.withInternetDateTime]
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateStr = try container.decode(String.self)
                    if let date = formatter.date(from: dateStr) { return date }
                    if let date = isoFormatterNoFractional.date(from: dateStr) { return date }
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
                }
                let localSessions = try decoder.decode([CheckoutSession].self, from: data)
                for s in localSessions {
                    if let idx = checkoutSessions.firstIndex(where: { $0.id == s.id }) {
                        if checkoutSessions[idx] != s { checkoutSessions[idx] = s }
                    } else {
                        checkoutSessions.append(s)
                    }
                }
            } catch {
                print("[DataStore] ⚠️ Failed to fetch local sessions from Python server: \(error.localizedDescription)")
            }
        }
#endif
        
        do {
            let fetched: [CheckoutSession] = try await api.fetch("checkout_sessions")
            // Smart merge — never delete, never downgrade status.
            // Sessions only in Python server memory (paid via web) stay visible.
            // Supabase returning an old status must not overwrite an advanced status
            // already set by the Python server.
            let advancedStatuses: [CheckoutStatus] = [
                .pendingStorePayment, .paid, .readyForPickup, .readyForShipping, .completed
            ]
            let fetchedById = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
            let currentIds  = Set(checkoutSessions.map { $0.id })
            
            var didAdvance = false
            let previousStatuses = Dictionary(uniqueKeysWithValues: checkoutSessions.map { ($0.id, $0.status) })
            
            // 1. Update existing sessions — skip if Supabase would downgrade status
            for idx in checkoutSessions.indices {
                guard let updated = fetchedById[checkoutSessions[idx].id] else { continue }
                let currentIsAdvanced = advancedStatuses.contains(checkoutSessions[idx].status)
                let newIsAdvanced     = advancedStatuses.contains(updated.status)
                if checkoutSessions[idx] != updated && (newIsAdvanced || !currentIsAdvanced) {
                    checkoutSessions[idx] = updated
                    if newIsAdvanced && !currentIsAdvanced {
                        didAdvance = true
                    }
                }
            }
            // 2. Append brand-new sessions from Supabase
            for session in fetched where !currentIds.contains(session.id) {
                checkoutSessions.append(session)
                if advancedStatuses.contains(session.status) {
                    didAdvance = true
                }
            }
            // NOTE: we intentionally never remove sessions — sessions only in
            // Python server memory must remain visible after payment.
            
            // Check if any session we already processed has advanced
            for s in checkoutSessions {
                if advancedStatuses.contains(s.status), let prev = previousStatuses[s.id], !advancedStatuses.contains(prev) {
                    didAdvance = true
                }
            }
            
            // 3. Auto-reconciliation: create missing Transaction/Tender for completed/paid online sessions
            try? await fetchInventoryReservations()
            if products.isEmpty {
                try? await fetchProducts()
            }
            if users.isEmpty {
                try? await fetchUsers()
            }
            if stores.isEmpty {
                try? await fetchStores()
            }
            let terminalStatuses: Set<CheckoutStatus> = [.readyForPickup, .readyForShipping, .completed]
            var didReconcile = false
            for s in checkoutSessions {
                if (s.status == .paid || terminalStatuses.contains(s.status)) && s.paymentMethod == .online {
                    if !transactions.contains(where: { $0.cartId == s.cartId }) {
                        let amt = cartTotal(for: s.cartId)
                        if amt > 0 {
                            let txId = UUID()
                            guard let storeId = universalCarts.first(where: { $0.id == s.cartId })?.storeId
                                ?? inventoryReservations.first(where: { $0.checkoutSessionId == s.id })?.storeId
                                ?? users.first(where: { $0.id == s.associateId })?.storeId
                                ?? stores.first?.id else {
                                print("[DataStore] ⚠️ Auto-reconciliation skipped for session \(s.token): store ID not resolved")
                                continue
                            }
                            let newTx = Transaction(
                                id: txId,
                                cartId: s.cartId,
                                storeId: storeId,
                                associateId: s.associateId,
                                clientId: s.clientId,
                                totalAmount: amt,
                                taxAmount: amt * 0.2 / 1.2,
                                currency: "INR",
                                status: .completed,
                                isTaxFree: false,
                                createdAt: s.createdAt
                            )
                            let newTender = Tender(
                                id: UUID(),
                                transactionId: txId,
                                method: .card,
                                amount: amt,
                                reference: "ONLINE (\(s.token))"
                            )
                            didReconcile = true
                            do {
                                try await createTransaction(newTx)
                                try await createTender(newTender)
                                print("[DataStore] 🚀 Automatically reconciled transaction and tender for online session \(s.token)")
                            } catch {
                                print("[DataStore] ⚠️ Auto-reconciliation failed for session \(s.token): \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            
            if didAdvance || didReconcile {
                // Find carts that are linked to these advanced sessions and complete them
                let advancedSessionCartIds = Set(checkoutSessions.filter { advancedStatuses.contains($0.status) }.map { $0.cartId })
                
                for cartId in advancedSessionCartIds {
                    if let cartIdx = universalCarts.firstIndex(where: { $0.id == cartId }), universalCarts[cartIdx].status != .completed {
                        // Create a mutable copy and update status
                        let oldCart = universalCarts[cartIdx]
                        let updatedCart = UniversalCart(
                            id: oldCart.id, type: oldCart.type, associateId: oldCart.associateId,
                            clientId: oldCart.clientId, storeId: oldCart.storeId, status: .completed,
                            note: oldCart.note, createdAt: oldCart.createdAt, updatedAt: Date()
                        )
                        universalCarts[cartIdx] = updatedCart
                        Task { try? await api.update("universal_carts", id: updatedCart.id, record: updatedCart) }
                    }
                }
                
                // Refresh transactions and orders so the UI updates
                try? await fetchTransactions()
                try? await fetchOrders()
            }
            
            // Clean up any lingering cart items in memory/Supabase for completed checkout sessions
            let completedCartIds = Set(checkoutSessions.filter { terminalStatuses.contains($0.status) }.map { $0.cartId })
            for cartId in completedCartIds {
                let itemsToDelete = universalCartItems.filter { $0.cartId == cartId }
                if !itemsToDelete.isEmpty {
                    print("[DataStore] 🛒 Found \(itemsToDelete.count) stale items in memory for completed cart \(cartId). Clearing them.")
                    for item in itemsToDelete {
                        Task {
                            try? await deleteUniversalCartItem(id: item.id)
                        }
                    }
                }
            }
        } catch {
            print("[DataStore] ⚠️ fetchCheckoutSessions from Supabase failed: \(error.localizedDescription). Using local state.")
        }
    }
    
    func fetchCheckoutSession(token: String) async throws -> CheckoutSession {
        do {
            let fetched: [CheckoutSession] = try await api.fetch("checkout_sessions", query: ["token": "eq.\(token)"])
            guard let first = fetched.first else {
                throw NSError(domain: "DataStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Checkout session not found."])
            }
            return first
        } catch {
            print("[DataStore] ⚠️ fetchCheckoutSession by token from Supabase failed: \(error.localizedDescription). Falling back to local state.")
            if let local = checkoutSessions.first(where: { $0.token == token }) {
                return local
            }
            throw error
        }
    }
    
    @discardableResult
    func createCheckoutSession(_ session: CheckoutSession) async throws -> CheckoutSession {
        if !checkoutSessions.contains(where: { $0.id == session.id }) {
            checkoutSessions.append(session)
        }
        
        defer {
            syncSessionWithLocalServer(session)
        }
        
        do {
            let created: CheckoutSession = try await api.insert("checkout_sessions", record: session)
            if let idx = checkoutSessions.firstIndex(where: { $0.id == session.id }) {
                checkoutSessions[idx] = created
            }
            return created
        } catch {
            print("[DataStore] ⚠️ createCheckoutSession in Supabase failed: \(error.localizedDescription). Kept locally in-memory.")
            return session
        }
    }
    
    func updateCheckoutSession(_ session: CheckoutSession) async throws {
        if let idx = checkoutSessions.firstIndex(where: { $0.id == session.id }) {
            checkoutSessions[idx] = session
        }
        
        defer {
            syncSessionWithLocalServer(session)
        }
        
        do {
            try await api.update("checkout_sessions", id: session.id, record: session)
        } catch {
            print("[DataStore] ⚠️ updateCheckoutSession in Supabase failed: \(error.localizedDescription). Updated locally in-memory.")
        }
    }
    
    func syncSessionWithLocalServer(_ session: CheckoutSession) {
#if DEBUG
        guard let url = URL(string: "\(checkoutServerBaseURL)/api/checkout/sync-session") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let cartItemsForSession = universalCartItems.filter { $0.cartId == session.cartId }
        let productsForSession = cartItemsForSession.compactMap { product(by: $0.productId) }
        let cart = universalCarts.first { $0.id == session.cartId }
        
        let subtotal = cartItemsForSession.reduce(0.0) { total, item in
            let price = item.unitPrice ?? product(by: item.productId)?.price ?? 0.0
            return total + (price * Double(item.quantity))
        }
        
        let discount = cart?.appliedDiscount.map { d -> Double in
            if d.type == .percentage { return subtotal * (d.value / 100.0) }
            return d.value
        } ?? 0.0
        
        let postDiscountSubtotal = max(0, subtotal - discount)
        let tax = postDiscountSubtotal * 0.20
        let finalTotal = postDiscountSubtotal + tax
        
        let cartItemsPayload: [[String: Any]] = cartItemsForSession.map { item in
            [
                "id": item.id.uuidString.lowercased(),
                "cart_id": item.cartId.uuidString.lowercased(),
                "product_id": item.productId.uuidString.lowercased(),
                "quantity": item.quantity,
                "unit_price": item.unitPrice as Any
            ]
        }
        
        let productsPayload: [[String: Any]] = productsForSession.map { prod in
            [
                "id": prod.id.uuidString.lowercased(),
                "name": prod.name,
                "price": prod.price,
                "brand": prod.brand,
                "category": prod.category,
                "sku": prod.sku
            ]
        }
        
        let payload: [String: Any] = [
            "session": [
                "id": session.id.uuidString.lowercased(),
                "cart_id": session.cartId.uuidString.lowercased(),
                "token": session.token,
                "client_id": session.clientId.uuidString.lowercased(),
                "associate_id": session.associateId.uuidString.lowercased(),
                "status": session.status.rawValue,
                "fulfillment_method": session.fulfillmentMethod?.rawValue as Any,
                "payment_method": session.paymentMethod?.rawValue as Any,
                "expires_at": ISO8601DateFormatter().string(from: session.expiresAt),
                "created_at": ISO8601DateFormatter().string(from: session.createdAt),
                "updated_at": ISO8601DateFormatter().string(from: session.updatedAt)
            ],
            "cartItems": cartItemsPayload,
            "products": productsPayload,
            "totals": [
                "subtotal": subtotal,
                "discount": discount,
                "tax": tax,
                "total": finalTotal
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
#endif
    }
    
    // MARK: - Pickup Confirmation Email
    
    /// Sends a pickup confirmation email to the client via the Python checkout server.
    /// Falls back silently if the server is unreachable — email is best-effort.
    func sendPickupConfirmationEmail(for session: CheckoutSession) async {
#if DEBUG
        guard let url = URL(string: "\(checkoutServerBaseURL)/api/checkout/send-pickup-email") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Resolve client email from local cache
        let clientEmail = client(by: session.clientId)?.email ?? ""
        let clientName  = client(by: session.clientId)?.fullName ?? "Valued Client"
        
        // Build cart item summary for the email body
        let cartItems = universalCartItems.filter { $0.cartId == session.cartId }
        let itemsPayload: [[String: Any]] = cartItems.map { item in
            let prod = product(by: item.productId)
            return [
                "name":     prod?.name ?? "Luxury Item",
                "quantity": item.quantity,
                "price":    item.unitPrice ?? prod?.price ?? 0
            ]
        }
        
        let formatter = ISO8601DateFormatter()
        let payload: [String: Any] = [
            "sessionId":         session.id.uuidString.lowercased(),
            "token":             session.token,
            "clientEmail":       clientEmail,
            "clientName":        clientName,
            "scheduledPickupAt": session.scheduledPickupAt.map { formatter.string(from: $0) } as Any,
            "pickupCode":        session.pickupCode as Any,
            "paymentMethod":     session.paymentMethod?.rawValue ?? "unknown",
            "fulfillmentMethod": session.fulfillmentMethod?.rawValue ?? "pickup",
            "items":             itemsPayload
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("[DataStore] ⚠️ sendPickupConfirmationEmail failed: \(error.localizedDescription)")
            } else {
                print("[DataStore] ✅ Pickup confirmation email sent for token: \(session.token)")
            }
        }.resume()
#endif
    }
    
    // MARK: - Checkout Shipping Addresses
    
    func fetchCheckoutShippingAddresses() async throws {
#if DEBUG
        if let url = URL(string: "\(checkoutServerBaseURL)/api/checkout/shipping-addresses") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoder = JSONDecoder()
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let isoFormatterNoFractional = ISO8601DateFormatter()
                isoFormatterNoFractional.formatOptions = [.withInternetDateTime]
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateStr = try container.decode(String.self)
                    if let date = formatter.date(from: dateStr) { return date }
                    if let date = isoFormatterNoFractional.date(from: dateStr) { return date }
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
                }
                let localAddresses = try decoder.decode([CheckoutShippingAddress].self, from: data)
                for addr in localAddresses {
                    if let idx = checkoutShippingAddresses.firstIndex(where: { $0.id == addr.id }) {
                        checkoutShippingAddresses[idx] = addr
                    } else {
                        checkoutShippingAddresses.append(addr)
                    }
                }
            } catch {
                print("[DataStore] ⚠️ Failed to fetch local shipping addresses from Python server: \(error.localizedDescription)")
            }
        }
#endif
        
        do {
            checkoutShippingAddresses = try await api.fetch("checkout_shipping_addresses")
        } catch {
            print("[DataStore] ⚠️ fetchCheckoutShippingAddresses from Supabase failed: \(error.localizedDescription). Using local state.")
        }
    }
    
    @discardableResult
    func createCheckoutShippingAddress(_ address: CheckoutShippingAddress) async throws -> CheckoutShippingAddress {
        if !checkoutShippingAddresses.contains(where: { $0.id == address.id }) {
            checkoutShippingAddresses.append(address)
        }
        
        do {
            let created: CheckoutShippingAddress = try await api.insert("checkout_shipping_addresses", record: address)
            if let idx = checkoutShippingAddresses.firstIndex(where: { $0.id == address.id }) {
                checkoutShippingAddresses[idx] = created
            }
            return created
        } catch {
            print("[DataStore] ⚠️ createCheckoutShippingAddress in Supabase failed: \(error.localizedDescription). Kept locally.")
            return address
        }
    }
    
    // MARK: - Inventory Reservations
    
    func fetchInventoryReservations() async throws {
        do {
            inventoryReservations = try await api.fetch("inventory_reservations")
        } catch {
            print("[DataStore] ⚠️ fetchInventoryReservations from Supabase failed: \(error.localizedDescription). Using local state.")
        }
    }
    
    @discardableResult
    func createInventoryReservation(_ reservation: InventoryReservation) async throws -> InventoryReservation {
        if !inventoryReservations.contains(where: { $0.id == reservation.id }) {
            inventoryReservations.append(reservation)
        }
        
        do {
            let created: InventoryReservation = try await api.insert("inventory_reservations", record: reservation)
            if let idx = inventoryReservations.firstIndex(where: { $0.id == reservation.id }) {
                inventoryReservations[idx] = created
            }
            return created
        } catch {
            print("[DataStore] ⚠️ createInventoryReservation in Supabase failed: \(error.localizedDescription). Kept locally.")
            return reservation
        }
    }
    
    func updateInventoryReservation(_ reservation: InventoryReservation) async throws {
        if let idx = inventoryReservations.firstIndex(where: { $0.id == reservation.id }) {
            inventoryReservations[idx] = reservation
        }
        
        do {
            try await api.update("inventory_reservations", id: reservation.id, record: reservation)
        } catch {
            print("[DataStore] ⚠️ updateInventoryReservation in Supabase failed: \(error.localizedDescription). Updated locally.")
        }
    }
    
    // MARK: - service_requests
    // ══════════════════════════════════════════════════════════
    
    func fetchServiceRequests(storeId: UUID? = nil) async throws {
        var query: [String: String] = [:]
        if let sid = storeId { query["store_id"] = "eq.\(sid)" }
        serviceRequests = try await api.fetch("service_requests", query: query)
    }
    
    @discardableResult
    func createServiceRequest(_ sr: ServiceRequest) async throws -> ServiceRequest {
        let created: ServiceRequest = try await api.insert("service_requests", record: sr)
        serviceRequests.append(created)
        return created
    }
    
    func updateServiceRequest(_ sr: ServiceRequest) async throws {
        try await api.update("service_requests", id: sr.id, record: sr)
        if let i = serviceRequests.firstIndex(where: { $0.id == sr.id }) { serviceRequests[i] = sr }
    }
    
    func deleteServiceRequest(id: UUID) async throws {
        try await api.delete("service_requests", id: id)
        await MainActor.run {
            serviceRequests.removeAll { $0.id == id }
        }
    }
    
    // ══════════════════════════════════════════════════════════
    // MARK: - service_activities
    // ══════════════════════════════════════════════════════════
    
    func fetchServiceActivities(requestId: String? = nil) async throws {
        var query: [String: String] = [:]
        if let rid = requestId { query["request_id"] = "eq.\(rid)" }
        serviceActivities = try await api.fetch("service_activities", query: query)
    }
    
    @discardableResult
    func createServiceActivity(_ sa: ServiceActivity) async throws -> ServiceActivity {
        let created: ServiceActivity = try await api.insert("service_activities", record: sa)
        serviceActivities.append(created)
        return created
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
        checkoutSessions = []
        checkoutShippingAddresses = []
        inventoryReservations = []
    }
    
    // ══════════════════════════════════════════════════════════
    // MARK: - loaner_assignments
    // ══════════════════════════════════════════════════════════
    
    func fetchLoanerAssignments(storeId: UUID? = nil) async throws {
        let endpoint = storeId != nil ? "loaner_assignments?store_id=eq.\(storeId!)" : "loaner_assignments"
        loanerAssignments = try await api.fetch(endpoint)
    }
    
    @discardableResult
    func createLoanerAssignment(_ assignment: LoanerAssignment) async throws -> LoanerAssignment {
        let created: LoanerAssignment = try await api.insert("loaner_assignments", record: assignment)
        loanerAssignments.append(created)
        return created
    }
    
    func updateLoanerAssignment(_ assignment: LoanerAssignment) async throws {
        try await api.update("loaner_assignments", id: assignment.id, record: assignment)
        if let i = loanerAssignments.firstIndex(where: { $0.id == assignment.id }) { loanerAssignments[i] = assignment }
    }
    
    // ══════════════════════════════════════════════════════════
    // MARK: - loaner_activities
    // ══════════════════════════════════════════════════════════
    
    func fetchLoanerActivities(assignmentId: String? = nil) async throws {
        let endpoint = assignmentId != nil ? "loaner_activities?assignment_id=eq.\(assignmentId!)" : "loaner_activities"
        loanerActivities = try await api.fetch(endpoint)
    }
    
    @discardableResult
    func createLoanerActivity(_ activity: LoanerActivity) async throws -> LoanerActivity {
        let created: LoanerActivity = try await api.insert("loaner_activities", record: activity)
        loanerActivities.append(created)
        return created
    }
}
