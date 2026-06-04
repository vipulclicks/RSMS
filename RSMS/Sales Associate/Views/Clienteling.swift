//
//  ClientProfileFeatures.swift
//  RSMS
//
//  Created by Vipul Kumar Singh on 20/05/26.
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    static let brandCrimson  = Color(red: 0.506, green: 0.043, blue: 0.220)
    static let brandCream    = Color(red: 0.945, green: 0.886, blue: 0.820)
    static let brandTaupe    = Color(red: 0.863, green: 0.765, blue: 0.667)
    static let brandBurgundy = Color(red: 0.329, green: 0.102, blue: 0.102)
}

// MARK: - Anniversary Type

enum AnniversaryType: String, CaseIterable, Codable {
    case birthday        = "birthday"
    case wedding         = "wedding"
    case custom          = "custom"

    var displayName: String {
        switch self {
        case .birthday: "Birthday"
        case .wedding:  "Wedding Anniversary"
        case .custom:   "Custom"
        }
    }

    var symbolName: String {
        switch self {
        case .birthday: "gift.fill"
        case .wedding:  "heart.fill"
        case .custom:   "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .birthday: Color(red: 0.357, green: 0.435, blue: 0.651)
        case .wedding:  Color.brandCrimson
        case .custom:   Color(red: 0.788, green: 0.659, blue: 0.298)
        }
    }
}

// MARK: - Mock Data Models

struct MockClientProfile: Identifiable, Hashable {
    let id: UUID
    var fullName: String
    var email: String?
    var phone: String?
    var preferredStoreId: UUID?
    var privacyConsentGiven: Bool
    var consentDate: Date?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: MockClientProfile, rhs: MockClientProfile) -> Bool { lhs.id == rhs.id }
}

struct MockClientPreference: Identifiable {
    let id: UUID
    let clientId: UUID
    var ringSize: String?
    var braceletSize: String?
    var necklaceLength: String?
    var wristSize: String?
    var favoriteCategories: [String]
    var favoriteMetals: [String]
    var favoriteGemstones: [String]
    var notes: String?
}

struct MockTransaction: Identifiable {
    let id: UUID
    let clientId: UUID
    let date: Date
    let totalAmount: Double
    let currency: String
    let productNames: [String]
    let status: TransactionStatus
}

struct MockAnniversary: Identifiable, Hashable {
    let id: UUID
    var clientId: UUID
    var type: AnniversaryType
    var customLabel: String?       // only used when type == .custom
    var date: Date
    var reminderEnabled: Bool

    var displayLabel: String {
        type == .custom ? (customLabel ?? "Custom") : type.displayName
    }

    /// Days until next occurrence (0 = today)
    var daysUntilNext: Int {
        let cal = Calendar.current
        let now = Date.now
        let components = cal.dateComponents([.month, .day], from: date)
        let next = cal.nextDate(after: now,
                                matching: DateComponents(month: components.month, day: components.day),
                                matchingPolicy: .nextTimePreservingSmallerComponents) ?? now
        // If today is the date, daysUntilNext = 0
        let diff = cal.dateComponents([.day], from: cal.startOfDay(for: now),
                                      to: cal.startOfDay(for: next)).day ?? 0
        return diff
    }
}

struct MockWishlistItem: Identifiable, Hashable {
    let id: UUID
    var clientId: UUID
    var productName: String
    var sku: String
    var category: String
    var priceINR: Double
    var isAvailable: Bool
    var notifyOnRestock: Bool
    var addedAt: Date
    var notes: String?
}

// MARK: - Sample Data

extension MockClientProfile {
    static let samples: [MockClientProfile] = [
        MockClientProfile(
            id: UUID(), fullName: "Isabelle Fontaine",
            email: "isabelle@maison.fr", phone: "+33 6 12 34 56 78",
            privacyConsentGiven: true, consentDate: Date(),
            notes: "Prefers private viewings. Allergic to nickel.",
            createdAt: Calendar.current.date(byAdding: .year, value: -4, to: .now)!,
            updatedAt: .now
        ),
        MockClientProfile(
            id: UUID(), fullName: "Arjun Mehta",
            email: "arjun.mehta@deluxe.in", phone: "+91 98765 43210",
            privacyConsentGiven: true, consentDate: Date(),
            notes: "Gifting for spouse. Interested in emerald pieces.",
            createdAt: Calendar.current.date(byAdding: .year, value: -2, to: .now)!,
            updatedAt: .now
        ),
        MockClientProfile(
            id: UUID(), fullName: "Sophia Delacroix",
            email: "sophia@lumiere.com", phone: "+1 310 555 0198",
            privacyConsentGiven: true, consentDate: Date(),
            notes: "Hosts annual charity gala.",
            createdAt: Calendar.current.date(byAdding: .year, value: -7, to: .now)!,
            updatedAt: .now
        ),
        MockClientProfile(
            id: UUID(), fullName: "Ryo Tanaka",
            email: "ryo.t@horizon.jp", phone: "+81 90 1234 5678",
            privacyConsentGiven: false,
            notes: "First visit. Interested in men's accessories.",
            createdAt: Calendar.current.date(byAdding: .month, value: -3, to: .now)!,
            updatedAt: .now
        ),
        MockClientProfile(
            id: UUID(), fullName: "Priya Nair",
            email: "priya.nair@velvet.co", phone: "+44 7700 900123",
            privacyConsentGiven: true, consentDate: Date(), notes: nil,
            createdAt: Calendar.current.date(byAdding: .month, value: -8, to: .now)!,
            updatedAt: .now
        ),
    ]
}

func makeSamplePreferences(for clientId: UUID) -> MockClientPreference {
    MockClientPreference(
        id: UUID(), clientId: clientId,
        ringSize: "52", braceletSize: "17 cm",
        necklaceLength: "45 cm", wristSize: "16.5 cm",
        favoriteCategories: ["Rings", "Necklaces", "Bracelets"],
        favoriteMetals: ["18K Rose Gold", "Platinum"],
        favoriteGemstones: ["Diamond", "Ruby", "Sapphire"],
        notes: nil
    )
}

func makeSampleTransactions(for clientId: UUID) -> [MockTransaction] {
    let cal = Calendar.current
    return [
        MockTransaction(id: UUID(), clientId: clientId,
                        date: cal.date(byAdding: .month, value: -2, to: .now)!,
                        totalAmount: 10_34_500, currency: "₹",
                        productNames: ["Lumière Solitaire Ring", "Diamond Tennis Bracelet"],
                        status: .completed),
        MockTransaction(id: UUID(), clientId: clientId,
                        date: cal.date(byAdding: .month, value: -6, to: .now)!,
                        totalAmount: 3_99_000, currency: "₹",
                        productNames: ["Halo Pendant Necklace"],
                        status: .completed),
        MockTransaction(id: UUID(), clientId: clientId,
                        date: cal.date(byAdding: .month, value: -11, to: .now)!,
                        totalAmount: 5_98_500, currency: "₹",
                        productNames: ["Rivière Earrings", "Ruby Cocktail Ring"],
                        status: .completed),
    ]
}

func makeSampleAnniversaries(for clientId: UUID) -> [MockAnniversary] {
    let cal = Calendar.current
    return [
        MockAnniversary(
            id: UUID(), clientId: clientId,
            type: .birthday, customLabel: nil,
            date: cal.date(from: DateComponents(year: 1985, month: 8, day: 14))!,
            reminderEnabled: true
        ),
        MockAnniversary(
            id: UUID(), clientId: clientId,
            type: .wedding, customLabel: nil,
            date: cal.date(from: DateComponents(year: 2010, month: 3, day: 22))!,
            reminderEnabled: true
        ),
        MockAnniversary(
            id: UUID(), clientId: clientId,
            type: .custom, customLabel: "First Purchase",
            date: cal.date(byAdding: .year, value: -4, to: .now)!,
            reminderEnabled: false
        ),
    ]
}

let sampleProductCatalogue: [MockWishlistItem] = [
    MockWishlistItem(id: UUID(), clientId: UUID(), productName: "Lumière Solitaire Ring",
                     sku: "RNG-001", category: "Rings", priceINR: 2_45_000,
                     isAvailable: true, notifyOnRestock: false, addedAt: .now),
    MockWishlistItem(id: UUID(), clientId: UUID(), productName: "Éclat Diamond Necklace",
                     sku: "NCK-042", category: "Necklaces", priceINR: 5_80_000,
                     isAvailable: true, notifyOnRestock: false, addedAt: .now),
    MockWishlistItem(id: UUID(), clientId: UUID(), productName: "Rivière Earrings",
                     sku: "EAR-017", category: "Earrings", priceINR: 1_95_000,
                     isAvailable: false, notifyOnRestock: false, addedAt: .now),
    MockWishlistItem(id: UUID(), clientId: UUID(), productName: "Halo Pendant",
                     sku: "NCK-055", category: "Necklaces", priceINR: 3_20_000,
                     isAvailable: true, notifyOnRestock: false, addedAt: .now),
    MockWishlistItem(id: UUID(), clientId: UUID(), productName: "Rose Gold Bangle",
                     sku: "BGL-008", category: "Bracelets", priceINR: 88_000,
                     isAvailable: true, notifyOnRestock: false, addedAt: .now),
    MockWishlistItem(id: UUID(), clientId: UUID(), productName: "Ruby Cocktail Ring",
                     sku: "RNG-034", category: "Rings", priceINR: 4_10_000,
                     isAvailable: false, notifyOnRestock: false, addedAt: .now),
    MockWishlistItem(id: UUID(), clientId: UUID(), productName: "Sapphire Tennis Bracelet",
                     sku: "BRC-021", category: "Bracelets", priceINR: 6_75_000,
                     isAvailable: true, notifyOnRestock: false, addedAt: .now),
    MockWishlistItem(id: UUID(), clientId: UUID(), productName: "Platinum Eternity Band",
                     sku: "RNG-060", category: "Rings", priceINR: 1_55_000,
                     isAvailable: true, notifyOnRestock: false, addedAt: .now),
]

// MARK: - ViewModel

@Observable
final class ClientProfilesViewModel {
    var clients: [MockClientProfile] = MockClientProfile.samples
    var searchText: String = ""
    var showNewClientSheet: Bool = false

    // Per-client wishlist store: clientId → [MockWishlistItem]
    var wishlists: [UUID: [MockWishlistItem]] = [:]
    // Per-client anniversaries store: clientId → [MockAnniversary]
    var anniversaries: [UUID: [MockAnniversary]] = [:]

    init() {
        // Seed sample data for each client
        for client in clients {
            wishlists[client.id] = []
            anniversaries[client.id] = makeSampleAnniversaries(for: client.id)
        }
    }

    var filtered: [MockClientProfile] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return clients }
        return clients.filter {
            $0.fullName.lowercased().contains(q) ||
            ($0.email?.lowercased().contains(q) ?? false) ||
            ($0.phone?.contains(q) ?? false) ||
            $0.id.uuidString.lowercased().contains(q)
        }
    }

    func addClient(_ client: MockClientProfile) {
        clients.insert(client, at: 0)
        wishlists[client.id] = []
        anniversaries[client.id] = []
    }

    // MARK: Wishlist helpers
    func wishlist(for clientId: UUID) -> [MockWishlistItem] {
        wishlists[clientId] ?? []
    }

    func addToWishlist(_ item: MockWishlistItem, clientId: UUID) {
        wishlists[clientId, default: []].append(item)
    }

    func removeFromWishlist(itemId: UUID, clientId: UUID) {
        wishlists[clientId]?.removeAll { $0.id == itemId }
    }

    func toggleNotify(itemId: UUID, clientId: UUID) {
        guard let idx = wishlists[clientId]?.firstIndex(where: { $0.id == itemId }) else { return }
        wishlists[clientId]?[idx].notifyOnRestock.toggle()
    }

    // MARK: Anniversary helpers
    func anniversaries(for clientId: UUID) -> [MockAnniversary] {
        (anniversaries[clientId] ?? []).sorted { $0.daysUntilNext < $1.daysUntilNext }
    }

    func addAnniversary(_ ann: MockAnniversary, clientId: UUID) {
        anniversaries[clientId, default: []].append(ann)
    }

    func deleteAnniversary(id: UUID, clientId: UUID) {
        anniversaries[clientId]?.removeAll { $0.id == id }
    }

    func toggleAnniversaryReminder(id: UUID, clientId: UUID) {
        guard let idx = anniversaries[clientId]?.firstIndex(where: { $0.id == id }) else { return }
        anniversaries[clientId]?[idx].reminderEnabled.toggle()
    }
}

// MARK: - Root Entry Point

struct ClientelingRootView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var vm = ClientProfilesViewModel()

    var body: some View {
        Group {
            if sizeClass == .regular {
                ClientProfilesIPadView(vm: vm)
            } else {
                ClientProfilesPhoneView(vm: vm)
            }
        }
        .sheet(isPresented: $vm.showNewClientSheet) {
            NewClientSheet(vm: vm)
        }
    }
}

// MARK: - iPhone Layout

struct ClientProfilesPhoneView: View {
    let vm: ClientProfilesViewModel

    var body: some View {
        NavigationStack {
            ClientListView(vm: vm)
                .navigationDestination(for: MockClientProfile.self) { client in
                    ClientDetailView(client: client, vm: vm)
                }
        }
    }
}

// MARK: - iPad Layout

struct ClientProfilesIPadView: View {
    let vm: ClientProfilesViewModel
    @State private var selectedClient: MockClientProfile?

    var body: some View {
        NavigationSplitView {
            ClientListView(vm: vm, selectedClient: $selectedClient)
                .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 420)
        } detail: {
            if let client = selectedClient {
                ClientDetailView(client: client, vm: vm)
            } else {
                EmptySelectionView()
            }
        }
    }
}

// MARK: - Client List View

struct ClientListView: View {
    let vm: ClientProfilesViewModel
    var selectedClient: Binding<MockClientProfile?>? = nil

    var body: some View {
        List {
            ForEach(vm.filtered) { client in
                if let binding = selectedClient {
                    ClientRowView(client: client,
                                  isSelected: binding.wrappedValue?.id == client.id)
                        .contentShape(Rectangle())
                        .onTapGesture { binding.wrappedValue = client }
                        .listRowBackground(
                            binding.wrappedValue?.id == client.id
                            ? Color.brandCrimson.opacity(0.06) : Color.clear
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                } else {
                    NavigationLink(value: client) {
                        ClientRowView(client: client)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Clients")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: Bindable(vm).searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Name, phone, email or ID")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { vm.showNewClientSheet = true } label: {
                    Image(systemName: "person.badge.plus").accessibilityLabel("Add").fontWeight(.medium)
                }
                .tint(.brandCrimson)
            }
        }
        .overlay {
            if vm.filtered.isEmpty {
                ContentUnavailableView.search(text: vm.searchText)
            }
        }
    }
}

// MARK: - Client Row

struct ClientRowView: View {
    let client: MockClientProfile
    var isSelected: Bool = false

    private var initials: String {
        client.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandCrimson.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(initials)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandCrimson)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(client.fullName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if let contact = client.email ?? client.phone {
                    Text(contact)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if !client.privacyConsentGiven {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Client Detail View

struct ClientDetailView: View {
    let client: MockClientProfile
    let vm: ClientProfilesViewModel

    @State private var showWishlistScreen = false
    @State private var showAddAnniversary = false

    private var preferences: MockClientPreference { makeSamplePreferences(for: client.id) }
    private var transactions: [MockTransaction]   { makeSampleTransactions(for: client.id) }
    private var anniversaries: [MockAnniversary]  { vm.anniversaries(for: client.id) }
    private var wishlist: [MockWishlistItem]       { vm.wishlist(for: client.id) }
    private var lifetimeValue: Double { transactions.reduce(0) { $0 + $1.totalAmount } }

    private var initials: String {
        client.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var body: some View {
        List {
            // Contact
            Section("Contact Information") {
                if let email = client.email {
                    LabeledContent { Text(email).foregroundStyle(.secondary) }
                        label: { Label("Email", systemImage: "envelope") }
                }
                if let phone = client.phone {
                    LabeledContent { Text(phone).foregroundStyle(.secondary) }
                        label: { Label("Phone", systemImage: "phone") }
                }
                LabeledContent {
                    Text(client.createdAt, style: .date).foregroundStyle(.secondary)
                } label: { Label("Member Since", systemImage: "calendar") }
            }

            // Purchase Summary
            Section("Purchase Summary") {
                LabeledContent("Lifetime Value") {
                    Text("₹\(lifetimeValue, format: .number.precision(.fractionLength(0)))")
                        .foregroundStyle(Color.brandCrimson).fontWeight(.semibold)
                }
                LabeledContent("Total Purchases") {
                    Text("\(transactions.count)").foregroundStyle(.secondary)
                }
            }

            // Anniversaries & Important Dates
            Section {
                if anniversaries.isEmpty {
                    Text("No dates added yet.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(anniversaries) { ann in
                        AnniversaryRow(ann: ann) {
                            vm.toggleAnniversaryReminder(id: ann.id, clientId: client.id)
                        }
                    }
                    .onDelete { indexSet in
                        let sorted = anniversaries
                        indexSet.forEach { vm.deleteAnniversary(id: sorted[$0].id, clientId: client.id) }
                    }
                }
            } header: {
                HStack {
                    Text("Important Dates")
                    Spacer()
                    Button {
                        showAddAnniversary = true
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandCrimson)
                    }
                }
            }

            // Wishlist
            Section {
                if wishlist.isEmpty {
                    Text("No items on wishlist.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(wishlist.prefix(3)) { item in
                        WishlistSummaryRow(item: item)
                    }
                    if wishlist.count > 3 {
                        Text("+ \(wishlist.count - 3) more items")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: {
                HStack {
                    Text("Wishlist")
                    Spacer()
                    Button {
                        showWishlistScreen = true
                    } label: {
                        Label("Manage", systemImage: "arrow.up.right.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandCrimson)
                    }
                }
            }

            // Notes
            if let notes = client.notes, !notes.isEmpty {
                Section("Associate Notes") {
                    Text(notes).font(.subheadline).foregroundStyle(.secondary)
                }
            }

            // Sizing
            Section("Sizing Preferences") {
                if let v = preferences.ringSize {
                    LabeledContent("Ring Size") { Text(v).foregroundStyle(.secondary) }
                }
                if let v = preferences.braceletSize {
                    LabeledContent("Bracelet Size") { Text(v).foregroundStyle(.secondary) }
                }
                if let v = preferences.necklaceLength {
                    LabeledContent("Necklace Length") { Text(v).foregroundStyle(.secondary) }
                }
                if let v = preferences.wristSize {
                    LabeledContent("Wrist Size") { Text(v).foregroundStyle(.secondary) }
                }
            }

            // Style
            Section("Style Preferences") {
                PreferenceTagRow(title: "Categories", tags: preferences.favoriteCategories, color: .brandCrimson)
                PreferenceTagRow(title: "Metals", tags: preferences.favoriteMetals, color: Color(red: 0.788, green: 0.659, blue: 0.298))
                PreferenceTagRow(title: "Gemstones", tags: preferences.favoriteGemstones, color: Color(red: 0.357, green: 0.435, blue: 0.651))
            }

            // Purchase History
            Section("Purchase History") {
                if transactions.isEmpty {
                    ContentUnavailableView("No Purchases", systemImage: "bag")
                } else {
                    ForEach(transactions) { TransactionRow(txn: $0) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(client.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .tint(.brandCrimson)
        .sheet(isPresented: $showWishlistScreen) {
            WishlistManagementView(client: client, vm: vm)
        }
        .sheet(isPresented: $showAddAnniversary) {
            AddAnniversarySheet(client: client, vm: vm)
        }
    }
}
// MARK: - Anniversary Row

struct AnniversaryRow: View {
    let ann: MockAnniversary
    let onToggleReminder: () -> Void

    private var daysLabel: String {
        switch ann.daysUntilNext {
        case 0:  return "Today!"
        case 1:  return "Tomorrow"
        default: return "In \(ann.daysUntilNext) days"
        }
    }

    private var daysLabelColor: Color {
        switch ann.daysUntilNext {
        case 0...7:   return .brandCrimson
        case 8...30:  return .orange
        default:       return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ann.type.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: ann.type.symbolName)
                    .font(.subheadline)
                    .foregroundStyle(ann.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ann.displayLabel)
                    .font(.subheadline.weight(.semibold))
                Text(ann.date, format: .dateTime.day().month(.wide))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(daysLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(daysLabelColor)
                Button {
                    onToggleReminder()
                } label: {
                    Image(systemName: ann.reminderEnabled ? "bell.fill" : "bell.slash").accessibilityLabel("Action")
                        .font(.caption)
                        .foregroundStyle(ann.reminderEnabled ? Color.brandCrimson : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Wishlist Summary Row (in detail view)

struct WishlistSummaryRow: View {
    let item: MockWishlistItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "diamond.fill")
                .font(.caption)
                .foregroundStyle(Color.brandCrimson.opacity(0.6))
            VStack(alignment: .leading, spacing: 1) {
                Text(item.productName)
                    .font(.subheadline)
                Text(item.sku)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text("₹\(item.priceINR, format: .number.precision(.fractionLength(0)))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandCrimson)
            if !item.isAvailable {
                Text("Out of Stock")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.orange.opacity(0.10), in: Capsule())
            }
        }
    }
}

// MARK: - Wishlist Management Screen

struct WishlistManagementView: View {
    let client: MockClientProfile
    let vm: ClientProfilesViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showAddSheet = false
    @State private var searchText = ""

    private var wishlist: [MockWishlistItem] { vm.wishlist(for: client.id) }

    private var filtered: [MockWishlistItem] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return wishlist }
        return wishlist.filter {
            $0.productName.lowercased().contains(q) ||
            $0.sku.lowercased().contains(q) ||
            $0.category.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if wishlist.isEmpty {
                    ContentUnavailableView {
                        Label("Empty Wishlist", systemImage: "heart.slash")
                    } description: {
                        Text("Add products from the catalogue or by entering a SKU.")
                    } actions: {
                        Button("Add Item") { showAddSheet = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.brandCrimson)
                    }
                } else {
                    List {
                        ForEach(filtered) { item in
                            WishlistDetailRow(item: item) {
                                vm.toggleNotify(itemId: item.id, clientId: client.id)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparatorTint(Color.brandTaupe.opacity(0.4))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { vm.removeFromWishlist(itemId: filtered[$0].id, clientId: client.id) }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search by name, SKU or category")
                }
            }
            .navigationTitle("\(client.fullName)'s Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }.tint(.brandCrimson)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus").accessibilityLabel("Add").fontWeight(.medium)
                    }
                    .tint(.brandCrimson)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddToWishlistSheet(client: client, vm: vm)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Wishlist Detail Row

struct WishlistDetailRow: View {
    let item: MockWishlistItem
    let onToggleNotify: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.brandCrimson.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: "diamond.fill")
                    .foregroundStyle(Color.brandCrimson.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.productName)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(item.sku)
                        .font(.caption).foregroundStyle(.tertiary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(item.category)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("₹\(item.priceINR, format: .number.precision(.fractionLength(0)))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.brandCrimson)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                // Availability badge
                Text(item.isAvailable ? "Available" : "Out of Stock")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(item.isAvailable ? .green : .orange)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background((item.isAvailable ? Color.green : Color.orange).opacity(0.10), in: Capsule())

                // Notify toggle (only relevant when out of stock)
                if !item.isAvailable {
                    Button {
                        onToggleNotify()
                    } label: {
                        Label(
                            item.notifyOnRestock ? "Notify On" : "Notify Off",
                            systemImage: item.notifyOnRestock ? "bell.fill" : "bell.slash"
                        )
                        .font(.caption2)
                        .foregroundStyle(item.notifyOnRestock ? Color.brandCrimson : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add To Wishlist Sheet

struct AddToWishlistSheet: View {
    let client: MockClientProfile
    let vm: ClientProfilesViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var mode: AddMode = .catalogue
    @State private var catalogueSearch = ""
    @State private var manualName = ""
    @State private var manualSKU = ""
    @State private var manualCategory = ""
    @State private var manualPrice = ""
    @State private var manualNotes = ""

    enum AddMode: String, CaseIterable {
        case catalogue = "Catalogue"
        case manual    = "Manual Entry"
    }

    private var existingSKUs: Set<String> { Set(vm.wishlist(for: client.id).map(\.sku)) }

    private var filteredCatalogue: [MockWishlistItem] {
        let q = catalogueSearch.trimmingCharacters(in: .whitespaces).lowercased()
        let base = sampleProductCatalogue.filter { !existingSKUs.contains($0.sku) }
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.productName.lowercased().contains(q) ||
            $0.sku.lowercased().contains(q) ||
            $0.category.lowercased().contains(q)
        }
    }

    private var manualIsValid: Bool {
        !manualName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !manualSKU.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(AddMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                if mode == .catalogue {
                    catalogueView
                } else {
                    manualEntryView
                }
            }
            .navigationTitle("Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }.tint(.brandCrimson)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Catalogue picker
    @ViewBuilder
    private var catalogueView: some View {
        List {
            if filteredCatalogue.isEmpty {
                ContentUnavailableView("No Products Found",
                                       systemImage: "magnifyingglass")
            } else {
                ForEach(filteredCatalogue) { product in
                    Button {
                        let newItem = MockWishlistItem(
                            id: UUID(), clientId: client.id,
                            productName: product.productName,
                            sku: product.sku, category: product.category,
                            priceINR: product.priceINR,
                            isAvailable: product.isAvailable,
                            notifyOnRestock: false,
                            addedAt: .now, notes: nil
                        )
                        vm.addToWishlist(newItem, clientId: client.id)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(product.productName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                HStack(spacing: 6) {
                                    Text(product.sku).font(.caption).foregroundStyle(.tertiary)
                                    Text("·").foregroundStyle(.tertiary)
                                    Text(product.category).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("₹\(product.priceINR, format: .number.precision(.fractionLength(0)))")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.brandCrimson)
                                Text(product.isAvailable ? "In Stock" : "Out of Stock")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(product.isAvailable ? .green : .orange)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background((product.isAvailable ? Color.green : Color.orange).opacity(0.10), in: Capsule())
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $catalogueSearch, prompt: "Search catalogue…")
    }

    // MARK: Manual entry
    @ViewBuilder
    private var manualEntryView: some View {
        Form {
            Section("Product Details") {
                TextField("Product Name", text: $manualName).autocorrectionDisabled()
                TextField("SKU", text: $manualSKU)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                TextField("Category", text: $manualCategory).autocorrectionDisabled()
                HStack {
                    Text("₹")
                    TextField("Price", text: $manualPrice).keyboardType(.decimalPad)
                }
            }
            Section("Notes") {
                TextField("Any notes…", text: $manualNotes, axis: .vertical).lineLimit(2...4)
            }
            Section {
                Button("Add to Wishlist") {
                    guard manualIsValid else { return }
                    let item = MockWishlistItem(
                        id: UUID(), clientId: client.id,
                        productName: manualName.trimmingCharacters(in: .whitespaces),
                        sku: manualSKU.trimmingCharacters(in: .whitespaces),
                        category: manualCategory.isEmpty ? "Uncategorised" : manualCategory.trimmingCharacters(in: .whitespaces),
                        priceINR: Double(manualPrice) ?? 0,
                        isAvailable: true,
                        notifyOnRestock: false,
                        addedAt: .now,
                        notes: manualNotes.isEmpty ? nil : manualNotes
                    )
                    vm.addToWishlist(item, clientId: client.id)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(manualIsValid ? Color.brandCrimson : .secondary)
                .disabled(!manualIsValid)
            }
        }
    }
}

// MARK: - Add Anniversary Sheet

struct AddAnniversarySheet: View {
    let client: MockClientProfile
    let vm: ClientProfilesViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var type: AnniversaryType = .birthday
    @State private var customLabel = ""
    @State private var date = Date.now
    @State private var reminderEnabled = true
    @State private var showValidation = false

    private var isValid: Bool {
        type != .custom || !customLabel.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Type") {
                    Picker("Type", selection: $type) {
                        ForEach(AnniversaryType.allCases, id: \.self) { t in
                            Label(t.displayName, systemImage: t.symbolName).tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                    .tint(.brandCrimson)

                    if type == .custom {
                        TextField("Label (e.g. First Purchase)", text: $customLabel)
                            .autocorrectionDisabled()
                    }
                }

                Section("Date") {
                    DatePicker(
                        type == .birthday ? "Date of Birth" : "Date",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .tint(.brandCrimson)
                }

                Section {
                    Toggle(isOn: $reminderEnabled) {
                        Label("Enable Reminder", systemImage: "bell")
                    }
                    .tint(.brandCrimson)
                } footer: {
                    Text("Reminders will alert you 7 days before the occasion.")
                }
            }
            .navigationTitle("Add Important Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }.tint(.brandCrimson)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard isValid else { showValidation = true; return }
                        let ann = MockAnniversary(
                            id: UUID(), clientId: client.id,
                            type: type,
                            customLabel: type == .custom ? customLabel.trimmingCharacters(in: .whitespaces) : nil,
                            date: date,
                            reminderEnabled: reminderEnabled
                        )
                        vm.addAnniversary(ann, clientId: client.id)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(.brandCrimson)
                }
            }
            .alert("Missing Label", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a label for the custom date.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Hero Cell

struct ClientHeroCell: View {
    let client: MockClientProfile
    let initials: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandCrimson.opacity(0.12))
                    .frame(width: 80, height: 80)
                Text(initials)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.brandCrimson)
            }
            .padding(.top, 24)

            Text(client.fullName)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
}

// MARK: - Preference Tag Row

struct PreferenceTagRow: View {
    let title: String
    let tags: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(color)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(color.opacity(0.10), in: Capsule())
                            .overlay(Capsule().stroke(color.opacity(0.20), lineWidth: 1))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let txn: MockTransaction

    var statusColor: Color {
        switch txn.status {
        case .completed: .green
        case .pending:   .orange
        case .voided:    .secondary
        case .refunded:  .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(txn.date, style: .date).font(.subheadline.weight(.semibold))
                    Text("Order #\(txn.id.uuidString.prefix(8).uppercased())")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(txn.currency)\(txn.totalAmount, format: .number.precision(.fractionLength(0)))")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.brandCrimson)
                    Text(txn.status.rawValue.capitalized)
                        .font(.caption.weight(.medium)).foregroundStyle(statusColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(statusColor.opacity(0.10), in: Capsule())
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                ForEach(txn.productNames, id: \.self) { name in
                    Label(name, systemImage: "diamond")
                        .font(.caption).foregroundStyle(.secondary).imageScale(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Selection (iPad)

struct EmptySelectionView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Select a Client", systemImage: "person.crop.rectangle.stack")
        } description: {
            Text("Choose a client from the list to view their profile, preferences, and purchase history.")
        }
        .tint(.brandCrimson)
    }
}

// MARK: - New Client Sheet

struct NewClientSheet: View {
    let vm: ClientProfilesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var privacyConsentGiven = false
    @State private var notes = ""
    @State private var ringSize = ""
    @State private var braceletSize = ""
    @State private var necklaceLength = ""
    @State private var wristSize = ""
    @State private var favCategoriesText = ""
    @State private var favMetalsText = ""
    @State private var favGemstonesText = ""
    @State private var showValidationAlert = false

    private var isValid: Bool { !fullName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: $fullName).textContentType(.name).autocorrectionDisabled()
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress).keyboardType(.emailAddress)
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone).textContentType(.telephoneNumber).keyboardType(.phonePad)
                } header: { Text("Identity") }
                footer: { Text("Full name is required to create a profile.") }

                Section("Consent") {
                    Toggle(isOn: $privacyConsentGiven) {
                        Label("Privacy Consent Given", systemImage: "checkmark.shield")
                    }
                    .tint(.brandCrimson)
                }

                Section("Associate Notes") {
                    TextField("Any relevant notes…", text: $notes, axis: .vertical).lineLimit(3...6)
                }

                Section("Sizing Preferences") {
                    LuxurySizeField(
                        title: "Ring Size",
                        text: $ringSize,
                        presets: LuxurySizePresets.rings
                    )
                    LuxurySizeField(
                        title: "Bracelet Size",
                        text: $braceletSize,
                        presets: LuxurySizePresets.bracelets
                    )
                    LuxurySizeField(
                        title: "Necklace Length",
                        text: $necklaceLength,
                        presets: LuxurySizePresets.necklaces
                    )
                    LuxurySizeField(
                        title: "Wrist Size",
                        text: $wristSize,
                        presets: LuxurySizePresets.wristSizes
                    )
                }

                Section {
                    TextField("e.g. Rings, Necklaces, Bracelets", text: $favCategoriesText, axis: .vertical).lineLimit(2)
                    TextField("e.g. 18K Rose Gold, Platinum", text: $favMetalsText, axis: .vertical).lineLimit(2)
                    TextField("e.g. Diamond, Ruby, Sapphire", text: $favGemstonesText, axis: .vertical).lineLimit(2)
                } header: { Text("Style Preferences") }
                footer: { Text("Separate multiple values with commas.") }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }.tint(.brandCrimson)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard isValid else { showValidationAlert = true; return }
                        saveClient(); dismiss()
                    }
                    .fontWeight(.semibold).tint(.brandCrimson)
                }
            }
            .alert("Missing Information", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter the client's full name before saving.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func saveClient() {
        let now = Date.now
        vm.addClient(MockClientProfile(
            id: UUID(),
            fullName: fullName.trimmingCharacters(in: .whitespaces),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
            privacyConsentGiven: privacyConsentGiven,
            consentDate: privacyConsentGiven ? now : nil,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            createdAt: now, updatedAt: now
        ))
    }
}

// MARK: - Preview

#Preview("iPhone") { ClientelingRootView() }

#Preview("iPad", traits: .fixedLayout(width: 1024, height: 768)) { ClientelingRootView() }
