//
//  SalesAssociateAllTransactionsView.swift
//  RSMS
//

import SwiftUI

//
//  SalesAssociateAllTransactionsView.swift
//  RSMS
//

import SwiftUI

enum SalesFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case instore = "In Store"
    case online = "Online"
    
    var id: String { rawValue }
}

struct SalesAssociateAllTransactionsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let transactions: [Transaction]
    
    @State private var selectedDate: Date = Date()
    @State private var selectedFilter: SalesFilter = .all
    @State private var showDatePickerPopover: Bool = false
    
    private var filteredTransactions: [Transaction] {
        transactions.filter { txn in
            Calendar.current.isDate(txn.createdAt, inSameDayAs: selectedDate)
        }.filter { txn in
            let isOnline = appViewModel.dataStore.tenders.contains(where: {
                $0.transactionId == txn.id && ($0.reference?.contains("ONLINE") == true || $0.reference == "online")
            }) || appViewModel.dataStore.checkoutSessions.contains(where: {
                $0.cartId == txn.cartId && $0.paymentMethod == .online
            })
            
            switch selectedFilter {
            case .all: return true
            case .instore: return !isOnline
            case .online: return isOnline
            }
        }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    totalSalesHeader()
                    
                    filterPills()
                    
                    if filteredTransactions.isEmpty {
                        Spacer().frame(height: 40)
                        ContentUnavailableView("No Transactions", systemImage: "indianrupeesign.circle", description: Text("No transactions match the selected date or filters."))
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTransactions) { txn in
                                transactionCard(txn)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Total Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDatePickerPopover.toggle()
                } label: {
                    Image(systemName: "calendar").accessibilityLabel("Action")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }
                .popover(isPresented: $showDatePickerPopover) {
                    VStack(spacing: 12) {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .tint(RSMSTheme.primary)
                        .frame(width: 320, height: 320)
                        .padding()
                        
                        Button("Done") {
                            showDatePickerPopover = false
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(RSMSTheme.primary)
                        .padding(.bottom, 12)
                    }
                }
            }
        }
        .task {
            // Fetch checkout sessions & tenders to ensure online status reference is cached correctly
            try? await appViewModel.dataStore.fetchCheckoutSessions()
            for txn in transactions {
                try? await appViewModel.dataStore.fetchTenders(transactionId: txn.id)
            }
        }
    }    
    private func filterPills() -> some View {
        HStack(spacing: 12) {
            ForEach(SalesFilter.allCases) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(selectedFilter == filter ? .white : RSMSTheme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? RSMSTheme.primary : RSMSTheme.surfacePrimary)
                                .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
    
    private func totalSalesHeader() -> some View {
        let totalSales = filteredTransactions.reduce(0) { $0 + $1.totalAmount }
        
        return VStack(spacing: 8) {
            Text("Grand Total Sales Amount")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            Text("₹\(Int(totalSales).formatted())")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(RSMSTheme.primary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.primary.opacity(0.05))
        )
    }
    
    private func transactionCard(_ txn: Transaction) -> some View {
        let clientName = appViewModel.dataStore.clientName(for: txn.clientId ?? UUID())
        let dateString = txn.createdAt.formatted(date: .abbreviated, time: .shortened)
        let commission = appViewModel.dataStore.commissions.first(where: { $0.transactionId == txn.id })?.amount ?? (txn.totalAmount * 0.05)
        
        let isOnline = appViewModel.dataStore.tenders.contains(where: {
            $0.transactionId == txn.id && ($0.reference?.contains("ONLINE") == true || $0.reference == "online")
        }) || appViewModel.dataStore.checkoutSessions.contains(where: {
            $0.cartId == txn.cartId && $0.paymentMethod == .online
        })
        
        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clientName)
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(dateString)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("₹\(Int(txn.totalAmount).formatted())")
                        .font(.title3.bold())
                        .foregroundStyle(RSMSTheme.primary)
                    HStack(spacing: 4) {
                        if isOnline {
                            Text("ONLINE")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RSMSTheme.primary.opacity(0.15))
                                .foregroundStyle(RSMSTheme.primary)
                                .cornerRadius(4)
                        }
                        Text(txn.status.rawValue.capitalized)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(txn.status == .completed ? RSMSTheme.success : RSMSTheme.warning)
                    }
                }
            }
            
            Divider().background(RSMSTheme.divider)
            
            HStack {
                Text("Commission Earned")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Spacer()
                Text("₹\(Int(commission).formatted())")
                    .font(.subheadline.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 2)
    }
}
