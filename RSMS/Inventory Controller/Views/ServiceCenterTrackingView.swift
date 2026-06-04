//
//  ServiceCenterTrackingView.swift
//  RSMS
//
//  Created by Antigravity on 2026-06-03.
//

import SwiftUI

struct ServiceCenterTrackingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = ServiceCenterTrackingViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(AppViewModel.self) var appViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                analyticsOverview
                serviceInventorySection
                recentActivitySection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Service Center Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isShowingNewRequestModal) {
            NewServiceRequestView(viewModel: viewModel)
                .environment(appViewModel)
        }
        .sheet(isPresented: $viewModel.isShowingRequestDetails) {
            if let request = viewModel.selectedRequest {
                ServiceRequestDetailView(request: request, viewModel: viewModel)
                    .environment(appViewModel)
            }
        }
        .task {
            await viewModel.loadData(dataStore: appViewModel.dataStore, storeId: appViewModel.currentStoreId ?? UUID())
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Service Center Tracking")
                    .font(.title2.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            
            Spacer()
            
            Button {
                viewModel.isShowingNewRequestModal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Service Request")
                }
                .font(.subheadline.bold())
                .foregroundStyle(RSMSTheme.cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RSMSTheme.primary)
                .clipShape(Capsule())
                .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Analytics Overview
    
    private var analyticsOverview: some View {
        let columns = horizontalSizeClass == .compact ? 
            [GridItem(.flexible()), GridItem(.flexible())] : 
            [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            
        return LazyVGrid(columns: columns, spacing: 16) {
            analyticsCard(title: "Pending", count: viewModel.pendingRepairsCount(dataStore: appViewModel.dataStore), icon: "hourglass", color: RSMSTheme.warning)
            analyticsCard(title: "In Service", count: viewModel.inServiceCount(dataStore: appViewModel.dataStore), icon: "wrench.and.screwdriver.fill", color: RSMSTheme.gold)
            analyticsCard(title: "Ready", count: viewModel.readyForReturnCount(dataStore: appViewModel.dataStore), icon: "shippingbox.fill", color: RSMSTheme.info)
            analyticsCard(title: "Completed", count: viewModel.completedCount(dataStore: appViewModel.dataStore), icon: "checkmark.seal.fill", color: RSMSTheme.success)
        }
    }
    
    private func analyticsCard(title: String, count: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .padding(10)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(count)")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .textCase(.uppercase)
            }
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: RSMSTheme.border, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Service Inventory Table/List
    
    private var serviceInventorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ACTIVE REPAIRS")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        TextField("Search...", text: $viewModel.searchText)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 200)
                }
            }
            
            if horizontalSizeClass == .compact {
                // Mobile: Stacked Cards
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredRequests(dataStore: appViewModel.dataStore)) { request in
                        mobileRequestCard(request)
                    }
                }
            } else {
                // iPad: Table
                desktopRequestTable
            }
        }
    }
    
    private var desktopRequestTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ID").frame(width: 80, alignment: .leading)
                Text("Product").frame(maxWidth: .infinity, alignment: .leading)
                Text("Service Center").frame(width: 150, alignment: .leading)
                Text("Status").frame(width: 120, alignment: .leading)
                Text("Expected").frame(width: 100, alignment: .leading)
                Text("Action").frame(width: 80, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(RSMSTheme.textTertiary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RSMSTheme.surfaceSecondary)
            
            Divider().background(RSMSTheme.divider)
            
            // Rows
            ForEach(viewModel.filteredRequests(dataStore: appViewModel.dataStore)) { request in
                HStack {
                    Text(request.requestId)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.productName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text(request.sku)
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(request.serviceCenterName)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(width: 150, alignment: .leading)
                    
                    statusChip(viewModel.getStatus(for: request))
                        .frame(width: 120, alignment: .leading)
                    
                    Text(request.expectedReturnDate?.formatted(date: .numeric, time: .omitted) ?? "TBD")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(width: 100, alignment: .leading)
                    
                    Button {
                        viewModel.selectedRequest = request
                        viewModel.isShowingRequestDetails = true
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(RSMSTheme.primary)
                    }
                    .accessibilityLabel("View Request Details")
                    .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider().background(RSMSTheme.divider)
            }
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    private func mobileRequestCard(_ request: ServiceRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(request.requestId)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RSMSTheme.textTertiary)
                Spacer()
                statusChip(viewModel.getStatus(for: request))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.productName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("SKU: \(request.sku) • SN: \(request.serialNumber)")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            
            Divider().background(RSMSTheme.divider)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Service Center")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(request.serviceCenterName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Expected")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(request.expectedReturnDate?.formatted(date: .numeric, time: .omitted) ?? "TBD")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
        .onTapGesture {
            viewModel.selectedRequest = request
            viewModel.isShowingRequestDetails = true
        }
    }
    
    private func statusChip(_ status: ServiceRequestStatus) -> some View {
        Text(status.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.12))
            .clipShape(Capsule())
    }
    
    // MARK: - Recent Activity
    
    private var recentActivitySection: some View {
        let activities = viewModel.sortedActivities(dataStore: appViewModel.dataStore)
        return VStack(alignment: .leading, spacing: 16) {
            Text("RECENT ACTIVITIES")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.gold)
            
            if activities.isEmpty {
                Text("No recent activity.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        let stage = viewModel.getStage(for: activity)
                        HStack(spacing: 16) {
                            Circle()
                                .fill(stage.color.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .fill(stage.color)
                                        .frame(width: 10, height: 10)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(activity.requestId)
                                        .font(.caption.monospacedDigit().bold())
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Text(activity.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                
                                Text("Updated to **\(stage.rawValue)** at \(activity.serviceCenter)")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        if index < activities.count - 1 {
                            Divider().background(RSMSTheme.divider).padding(.leading, 64)
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
            }
        }
    }
}

// MARK: - Form Modal

struct NewServiceRequestView: View {
    @Bindable var viewModel: ServiceCenterTrackingViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(AppViewModel.self) var appViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var isShowingScanner = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                RSMSTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header info
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Request Date")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Text(Date().formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Section 1: Product Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Product Details")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "magnifyingglass").foregroundStyle(RSMSTheme.textTertiary)
                                    TextField("Search product by SKU or name...", text: $viewModel.newProductSearch)
                                    Button {
                                        isShowingScanner = true
                                    } label: {
                                        Image(systemName: "barcode.viewfinder")
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                    }
                                    .accessibilityLabel("Scan Barcode")
                                }
                                .padding()
                                .background(RSMSTheme.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                                
                                if !viewModel.searchResults.isEmpty && viewModel.selectedProduct == nil {
                                    VStack(spacing: 0) {
                                        ForEach(viewModel.searchResults) { product in
                                            Button {
                                                withAnimation(reduceMotion ? nil : .default) {
                                                    viewModel.selectedProduct = product
                                                    viewModel.newProductSearch = ""
                                                    viewModel.newSku = product.sku
                                                    if viewModel.availableCategories.contains(product.category) {
                                                        viewModel.newCategory = product.category
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    Text(product.name)
                                                        .foregroundStyle(RSMSTheme.textPrimary)
                                                    Spacer()
                                                    Text(product.sku)
                                                        .font(.caption.monospaced())
                                                        .foregroundStyle(RSMSTheme.textTertiary)
                                                }
                                                .padding()
                                            }
                                            if product.id != viewModel.searchResults.last?.id { Divider() }
                                        }
                                    }
                                    .background(RSMSTheme.surfacePrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                                }
                                
                                VStack(spacing: 0) {
                                    if let p = viewModel.selectedProduct {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(p.name).font(.headline).foregroundStyle(RSMSTheme.textPrimary).accessibilityAddTraits(.isHeader)
                                            }
                                            Spacer()
                                            Button {
                                                withAnimation(reduceMotion ? nil : .default) {
                                                    viewModel.selectedProduct = nil
                                                    viewModel.newSku = ""
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill").foregroundStyle(RSMSTheme.textTertiary)
                                            }
                                        }
                                        .padding()
                                        
                                        Divider().padding(.leading)
                                    }
                                    
                                    TextField("SKU", text: $viewModel.newSku)
                                        .padding()
                                    Divider().padding(.leading)
                                    
                                    TextField("Serial Number", text: $viewModel.newSerialNumber)
                                        .padding()
                                    Divider().padding(.leading)
                                    
                                    HStack {
                                        Text("Category").foregroundStyle(RSMSTheme.textPrimary)
                                        Spacer()
                                        Picker("Category", selection: $viewModel.newCategory) {
                                            ForEach(viewModel.availableCategories, id: \.self) { cat in
                                                Text(cat).tag(cat)
                                            }
                                        }
                                        .tint(RSMSTheme.gold)
                                    }
                                    .padding()
                                    
                                    Divider().padding(.leading)
                                    
                                    Toggle("Under Warranty", isOn: $viewModel.newIsUnderWarranty)
                                        .padding()
                                        .tint(RSMSTheme.gold)
                                }
                                .background(RSMSTheme.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                            }
                        }
                        
                        // Section 2: Service Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Service Details")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Issue Type").foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Picker("Issue Type", selection: $viewModel.newIssueType) {
                                        ForEach(ServiceIssueType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .tint(RSMSTheme.gold)
                                }
                                .padding()
                                
                                Divider().padding(.leading)
                                
                                HStack {
                                    Text("Priority").foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Picker("Priority", selection: $viewModel.newPriority) {
                                        ForEach(ServicePriority.allCases) { priority in
                                            Text(priority.rawValue).tag(priority)
                                        }
                                    }
                                    .tint(RSMSTheme.gold)
                                }
                                .padding()
                                
                                Divider().padding(.leading)
                                
                                VStack(alignment: .leading) {
                                    Text("Issue Description")
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .padding(.horizontal)
                                        .padding(.top)
                                    TextEditor(text: $viewModel.newIssueDescription)
                                        .frame(minHeight: 100)
                                        .padding(.horizontal)
                                        .scrollContentBackground(.hidden)
                                }
                            }
                            .background(RSMSTheme.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                        }
                        
                        // Bottom Padding for submit button
                        Spacer().frame(height: 100)
                    }
                    .padding(24)
                }
                
                // Sticky Submit Button
                VStack {
                    Divider()
                    Button {
                        Task {
                            await viewModel.submitNewRequest(
                                dataStore: appViewModel.dataStore,
                                storeId: appViewModel.currentStoreId ?? UUID()
                            )
                        }
                    } label: {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView().tint(RSMSTheme.background)
                            } else {
                                Text("Submit Request")
                                    .font(.headline.weight(.bold))
                            }
                        }
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.isSubmitting)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(RSMSTheme.background.opacity(0.95))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NEW SERVICE REQUEST")
                        .font(.system(.headline, design: .serif, weight: .light))
                        .tracking(4)
                        .foregroundStyle(RSMSTheme.gold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                // Mock scanner view
                NavigationStack {
                    VStack {
                        Image(systemName: "barcode.viewfinder")
                            .font(.largeTitle)
                            .foregroundStyle(RSMSTheme.primary)
                        Text("Camera Scanner")
                            .font(.headline)
                            .padding()
                        Text("Point camera at product barcode")
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { isShowingScanner = false }
                        }
                    }
                }
            }
        }
        .onAppear {
            if viewModel.products.isEmpty {
                viewModel.products = appViewModel.dataStore.products
                let cats = Array(Set(viewModel.products.map { $0.category })).sorted()
                if !cats.isEmpty {
                    viewModel.availableCategories = cats
                }
            }
        }
        .alert("Error Submitting Request", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
}

// MARK: - Request Detail View

struct ServiceRequestDetailView: View {
    let request: ServiceRequest
    @Bindable var viewModel: ServiceCenterTrackingViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(AppViewModel.self) var appViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(request.productName)
                            .font(.title2.bold())
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("SKU: \(request.sku) • SN: \(request.serialNumber)")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    
                    // Request Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Service Details")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        
                        VStack(spacing: 0) {
                            detailRow(title: "Request ID", value: request.requestId)
                            Divider().padding(.leading)
                            detailRow(title: "Status", value: request.status)
                            Divider().padding(.leading)
                            detailRow(title: "Issue Type", value: request.issueType)
                            Divider().padding(.leading)
                            detailRow(title: "Priority", value: request.priority)
                            Divider().padding(.leading)
                            detailRow(title: "Service Center", value: request.serviceCenterName)
                            Divider().padding(.leading)
                            detailRow(title: "Expected Return", value: request.expectedReturnDate?.formatted(date: .abbreviated, time: .omitted) ?? "TBD")
                        }
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                    }
                    
                    if !request.issueDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Description")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text(request.issueDescription)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RSMSTheme.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                        }
                    }
                    
                    Spacer().frame(height: 40)
                }
                .padding(24)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        let allowedStatuses: [ServiceRequestStatus] = [.pending, .inService, .readyForReturn, .completed]
                        ForEach(allowedStatuses, id: \.self) { status in
                            if status.rawValue != request.status {
                                Button(status.rawValue) {
                                    Task {
                                        await viewModel.updateRequestStatus(
                                            request: request,
                                            newStatus: status,
                                            dataStore: appViewModel.dataStore
                                        )
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Update Status")
                                .font(.subheadline.bold())
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(RSMSTheme.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(RSMSTheme.primary)
                }
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(RSMSTheme.textTertiary)
            Spacer()
            Text(value)
                .foregroundStyle(RSMSTheme.textPrimary)
                .fontWeight(.medium)
        }
        .padding()
    }
}
