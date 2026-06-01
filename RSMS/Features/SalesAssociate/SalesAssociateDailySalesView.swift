//
//  SalesAssociateDailySalesView.swift
//  RSMS
//

import SwiftUI

struct SalesAssociateDailySalesView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let transactions: [Transaction]
    
    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()
            
            if transactions.isEmpty {
                ContentUnavailableView("No Sales Today", systemImage: "indianrupeesign.circle", description: Text("You haven't completed any transactions today."))
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        totalSalesHeader()
                        
                        LazyVStack(spacing: 16) {
                            ForEach(transactions) { txn in
                                transactionCard(txn)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Today's Sales")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func totalSalesHeader() -> some View {
        let totalSales = transactions.reduce(0) { $0 + $1.totalAmount }
        
        return VStack(spacing: 8) {
            Text("Total Sales Amount")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            Text("₹\(Int(totalSales).formatted())")
                .font(.system(size: 34, weight: .heavy))
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
        let timeString = txn.createdAt.formatted(date: .omitted, time: .shortened)
        let commission = appViewModel.dataStore.commissions.first(where: { $0.transactionId == txn.id })?.amount ?? (txn.totalAmount * 0.05)
        
        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clientName)
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(timeString)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("₹\(Int(txn.totalAmount).formatted())")
                        .font(.title3.bold())
                        .foregroundStyle(RSMSTheme.primary)
                    Text(txn.status.rawValue.capitalized)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.success)
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
