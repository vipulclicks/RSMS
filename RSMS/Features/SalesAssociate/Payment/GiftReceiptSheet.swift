//
//  GiftReceiptSheet.swift
//  RSMS
//

import SwiftUI

/// A fully composed gift receipt that is ready to persist once we have a real transactionId.
/// The transactionId is a placeholder UUID until payment completes.
struct PendingGiftReceipt: Identifiable {
    let id: UUID
    let encodedNote: String      // the full GiftReceiptPayload JSON string
    let selectedItemIds: [UUID]  // for display purposes in OrderCompletionView
    let printedAt: Date
}

// Internal only — not persisted as a top-level model
private struct GiftReceiptPayload: Codable {
    let selectedItemIds: [UUID]
    let customerNote: String       // "To: Priya, with love from Rahul"
    let associateName: String
    let associateEmail: String
    let associatePhone: String?
    let storeName: String
    let storeAddress: String
}

struct GiftReceiptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM

    let cartItems: [UniversalCartItem]       // all items in the current cart
    let cart: UniversalCart                   // for storeId
    @Binding var generatedReceipts: [PendingGiftReceipt]  // passed back to PaymentSummaryView

    @State private var selectedItemIds: Set<UUID> = []     // items for the current receipt
    @State private var customerNote: String = ""            // personal note, max 150 chars
    @State private var isGenerating: Bool = false
    @State private var showSuccessBanner: Bool = false
    @State private var assignedItemIds: Set<UUID> = []     // items already on a previous receipt this session

    private var hasRemainingItems: Bool {
        let remainingCount = cartItems.filter { !assignedItemIds.contains($0.id) }.count
        return remainingCount > 0
    }

    var body: some View {
        ZStack(alignment: .top) {
            RSMSTheme.background.ignoresSafeArea()

            NavigationStack {
                Form {
                    Section(header: Text("Items for this receipt").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                        ForEach(cartItems) { item in
                            let product = appVM.dataStore.product(by: item.productId)
                            let isAssigned = assignedItemIds.contains(item.id)
                            let isSelected = selectedItemIds.contains(item.id)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product?.name ?? "Unknown Product")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(isAssigned ? RSMSTheme.textTertiary : RSMSTheme.textPrimary)
                                    Text("Qty: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundStyle(isAssigned ? RSMSTheme.textTertiary : RSMSTheme.textSecondary)
                                }

                                Spacer()

                                if isAssigned {
                                    StatusBadge(text: "Assigned", color: RSMSTheme.success)
                                } else {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(isSelected ? RSMSTheme.primary : RSMSTheme.textTertiary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isAssigned {
                                    if isSelected {
                                        selectedItemIds.remove(item.id)
                                    } else {
                                        selectedItemIds.insert(item.id)
                                    }
                                }
                            }
                        }
                    }

                    Section(header: Text("Recipient & Note").font(.caption.bold()).foregroundStyle(RSMSTheme.textSecondary)) {
                        TextField("To: Recipient (optional personal note)", text: $customerNote)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .onChange(of: customerNote) { _, newValue in
                                if newValue.count > 150 {
                                    customerNote = String(newValue.prefix(150))
                                }
                            }

                        HStack {
                            Spacer()
                            Text("\(customerNote.count) / 150")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }

                    if !generatedReceipts.isEmpty {
                        Section {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Receipts prepared: \(generatedReceipts.count)")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                            }
                            .foregroundStyle(RSMSTheme.success)
                        }
                    }

                    Section {
                        Button {
                            generateReceipt()
                        } label: {
                            HStack(spacing: 8) {
                                if isGenerating {
                                    ProgressView()
                                        .tint(RSMSTheme.cream)
                                }
                                Text("Generate Receipt")
                            }
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedItemIds.isEmpty || isGenerating ? AnyShapeStyle(RSMSTheme.surfaceSecondary) : AnyShapeStyle(RSMSTheme.primaryGradient))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(selectedItemIds.isEmpty || isGenerating)
                        .listRowInsets(EdgeInsets())

                        if hasRemainingItems && !generatedReceipts.isEmpty {
                            Button {
                                let remaining = cartItems.map(\.id).filter { !assignedItemIds.contains($0) }
                                selectedItemIds = Set(remaining)
                                customerNote = ""
                            } label: {
                                Text("Generate Another Receipt")
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RSMSTheme.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .listRowInsets(EdgeInsets())
                            .padding(.top, 12)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Gift Receipt")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(RSMSTheme.primary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if !generatedReceipts.isEmpty {
                            Button("Done") {
                                dismiss()
                            }
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.primary)
                        }
                    }
                }
            }
            .onAppear {
                let unassigned = cartItems.map(\.id).filter { !assignedItemIds.contains($0) }
                selectedItemIds = Set(unassigned)
            }

            if showSuccessBanner {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Gift receipt generated ✓")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(RSMSTheme.success)
                .foregroundStyle(Color.white)
                .clipShape(Capsule())
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
    }

    private func generateReceipt() {
        isGenerating = true
        Task {
            // Small delay to make the UX premium and show the isGenerating loading state
            try? await Task.sleep(nanoseconds: 500_000_000)

            let associateName = appVM.currentUser?.fullName ?? "Sales Associate"
            let associateEmail = appVM.currentUser?.email ?? ""
            let associatePhone = appVM.currentUser?.phone

            let store = cart.storeId.flatMap { appVM.dataStore.store(by: $0) }
            let storeName = store?.name ?? "Maison Lumière"
            let storeAddress = store?.address ?? ""

            let payload = GiftReceiptPayload(
                selectedItemIds: Array(selectedItemIds),
                customerNote: customerNote,
                associateName: associateName,
                associateEmail: associateEmail,
                associatePhone: associatePhone,
                storeName: storeName,
                storeAddress: storeAddress
            )

            do {
                let data = try JSONEncoder().encode(payload)
                let encodedNote = String(data: data, encoding: .utf8) ?? ""
                let pending = PendingGiftReceipt(
                    id: UUID(),
                    encodedNote: encodedNote,
                    selectedItemIds: Array(selectedItemIds),
                    printedAt: .now
                )

                generatedReceipts.append(pending)
                assignedItemIds.formUnion(selectedItemIds)

                let remaining = cartItems.map(\.id).filter { !assignedItemIds.contains($0) }
                selectedItemIds = Set(remaining)
                customerNote = ""

                isGenerating = false

                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccessBanner = true
                }

                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSuccessBanner = false
                    }
                }
            } catch {
                isGenerating = false
                print("Failed to encode payload: \(error)")
            }
        }
    }
}
