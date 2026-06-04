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

    @State private var generatedPDFURL: URL? = nil
    @State private var showShareSheet = false

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
                                .font(.largeTitle)
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
                        Button {
                            shareReceipt()
                        } label: {
                            Image(systemName: "square.and.arrow.up").accessibilityLabel("Share")
                                .foregroundStyle(RSMSTheme.primary)
                        }

                        Button {
                            printReceipt()
                        } label: {
                            Image(systemName: "printer").accessibilityLabel("Print")
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
            .sheet(isPresented: $showShareSheet) {
                if let url = generatedPDFURL {
                    GiftReceiptShareSheet(activityItems: [url])
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

    // MARK: - PDF Rendering / Printing / Sharing

    private var giftReceiptPrintView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Maison Lumière")
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Gift Receipt")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            .padding(.top, 16)
            
            Divider()

            // Transaction Details
            VStack(spacing: 8) {
                HStack {
                    Text("Reference No.")
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                    Text("ORDER-\(order.id.uuidString.prefix(8).uppercased())")
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .fontWeight(.medium)
                }
                HStack {
                    Text("Purchase Date")
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                    Text(formattedDate)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .fontWeight(.medium)
                }
                HStack {
                    Text("Store")
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Spacer()
                    Text(storeDisplayString)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .fontWeight(.medium)
                }
            }

            Divider()

            // Items
            VStack(alignment: .leading, spacing: 10) {
                Text("Items")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
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

            // Personal Note
            if let note = payload?.customerNote, !note.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Personal Note")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(note)
                        .font(.body)
                        .italic()
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Sales Associate Details
            if let payload {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(30)
        .background(Color.white)
    }

    @MainActor
    private func generatePDF() -> URL? {
        let printView = giftReceiptPrintView
            .frame(width: 612, height: 792) // Letter size
            .padding(40)
            .background(Color.white)
        
        let renderer = ImageRenderer(content: printView)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("GiftReceipt-\(order.id.uuidString.prefix(8)).pdf")
        
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: CGSize(width: 612, height: 792))
            guard let pdfContext = CGContext(tempURL as CFURL, mediaBox: &box, nil) else { return }
            pdfContext.beginPDFPage(nil)
            
            let dx = (box.size.width - size.width) / 2
            let dy = (box.size.height - size.height) / 2
            pdfContext.translateBy(x: dx, y: dy)
            
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        return tempURL
    }

    private func shareReceipt() {
        if let url = generatePDF() {
            generatedPDFURL = url
            showShareSheet = true
        }
    }

    private func printReceipt() {
        if let url = generatePDF() {
            let printController = UIPrintInteractionController.shared
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = "Gift Receipt \(order.id.uuidString.prefix(8))"
            printInfo.outputType = .general
            printController.printInfo = printInfo
            printController.printingItem = url
            
            printController.present(animated: true) { _, _, _ in }
        }
    }
}

struct GiftReceiptShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

