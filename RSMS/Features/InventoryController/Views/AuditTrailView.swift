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
        case reconciliations = "Reconciliations"
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
        case .reconciliations:
            result = result.filter { $0.action.lowercased() == "stock adjusted" && ($0.details?.contains("prev:") ?? false) }
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
                        .font(.system(.title, design: .rounded).weight(.bold))
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
                        .frame(minHeight: 44)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
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
                            .font(.largeTitle)
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
                        LazyVStack(spacing: 0) {
                            ForEach(filteredAudits) { audit in
                                auditCard(audit)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .padding(.top, 12)
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
        let isRecon = audit.action == "Stock Adjusted" && (audit.details?.contains("prev:") ?? false)
        
        return VStack(spacing: 0) {
            Rectangle()
                .fill(RSMSTheme.divider)
                .frame(height: 0.5)
                .padding(.horizontal, 14)

            HStack(alignment: .top, spacing: 12) {
                // Timeline dot
                VStack(spacing: 4) {
                    Circle()
                        .fill(isRecon ? RSMSTheme.gold : RSMSTheme.textTertiary)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(RSMSTheme.divider)
                        .frame(width: 2)
                }
                .frame(width: 10)
                .padding(.top, 4)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        let name = userName(for: audit.performedBy.uuidString)
                        Text(name ?? audit.action)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Spacer()
                        Text(audit.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if userName(for: audit.performedBy.uuidString) != nil {
                            Text("\(audit.action)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        
                        if isRecon {
                            reconciliationDetails(audit.details)
                        } else if let details = audit.details {
                            Text(details)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
    
    @ViewBuilder
    private func reconciliationDetails(_ detailsString: String?) -> some View {
        if let details = detailsString {
            // Expected format: "SKU: 12345 · Product Name | prev: 10 | new: 15 | reason: Miscounted"
            let parts = details.components(separatedBy: " | ")
            if parts.count >= 1 {
                Text("Reconciled **\(parts[0])**")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            let reason = parts.first(where: { $0.hasPrefix("reason: ") })?.dropFirst(8) ?? "Unknown"
            Text("Reason: \(reason)")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
            
            let prev = parts.first(where: { $0.hasPrefix("prev: ") })?.dropFirst(6) ?? "0"
            let new = parts.first(where: { $0.hasPrefix("new: ") })?.dropFirst(5) ?? "0"
            
            HStack(spacing: 6) {
                Text(String(prev))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.danger)
                    .strikethrough()
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
                Text(String(new))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.success)
            }
        }
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
    
    private func userName(for userId: String) -> String? {
        // Find user by ID. If not found, check if it's "System"
        if userId == "System" { return "System" }
        if let uuid = UUID(uuidString: userId), let user = appVM.dataStore.users.first(where: { $0.id == uuid }) {
            return user.fullName
        }
        return nil
    }
}
