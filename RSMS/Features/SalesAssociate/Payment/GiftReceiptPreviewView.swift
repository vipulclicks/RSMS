//
//  GiftReceiptPreviewView.swift
//  RSMS
//

import SwiftUI

struct GiftReceiptPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM

    let giftReceipt: GiftReceipt             // the persisted receipt (has real transactionId)
    let order: Order                          // for transaction ref and purchase date
    let cartItems: [UniversalCartItem]        // full cart items (we filter by selectedItemIds)

    private struct GiftReceiptPayload: Codable {
        let selectedItemIds: [UUID]
        let customerNote: String       // "To: Priya, with love from Rahul"
        let associateName: String
        let associateEmail: String
        let associatePhone: String?
        let storeName: String
        let storeAddress: String
    }

    private func decodePayload(_ note: String?) -> GiftReceiptPayload? {
        guard let note, let data = note.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GiftReceiptPayload.self, from: data)
    }

    private var payload: GiftReceiptPayload? {
        decodePayload(giftReceipt.recipientNote)
    }

    private var selectedItems: [UniversalCartItem] {
        guard let ids = payload?.selectedItemIds else { return cartItems }
        return cartItems.filter { ids.contains($0.id) }
    }

    private var store: Store? {
        guard let storeId = appVM.currentUser?.storeId else { return nil }
        return appVM.dataStore.store(by: storeId)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: order.createdAt)
    }

    private var storeDisplayString: String {
        let name = payload?.storeName ?? store?.name ?? "Maison Lumière"
        let city = store?.city ?? ""
        if city.isEmpty {
            return name
        }
        return "\(name) — \(city)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(RSMSTheme.primary)
                            Text("Maison Lumière")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("Gift Receipt")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        .padding(.top, 16)

                        // Transaction Details
                        VStack(spacing: 12) {
                            detailRow(title: "Reference No.", value: "ORDER-\(order.id.uuidString.prefix(8).uppercased())")
                            detailRow(title: "Purchase Date", value: formattedDate)
                            detailRow(title: "Store", value: storeDisplayString)
                        }
                        .padding()
                        .rsmsCard()

                        // Items Card
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Items")
                            ForEach(selectedItems) { item in
                                let productName = appVM.dataStore.product(by: item.productId)?.name ?? "Unknown Product"
                                HStack {
                                    Text("\(item.quantity)×")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Text(productName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .rsmsCard()

                        // Personal Note Card (if customerNote is non-empty)
                        if let note = payload?.customerNote, !note.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "Personal Note")
                                Text(note)
                                    .font(.body)
                                    .italic()
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .rsmsCard()
                        }

                        // Sales Associate Details
                        if let payload {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assisted by")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                                Text(payload.associateName)
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                if !payload.associateEmail.isEmpty {
                                    Text(payload.associateEmail)
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                                if let phone = payload.associatePhone, !phone.isEmpty {
                                    Text(phone)
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .rsmsCard()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        ShareLink(item: buildShareText()) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(RSMSTheme.primary)
                        }

                        Button {
                            printReceipt()
                        } label: {
                            Image(systemName: "printer")
                                .foregroundStyle(RSMSTheme.primary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.primary)
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(RSMSTheme.textPrimary)
                .fontWeight(.medium)
        }
    }

    private func buildShareText() -> String {
        let ref = order.id.uuidString.prefix(8).uppercased()
        let dateStr = formattedDate
        let storeName = payload?.storeName ?? store?.name ?? "Maison Lumière"
        let storeCity = store?.city ?? ""
        let storeInfo = storeCity.isEmpty ? storeName : "\(storeName), \(storeCity)"

        var text = """
        MAISON LUMIÈRE — GIFT RECEIPT
        Reference: ORDER-\(ref)
        Date: \(dateStr)
        Store: \(storeInfo)

        Items:
        """

        for item in selectedItems {
            let name = appVM.dataStore.product(by: item.productId)?.name ?? "Unknown Product"
            text += "\n• \(item.quantity)× \(name)"
        }

        if let note = payload?.customerNote, !note.isEmpty {
            text += "\n\n\(note)"
        }

        if let payload {
            text += "\n\nAssisted by: \(payload.associateName)"
            if !payload.associateEmail.isEmpty {
                text += "\n\(payload.associateEmail)"
            }
            if let phone = payload.associatePhone, !phone.isEmpty {
                text += "\n\(phone)"
            }
        }

        return text
    }

    private func printReceipt() {
        let formatter = UISimpleTextPrintFormatter(text: buildShareText())
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.outputType = .general
        info.jobName = "Gift Receipt — \(order.id.uuidString.prefix(8).uppercased())"
        controller.printInfo = info
        controller.printFormatter = formatter
        controller.present(animated: true)
    }
}
