//
//  InventorySourcingRequestListView.swift
//  RSMS
//

import SwiftUI

struct InventorySourcingRequestListView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var sourcingVM = InventorySourcingViewModel()
    @State private var selectedSegment = 0 // 0 = Pending, 1 = Active, 2 = Completed
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Adapt view based on user role
                let role = appViewModel.currentUser?.role ?? .salesAssociate
                
                if role == .boutiqueManager {
                    analyticsHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }
                
                // Segmented Control
                Picker("Filter Requests", selection: $selectedSegment) {
                    Text("Pending").tag(0)
                    Text("Active").tag(1)
                    Text("Completed").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                if sourcingVM.isLoading {
                    Spacer()
                    ProgressView("Loading Sourcing Requests...")
                        .tint(RSMSTheme.primary)
                    Spacer()
                } else {
                    let filtered = currentFilteredRequests(role: role)
                    
                    if filtered.isEmpty {
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filtered) { request in
                                    NavigationLink(destination: InventorySourcingRequestDetailView(request: request, sourcingVM: sourcingVM)) {
                                        requestCard(request)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
        .navigationTitle(navigationTitleForRole)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await sourcingVM.load(dataStore: appViewModel.dataStore)
        }
        .refreshable {
            await sourcingVM.load(dataStore: appViewModel.dataStore)
        }
    }
    
    // MARK: - Adapter Helpers
    
    private var navigationTitleForRole: String {
        switch appViewModel.currentUser?.role {
        case .inventoryController: return "Sourcing Inbox"
        case .boutiqueManager: return "Sourcing Monitor"
        default: return "Sourcing Requests"
        }
    }
    
    private func currentFilteredRequests(role: UserRole) -> [InventorySourcingRequest] {
        let associateId: UUID? = (role == .salesAssociate) ? appViewModel.currentUser?.id : nil
        
        var list: [InventorySourcingRequest] = []
        switch selectedSegment {
        case 0:
            list = sourcingVM.pendingRequests(for: associateId)
        case 1:
            list = sourcingVM.activeRequests(for: associateId)
        case 2:
            list = sourcingVM.completedRequests(for: associateId)
        default:
            list = []
        }
        
        // Boutique manager filters by their own store
        if role == .boutiqueManager, let storeId = appViewModel.currentUser?.storeId {
            list = list.filter { $0.requestingStoreId == storeId }
        }
        
        return list
    }
    
    // MARK: - Subviews
    
    private var analyticsHeader: some View {
        let role = appViewModel.currentUser?.role ?? .salesAssociate
        let allForStore = sourcingVM.requests.filter { req in
            role != .boutiqueManager || req.requestingStoreId == appViewModel.currentUser?.storeId
        }
        let pendingCount = allForStore.filter { $0.status == .requested || $0.status == .searching || $0.status == .stockFound }.count
        let activeCount = allForStore.filter { $0.status == .transferInitiated || $0.status == .inTransit || $0.status == .received || $0.status == .available }.count
        let completedCount = allForStore.filter { $0.status == .completed }.count
        
        return HStack(spacing: 12) {
            analyticsCard(title: "PENDING", count: pendingCount, color: RSMSTheme.info)
            analyticsCard(title: "ACTIVE", count: activeCount, color: RSMSTheme.warning)
            analyticsCard(title: "COMPLETED", count: completedCount, color: RSMSTheme.success)
        }
    }
    
    private func analyticsCard(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.textTertiary)
            
            Text("No requests found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            
            Text("No sourcing requests match this filter.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
        )
        .padding(.horizontal, 24)
    }
    
    private func requestCard(_ request: InventorySourcingRequest) -> some View {
        let storeName = appViewModel.dataStore.storeName(for: request.requestingStoreId)
        let requesterName = appViewModel.dataStore.userName(for: request.salesAssociateId)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                        .foregroundStyle(RSMSTheme.primary)
                    Text(request.productName)
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle().fill(request.status.color).frame(width: 8, height: 8)
                    Text(request.status.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(request.status.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(request.status.color.opacity(0.1)))
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Requested Qty")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("\(request.requestedQuantity) unit\(request.requestedQuantity == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Store")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text(storeName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text(request.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
            }
            
            if appViewModel.currentUser?.role != .salesAssociate {
                Divider().overlay(RSMSTheme.divider)
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .font(.caption)
                    Text("Requested by \(requesterName)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfacePrimary)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }
}
