//
//  ReceiptView.swift
//  RSMS
//

import SwiftUI

struct ReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM

    let order: Order
    let client: ClientProfile
    let paymentId: String
    
    // In a real app we might fetch the items from the cart.
    // Here we'll pass them in or fetch them from DataStore
    let cartItems: [UniversalCartItem]
    @State private var localCartItems: [UniversalCartItem] = []
    
    @State private var generatedPDFURL: URL? = nil
    @State private var showShareSheet = false

    private var store: Store? {
        guard let storeId = appVM.currentUser?.storeId else { return nil }
        return appVM.dataStore.store(by: storeId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            receiptPaperView
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Receipt")
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
                    ReceiptShareSheet(activityItems: [url])
                }
            }
            .task {
                if cartItems.isEmpty {
                    do {
                        try await appVM.dataStore.fetchUniversalCartItems(cartId: order.cartId)
                        localCartItems = appVM.dataStore.universalCartItems.filter { $0.cartId == order.cartId }
                    } catch {
                        print("Error fetching items for receipt: \(error)")
                    }
                } else {
                    localCartItems = cartItems
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
    private var receiptPaperView: some View {
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
                        Text(store.name)
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
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("PAYMENT RECEIPT")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(red: 0.45, green: 0.05, blue: 0.1))
                        .tracking(1)
                    Group {
                        labeledValue("Order", order.id.uuidString.prefix(8).uppercased())
                        labeledValue("Date", order.createdAt.formatted(date: .abbreviated, time: .omitted))
                        labeledValue("Time", order.createdAt.formatted(date: .omitted, time: .shortened))
                    }
                }
            }
            .padding(.bottom, 16)

            slipDivider

            // ── STORE / CLIENT ─────────────────────────────────
            HStack(alignment: .top, spacing: 24) {
                // Store
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("STORE")
                    if let store = store {
                        Text(store.name)
                            .font(.caption2.weight(.bold)).foregroundStyle(.black)
                        Text(store.address)
                            .font(.caption2).foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        if let phone = store.phone {
                            Text(phone).font(.caption2).foregroundStyle(.gray)
                        }
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

                // Client
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("CLIENT")
                    Text(client.fullName)
                        .font(.caption2.weight(.bold)).foregroundStyle(.black)
                    if let phone = client.phone {
                        Text(phone).font(.caption2).foregroundStyle(.gray)
                    }
                    if let email = client.email {
                        Text(email).font(.caption2).foregroundStyle(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 14)

            slipDivider

            // ── INFO ROW ───────────────────────────────────
            HStack(spacing: 0) {
                infoCell(label: "PAYMENT METHOD", value: "Razorpay")
                Divider().frame(height: 36)
                infoCell(label: "TRANSACTION REF.", value: paymentId.isEmpty ? "—" : paymentId)
                Divider().frame(height: 36)
                infoCell(label: "CASHIER", value: appVM.currentUser?.fullName ?? "Staff")
            }
            .padding(.vertical, 10)
            .background(Color(red: 0.97, green: 0.96, blue: 0.94))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            slipDivider

            // ── ITEMS TABLE ─────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                sectionHeader("ITEMS BOUGHT")
                    .padding(.bottom, 4)

                // Table Header
                HStack {
                    Text("DESCRIPTION").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("SKU").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 90, alignment: .leading)
                    Text("QTY").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 40, alignment: .center)
                    Text("PRICE").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
                .background(Color.black)

                // Table Rows
                ForEach(Array(localCartItems.enumerated()), id: \.element.id) { index, item in
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

                        let price = appVM.dataStore.resolvedPrice(for: item)
                        Text("₹\(Int(price).formatted())")
                            .font(.caption2.weight(.medium)).foregroundStyle(.black)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 6)
                    .background(index % 2 == 0 ? Color.white : Color(red: 0.97, green: 0.97, blue: 0.97))

                    Divider().overlay(Color.gray.opacity(0.15))
                }
            }
            .padding(.vertical, 14)

            slipDivider

            // ── FINANCIALS ─────────────────────────────────────────
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    HStack {
                        Text("SUBTOTAL")
                            .font(.caption2.weight(.bold)).foregroundStyle(.gray)
                        Text("₹\(Int(order.totalAmount).formatted())")
                            .font(.caption2.weight(.semibold)).foregroundStyle(.black)
                            .frame(width: 80, alignment: .trailing)
                    }
                    if order.discountAmount > 0 {
                        HStack {
                            Text("DISCOUNT")
                                .font(.caption2.weight(.bold)).foregroundStyle(.gray)
                            Text("-₹\(Int(order.discountAmount).formatted())")
                                .font(.caption2.weight(.semibold)).foregroundStyle(RSMSTheme.success)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                    HStack {
                        Text("TOTAL PAID")
                            .font(.caption2.weight(.bold)).foregroundStyle(.black)
                        Text("₹\(Int(order.finalAmount).formatted())")
                            .font(.caption.weight(.bold)).foregroundStyle(.black)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 12)
            
            slipDivider
            
            // ── TAX-FREE ─────────────────────────────────────────
            if let taxFree = appVM.dataStore.taxFreeTransactions.first(where: { $0.orderId == order.id }) {
                let layout = TaxFreeReceiptGenerator.generateLayout(
                    transactionId: taxFree.id,
                    passportNumber: taxFree.passportNumber,
                    countryOfResidence: taxFree.countryOfResidence,
                    taxAmount: taxFree.taxAmount,
                    refundAmount: taxFree.refundAmount
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("TAX-FREE SHOPPING DETAILS")
                    
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TAX-FREE REF: \(layout.refNumber)")
                                .font(.caption2.weight(.bold)).foregroundStyle(.black)
                            Text("Passport: \(layout.passportNumber)")
                                .font(.caption2).foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                            Text("Country: \(layout.country)")
                                .font(.caption2).foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("VAT/GST PAID: ₹\(Int(truncating: layout.taxAmount as NSDecimalNumber).formatted())")
                                .font(.caption2.weight(.bold)).foregroundStyle(.black)
                            Text("REFUND AMT: ₹\(Int(truncating: layout.refundAmount as NSDecimalNumber).formatted())")
                                .font(.caption2.weight(.bold)).foregroundStyle(RSMSTheme.success)
                        }
                        Spacer()
                    }
                    
                    Text(layout.message)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.gray)
                        .padding(.top, 4)
                }
                .padding(.vertical, 12)
                
                slipDivider
            }

            // ── FOOTER / BARCODE ──────────────────────────────────────────
            Text("This is an official payment receipt. For returns or exchanges, please present this receipt within 14 days of purchase. Maison Lumière thanks you for your patronage.")
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
        let printView = receiptPaperView
            .frame(width: 612, height: 792) // Letter size
            .padding(40)
            .background(Color.white)
        
        let renderer = ImageRenderer(content: printView)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Receipt-\(order.id.uuidString.prefix(8)).pdf")
        
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
            printInfo.jobName = "Receipt \(order.id.uuidString.prefix(8))"
            printInfo.outputType = .general
            printController.printInfo = printInfo
            printController.printingItem = url
            
            printController.present(animated: true) { _, _, _ in }
        }
    }
}

struct ReceiptShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

