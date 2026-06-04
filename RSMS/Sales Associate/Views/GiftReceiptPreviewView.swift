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
                    VStack(spacing: 20) {
                        giftReceiptPaperView
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Gift Receipt")
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

    // MARK: - Slip Helpers
    
    private var slipDivider: some View {
        Rectangle()
            .fill(Color(red: 0.8, green: 0.75, blue: 0.68))
            .frame(minHeight: 0.75)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color(red: 0.45, green: 0.05, blue: 0.1))
            .tracking(1.5)
    }

    private func labeledValue(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.gray)
            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.black)
        }
    }

    private func infoCell(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.gray)
                .tracking(0.5)
            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    // MARK: - Slip Paper View
    private var giftReceiptPaperView: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── HEADER ──────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MAISON LUMIÈRE")
                        .font(.headline.weight(.black))
                        .tracking(3)
                        .foregroundStyle(.black)
                    Text("Luxury Boutique")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .tracking(1)
                    if let store = store {
                        Spacer().frame(height: 6)
                        Text(storeDisplayString)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
                        Text(store.address)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        if let phone = store.phone {
                            Text("Tel: \(phone)")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    } else if let payload = payload {
                        Spacer().frame(height: 6)
                        Text(storeDisplayString)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
                        Text(payload.storeAddress)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("GIFT RECEIPT")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(red: 0.45, green: 0.05, blue: 0.1))
                        .tracking(1)
                    Group {
                        labeledValue("Order", order.id.uuidString.prefix(8).uppercased())
                        labeledValue("Date", formattedDate)
                    }
                }
            }
            .padding(.bottom, 16)

            slipDivider

            // ── STORE / RECIPIENT ─────────────────────────────────
            HStack(alignment: .top, spacing: 24) {
                // Store
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("STORE")
                    if let store = store {
                        Text(store.name)
                            .font(.caption2.weight(.bold)).foregroundStyle(.black)
                        Text(store.address)
                            .font(.caption2).foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                    } else if let payload = payload {
                        Text(payload.storeName)
                            .font(.caption2.weight(.bold)).foregroundStyle(.black)
                        Text(payload.storeAddress)
                            .font(.caption2).foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                    } else {
                        Text("Store details unavailable")
                            .font(.caption2).foregroundStyle(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1)

                // Recipient / Gift
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("GIFT NOTE")
                    if let note = payload?.customerNote, !note.isEmpty {
                        Text(note)
                            .font(.caption2.italic())
                            .foregroundStyle(.black)
                    } else {
                        Text("A gift for you")
                            .font(.caption2.italic())
                            .foregroundStyle(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 14)

            slipDivider

            // ── INFO ROW ───────────────────────────────────
            HStack(spacing: 0) {
                infoCell(label: "ASSOCIATE", value: payload?.associateName ?? "Staff")
                Divider().frame(height: 36)
                infoCell(label: "TOTAL ITEMS", value: "\(selectedItems.reduce(0) { $0 + $1.quantity })")
            }
            .padding(.vertical, 10)
            .background(Color(red: 0.97, green: 0.96, blue: 0.94))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            slipDivider

            // ── ITEMS TABLE ─────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                sectionHeader("GIFT ITEMS")
                    .padding(.bottom, 4)

                // Table Header
                HStack {
                    Text("DESCRIPTION").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("SKU").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 90, alignment: .leading)
                    Text("QTY").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 40, alignment: .center)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
                .background(Color.black)

                // Table Rows
                ForEach(Array(selectedItems.enumerated()), id: \.element.id) { index, item in
                    let product = appVM.dataStore.product(by: item.productId)
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(product?.name ?? appVM.dataStore.productName(for: item.productId))
                                .font(.caption2.weight(.medium)).foregroundStyle(.black)
                            if let category = product?.category {
                                Text(category)
                                    .font(.caption2).foregroundStyle(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(product?.sku ?? "—")
                            .font(.system(.caption2, design: .monospaced)).foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
                            .frame(width: 90, alignment: .leading)

                        Text("\(item.quantity)")
                            .font(.caption2.weight(.bold)).foregroundStyle(.black)
                            .frame(width: 40, alignment: .center)
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 6)
                    .background(index % 2 == 0 ? Color.white : Color(red: 0.97, green: 0.97, blue: 0.97))

                    Divider().overlay(Color.gray.opacity(0.15))
                }
            }
            .padding(.vertical, 14)
            
            slipDivider

            // ── FOOTER / BARCODE ──────────────────────────────────────────
            Text("This receipt can be used for returns or exchanges within 14 days of purchase. No pricing information is included. Maison Lumière thanks you for your patronage.")
                .font(.caption2)
                .italic()
                .foregroundStyle(.gray)
                .padding(.top, 12)

            HStack {
                Spacer()
                VStack(spacing: 2) {
                    HStack(spacing: 1) {
                        ForEach(Array(order.id.uuidString.prefix(12).unicodeScalars), id: \.value) { scalar in
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: scalar.value % 3 == 0 ? 3 : 1.5, height: 28)
                        }
                    }
                    Text(order.id.uuidString.prefix(12).uppercased())
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.black)
                }
                Spacer()
            }
            .padding(.top, 10)
        }
    }

    @MainActor
    private func generatePDF() -> URL? {
        let printView = giftReceiptPaperView
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

