//
//  InspectionQueueView.swift
//  RSMS
//

import SwiftUI

struct InspectionQueueView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var isRefreshing = false
    @State private var selectedRequest: InspectionRequestType?
    
    init() {}
    
    var body: some View {
        List {
            let pendingReturns = appVM.dataStore.posReturnRequests.filter { $0.status == .inspectionPending }
            let pendingExchanges = appVM.dataStore.posExchangeRequests.filter { $0.status == .inspectionPending }
            
            Section("Pending Returns") {
                if pendingReturns.isEmpty {
                    Text("No returns pending inspection.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(pendingReturns) { req in
                        Button {
                            selectedRequest = .returnRequest(req)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appVM.dataStore.productName(for: req.productId))
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text("Order ID: \(req.orderId.uuidString.prefix(8).uppercased())")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Qty: \(req.quantity)")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text(req.reason)
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(RSMSTheme.surfacePrimary)
                    }
                }
            }
            
            Section("Pending Exchanges") {
                if pendingExchanges.isEmpty {
                    Text("No exchanges pending inspection.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(pendingExchanges) { req in
                        Button {
                            selectedRequest = .exchangeRequest(req)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(appVM.dataStore.productName(for: req.originalProductId)) ➔ \(appVM.dataStore.productName(for: req.replacementProductId))")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text("Order ID: \(req.orderId.uuidString.prefix(8).uppercased())")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Qty: \(req.quantity)")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text(req.reason)
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(RSMSTheme.surfacePrimary)
                    }
                }
            }
        }
        .navigationTitle("Inspection Queue")
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationDestination(item: $selectedRequest) { reqType in
            InspectionDetailView(request: reqType)
        }

        .task {
            await appVM.dataStore.fetchPOSReturnsExchanges()
        }
    }
}
