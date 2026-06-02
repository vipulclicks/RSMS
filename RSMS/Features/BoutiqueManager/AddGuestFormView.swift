import SwiftUI

struct AddGuestFormView: View {
    let eventId: UUID
    @Bindable var viewModel: BoutiqueEventsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    @State private var searchText = ""
    @State private var selectedTier: VIPTier? = nil
    @State private var isSubmitting = false
    @State private var isLoadingClients = false
    
    var filteredClients: [ClientProfile] {
        var clients = appVM.dataStore.clients
        
        if let tier = selectedTier {
            clients = clients.filter { $0.vipTier == tier }
        }
        
        if !searchText.isEmpty {
            clients = clients.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return clients.sorted { $0.fullName < $1.fullName }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All Tiers", isSelected: selectedTier == nil) {
                            selectedTier = nil
                        }
                        
                        ForEach(VIPTier.allCases, id: \.self) { tier in
                            FilterChip(title: tier.rawValue.capitalized, isSelected: selectedTier == tier) {
                                selectedTier = tier
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(RSMSTheme.surfacePrimary)
                
                Divider()
                
                // Client List
                if isLoadingClients {
                    Spacer()
                    ProgressView("Loading Clients...")
                    Spacer()
                } else if appVM.dataStore.clients.isEmpty {
                    ContentUnavailableView("No Clients", systemImage: "person.crop.circle.badge.xmark", description: Text("There are no client profiles in the database."))
                } else if filteredClients.isEmpty {
                    ContentUnavailableView("No Matches", systemImage: "magnifyingglass", description: Text("No clients match your search and filter criteria."))
                } else {
                    List {
                        ForEach(filteredClients) { client in
                            Button {
                                submitGuest(clientId: client.id)
                            } label: {
                                ClientSelectionRow(client: client)
                            }
                            .buttonStyle(.plain)
                            .disabled(isSubmitting)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add VIP Guest")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search by name or email")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RSMSTheme.danger)
                    .disabled(isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .padding()
                            .background(Material.ultraThin)
                            .cornerRadius(8)
                    }
                }
            }
            .task {
                if appVM.dataStore.clients.isEmpty {
                    isLoadingClients = true
                    try? await appVM.dataStore.fetchClients()
                    isLoadingClients = false
                }
            }
        }
    }
    
    private func submitGuest(clientId: UUID) {
        isSubmitting = true
        Task {
            await viewModel.addGuest(to: eventId, clientId: clientId, dataStore: appVM.dataStore)
            await viewModel.fetchInvitations(for: eventId, dataStore: appVM.dataStore)
            dismiss()
        }
    }
}

// MARK: - Subcomponents

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? RSMSTheme.cream : RSMSTheme.textSecondary)
                .background(isSelected ? RSMSTheme.primaryDark : RSMSTheme.surfaceSecondary)
                .clipShape(Capsule())
        }
    }
}

struct ClientSelectionRow: View {
    let client: ClientProfile
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.surfaceSecondary)
                    .frame(width: 44, height: 44)
                Text(String(client.fullName.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.primaryDark)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                if let email = client.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            
            Spacer()
            
            Text(client.vipTier.rawValue.capitalized)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tierColor(for: client.vipTier))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tierColor(for: client.vipTier).opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
    
    private func tierColor(for tier: VIPTier) -> Color {
        switch tier {
        case .standard: return RSMSTheme.textSecondary
        case .silver: return Color.gray
        case .gold: return RSMSTheme.gold
        case .platinum: return Color.blue
        case .prive: return RSMSTheme.primaryDark
        case .vip: return RSMSTheme.primary
        }
    }
}
