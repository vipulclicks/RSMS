//
//  TaxFreeDashboardView.swift
//  RSMS
//

import SwiftUI

struct TaxFreeDashboardView: View {
    @Environment(AppViewModel.self) private var appVM
    
    @State private var selectedStoreFilter: String = "All"
    @State private var selectedDateRange: DateRangeFilter = .allTime
    @State private var showExportSheet = false
    @State private var exportData: String = ""
    @State private var showActionSuccessAlert = false
    
    enum DateRangeFilter: String, CaseIterable, Identifiable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case allTime = "All Time"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filters Header
                HStack(spacing: 12) {
                    Picker("Store Filter", selection: $selectedStoreFilter) {
                        Text("All Stores").tag("All")
                        ForEach(appVM.dataStore.stores) { store in
                            Text(store.name).tag(store.id.uuidString)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                    
                    Picker("Date Range", selection: $selectedDateRange) {
                        ForEach(DateRangeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                    
                    Spacer()
                    
                    Button {
                        triggerExport()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.primary)
                            .padding(10)
                            .background(RSMSTheme.surfacePrimary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(RSMSTheme.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // KPIs Grid
                        let metrics = calculatedMetrics
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            kpiMetricCard(title: "Transactions", value: "\(metrics.count)", color: RSMSTheme.primary)
                            kpiMetricCard(title: "Pending Refunds", value: "\(metrics.pending)", color: RSMSTheme.warning)
                            kpiMetricCard(title: "Approved Value", value: "₹\(Int(truncating: metrics.approvedValue as NSDecimalNumber).formatted())", color: RSMSTheme.success)
                            kpiMetricCard(title: "Rejected Count", value: "\(metrics.rejected)", color: RSMSTheme.danger)
                        }
                        
                        // Transaction Details List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Refund Requests")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            
                            if filteredTransactions.isEmpty {
                                ContentUnavailableView(
                                    "No Refund Requests",
                                    systemImage: "doc.text.magnifyingglass",
                                    description: Text("No tax-free transactions match your filters.")
                                )
                                .padding()
                                .frame(height: 200)
                            } else {
                                ForEach(filteredTransactions) { txn in
                                    taxFreeTransactionRow(txn: txn)
                                }
                            }
                        }
                        .padding()
                        .rsmsCard()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Tax-Free Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Action Processed", isPresented: $showActionSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("The request status has been updated and logged successfully.")
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(activityItems: [exportData])
        }
        .task {
            try? await appVM.dataStore.fetchTaxFreeTransactions()
            try? await appVM.dataStore.fetchStores()
            try? await appVM.dataStore.fetchUsers()
        }
    }
    
    // MARK: - Metric Cards
    
    private func kpiMetricCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    // MARK: - Transaction Rows
    
    private func taxFreeTransactionRow(txn: TaxFreeTransaction) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(txn.customerName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Passport: \(txn.passportNumber) | \(txn.countryOfResidence)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle().fill(statusColor(txn.status)).frame(width: 8, height: 8)
                    Text(txn.status.rawValue.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(statusColor(txn.status))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(statusColor(txn.status).opacity(0.12)))
            }
            
            Divider().overlay(RSMSTheme.divider)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VAT/GST Amount")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("₹\(Int(truncating: txn.taxAmount as NSDecimalNumber).formatted())")
                        .font(.caption.bold())
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                Spacer()
                VStack(alignment: .center, spacing: 2) {
                    Text("Refund Value")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("₹\(Int(truncating: txn.refundAmount as NSDecimalNumber).formatted())")
                        .font(.caption.bold())
                        .foregroundStyle(RSMSTheme.success)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Date")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text(txn.transactionDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.bold())
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
            }
            
            if txn.status == .pending && appVM.currentUser?.role == .boutiqueManager {
                Divider().overlay(RSMSTheme.divider)
                
                HStack(spacing: 12) {
                    Button {
                        updateStatus(txnId: txn.id, status: .approved)
                    } label: {
                        Text("Approve")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(RSMSTheme.success)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button {
                        updateStatus(txnId: txn.id, status: .rejected)
                    } label: {
                        Text("Reject")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(RSMSTheme.danger)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(RSMSTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    // MARK: - Helper Methods
    
    private func statusColor(_ status: TaxFreeStatus) -> Color {
        switch status {
        case .pending: return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .rejected: return RSMSTheme.danger
        case .refunded: return RSMSTheme.info
        }
    }
    
    private var filteredTransactions: [TaxFreeTransaction] {
        var list = appVM.dataStore.taxFreeTransactions
        
        // Filter by Store
        if selectedStoreFilter != "All", let storeUUID = UUID(uuidString: selectedStoreFilter) {
            let storeOrders = appVM.dataStore.orders.filter { order in
                if let txn = appVM.dataStore.transactions.first(where: { $0.id == order.transactionId }) {
                    return txn.storeId == storeUUID
                }
                return false
            }
            list = list.filter { txn in
                storeOrders.contains(where: { $0.id == txn.orderId })
            }
        }
        
        // Filter by Date
        let calendar = Calendar.current
        let now = Date()
        list = list.filter { txn in
            switch selectedDateRange {
            case .today:
                return calendar.isDateInToday(txn.transactionDate)
            case .thisWeek:
                if let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now) {
                    return txn.transactionDate >= startOfWeek
                }
                return true
            case .thisMonth:
                if let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now) {
                    return txn.transactionDate >= startOfMonth
                }
                return true
            case .allTime:
                return true
            }
        }
        
        return list.sorted(by: { $0.transactionDate > $1.transactionDate })
    }
    
    struct CalculatedMetrics {
        let count: Int
        let pending: Int
        let approvedValue: Decimal
        let rejected: Int
    }
    
    private var calculatedMetrics: CalculatedMetrics {
        let list = filteredTransactions
        let count = list.count
        let pending = list.filter { $0.status == .pending }.count
        let approvedValue = list.filter { $0.status == .approved || $0.status == .refunded }.reduce(0) { $0 + $1.refundAmount }
        let rejected = list.filter { $0.status == .rejected }.count
        
        return CalculatedMetrics(count: count, pending: pending, approvedValue: approvedValue, rejected: rejected)
    }
    
    private func updateStatus(txnId: UUID, status: TaxFreeStatus) {
        guard let managerId = appVM.currentUser?.id else { return }
        Task {
            try? await appVM.dataStore.updateTaxFreeTransactionStatus(id: txnId, status: status, managerId: managerId)
            showActionSuccessAlert = true
        }
    }
    
    private func triggerExport() {
        let list = filteredTransactions
        var csv = "ID,Customer Name,Passport,Country,Tax,Refund,Status,Date\n"
        for txn in list {
            csv += "\(txn.id.uuidString),\(txn.customerName),\(txn.passportNumber),\(txn.countryOfResidence),\(txn.taxAmount),\(txn.refundAmount),\(txn.status.rawValue),\(txn.transactionDate)\n"
        }
        exportData = csv
        showExportSheet = true
    }
}

// ShareSheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
