//
//  AuditTrailView.swift
//  RSMS
//

import SwiftUI

struct AuditTrailView: View {
    @Environment(AppViewModel.self) private var appVM
    
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var appeared = false
    @State private var isLoading = false
    
    enum FilterOption: String, CaseIterable {
        case all = "All Activity"
        case stock = "Stock Updates"
        case transfers = "Transfers"
        case exceptions = "Exceptions"
    }
    
    var filteredAudits: [AuditTrail] {
        var result = appVM.dataStore.auditTrails
        
        // Category Filter
        switch selectedFilter {
        case .all: break
        case .stock:
            result = result.filter { $0.action.lowercased().contains("stock") || $0.action.lowercased().contains("adjust") }
        case .transfers:
            result = result.filter { $0.action.lowercased().contains("transfer") || $0.action.lowercased().contains("shipped") || $0.action.lowercased().contains("receive") }
        case .exceptions:
            result = result.filter { $0.action.lowercased().contains("variance") || $0.action.lowercased().contains("damage") }
        }
        
        // Search Filter
        if !searchText.isEmpty {
            let lowerSearch = searchText.lowercased()
            result = result.filter {
                $0.action.lowercased().contains(lowerSearch) ||
                ($0.details?.lowercased().contains(lowerSearch) ?? false) ||
                $0.entityType.lowercased().contains(lowerSearch) ||
                $0.entityId.uuidString.lowercased().contains(lowerSearch)
            }
        }
        
        // Sort newest first
        return result.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Fixed Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Inventory Audit Trail")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Review all system-recorded inventory stock activities.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    
                    // Search & Filters
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(RSMSTheme.textTertiary)
                            TextField("Search activities, items, users...", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .tint(RSMSTheme.textPrimary)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                .background(RSMSTheme.background)
                .zIndex(1)
                
                // Content
                if isLoading && appVM.dataStore.auditTrails.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView().tint(RSMSTheme.gold).scaleEffect(1.3)
                        Spacer()
                    }
                } else if filteredAudits.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(RSMSTheme.textTertiary)
                            .padding(.bottom, 8)
                        Text("No audit records found.")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAudits) { audit in
                                auditCard(audit)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationTitle("Audit Trail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAudits()
        }
        .refreshable {
            await loadAudits()
        }
    }
    
    private func loadAudits() async {
        isLoading = true
        if let storeId = appVM.currentStoreId {
            do {
                try await appVM.dataStore.fetchAuditTrails(storeId: storeId)
            } catch {
                print("Error loading audits: \(error)")
            }
        }
        isLoading = false
    }
    
    private func auditCard(_ audit: AuditTrail) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(RSMSTheme.primaryGradient)
                    .frame(width: 40, height: 40)
                Image(systemName: iconFor(action: audit.action))
                    .foregroundStyle(RSMSTheme.cream)
                    .font(.system(size: 16, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(audit.action)
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Spacer()
                    Text(audit.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                
                if let details = audit.details {
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack {
                    Label(audit.entityType, systemImage: "cube.box")
                    Spacer()
                    Label(userName(for: audit.performedBy), systemImage: "person.fill")
                }
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
    
    private func iconFor(action: String) -> String {
        let lower = action.lowercased()
        if lower.contains("stock") || lower.contains("adjust") { return "shippingbox.fill" }
        if lower.contains("transfer") { return "arrow.left.arrow.right" }
        if lower.contains("variance") || lower.contains("exception") { return "exclamationmark.triangle.fill" }
        if lower.contains("cycle") || lower.contains("count") { return "arrow.triangle.2.circlepath" }
        if lower.contains("scan") { return "barcode.viewfinder" }
        if lower.contains("replenishment") { return "truck.box.fill" }
        return "doc.text.fill"
    }
    
    private func userName(for userId: UUID) -> String {
        if let user = appVM.dataStore.users.first(where: { $0.id == userId }) {
            return user.fullName
        }
        return "Unknown User"
    }
}
