//
//  PackingSlipView.swift
//  RSMS
//
//  Created for Ship From Store Packing Slip Generation & Management.
//

import SwiftUI
import PDFKit

struct PackingSlipView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let session: CheckoutSession
    let slip: ShipFromStoreSlip
    
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var showShareSheet = false
    @State private var generatedPDFURL: URL? = nil
    @State private var carrier = ""
    @State private var trackingNumber = ""
    @State private var isSavingTracking = false
    @State private var showSuccessBanner = false
    @State private var isShipped = false
    
    private var client: ClientProfile? {
        appVM.dataStore.client(by: session.clientId)
    }
    
    private var shippingAddress: CheckoutShippingAddress? {
        appVM.dataStore.checkoutShippingAddresses.first { $0.checkoutSessionId == session.id }
    }
    
    private var store: Store? {
        appVM.dataStore.store(by: slip.storeId)
    }
    
    private var confirmedItems: [InventoryReservation] {
        appVM.dataStore.inventoryReservations.filter {
            $0.checkoutSessionId == session.id && ($0.status == .reserved || $0.status == .fulfilled)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if showSuccessBanner {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(RSMSTheme.success)
                            Text("Packing Slip successfully generated & saved.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Spacer()
                            Button {
                                withAnimation(reduceMotion ? nil : .default) { showSuccessBanner = false }
                            } label: {
                                Image(systemName: "xmark").accessibilityLabel("Close")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                        }
                        .padding()
                        .background(RSMSTheme.surfaceSecondary)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. Slip Content
                            slipPaperView
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            
                            // 2. Tracking details card
                            trackingInputSection
                        }
                        .padding(24)
                    }
                    
                    // 3. Actions Footer
                    actionsFooter
                }
            }
            .navigationTitle("Packing Slip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                carrier = slip.carrier ?? ""
                trackingNumber = slip.trackingNumber ?? ""
                isShipped = slip.shippedAt != nil
                withAnimation(reduceMotion ? nil : .default) {
                    showSuccessBanner = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation(reduceMotion ? nil : .default) {
                        showSuccessBanner = false
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = generatedPDFURL {
                    PackingSlipShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // MARK: - Slip Paper View
    private var slipPaperView: some View {
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
                    Text("SHIPPING SLIP")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(red: 0.45, green: 0.05, blue: 0.1))
                        .tracking(1)
                    Group {
                        labeledValue("Order", session.token)
                        labeledValue("Date", Date().formatted(date: .abbreviated, time: .omitted))
                        labeledValue("Created", session.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }
            .padding(.bottom, 16)

            slipDivider

            // ── SHIP FROM / SHIP TO ─────────────────────────────────
            HStack(alignment: .top, spacing: 24) {
                // Ship From
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("SHIP FROM")
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

                // Ship To
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("SHIP TO")
                    if let addr = shippingAddress {
                        Text(addr.name)
                            .font(.caption2.weight(.bold)).foregroundStyle(.black)
                        Text(addr.address)
                            .font(.caption2).foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        Text("\(addr.city), \(addr.state) — \(addr.pincode)")
                            .font(.caption2).foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        Text("Ph: \(addr.phone)")
                            .font(.caption2).foregroundStyle(.gray)
                    } else if let client = client {
                        Text(client.fullName)
                            .font(.caption2.weight(.bold)).foregroundStyle(.black)
                        if let phone = client.phone {
                            Text(phone).font(.caption2).foregroundStyle(.gray)
                        }
                        Text("⚠ No shipping address on file")
                            .font(.caption2).foregroundStyle(.orange)
                            .padding(.top, 2)
                    } else {
                        Text("No recipient details available")
                            .font(.caption2).foregroundStyle(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 14)

            slipDivider

            // ── SHIPMENT INFO ROW ───────────────────────────────────
            HStack(spacing: 0) {
                shipInfoCell(label: "CARRIER",
                             value: carrier.isEmpty ? "Pending assignment" : carrier)
                Divider().frame(height: 36)
                shipInfoCell(label: "TRACKING NO.",
                             value: trackingNumber.isEmpty ? "Awaiting dispatch" : trackingNumber)
                Divider().frame(height: 36)
                shipInfoCell(label: "SHIP DATE",
                             value: slip.shippedAt?.formatted(date: .abbreviated, time: .omitted)
                                    ?? Date().formatted(date: .abbreviated, time: .omitted))
                Divider().frame(height: 36)
                shipInfoCell(label: "PACKED BY",
                             value: appVM.dataStore.users
                                        .first(where: { $0.id == slip.packedBy })?.fullName
                                    ?? "Staff")
            }
            .padding(.vertical, 10)
            .background(Color(red: 0.97, green: 0.96, blue: 0.94))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            slipDivider

            // ── ITEMS TABLE ─────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                sectionHeader("PACKED ITEMS")
                    .padding(.bottom, 4)

                // Table Header
                HStack {
                    Text("DESCRIPTION").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("SKU").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 90, alignment: .leading)
                    Text("QTY").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 40, alignment: .center)
                    Text("WEIGHT").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
                .background(Color.black)

                // Table Rows
                ForEach(Array(confirmedItems.enumerated()), id: \.element.id) { index, item in
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

                        Text("—")
                            .font(.caption2).foregroundStyle(.gray)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 6)
                    .background(index % 2 == 0 ? Color.white : Color(red: 0.97, green: 0.97, blue: 0.97))

                    Divider().overlay(Color.gray.opacity(0.15))
                }

                // Total row
                HStack {
                    Text("TOTAL ITEMS")
                        .font(.caption2.weight(.bold)).foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("\(confirmedItems.reduce(0) { $0 + $1.quantity }) units")
                        .font(.caption2.weight(.bold)).foregroundStyle(.black)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
                .background(Color(red: 0.95, green: 0.93, blue: 0.90))
            }
            .padding(.vertical, 14)

            slipDivider

            // ── SPECIAL INSTRUCTIONS / FOOTER ──────────────────────
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("SPECIAL INSTRUCTIONS")
                    Text("Handle with care. Luxury items enclosed.\nDo not bend. Signature required on delivery.")
                        .font(.caption2).foregroundStyle(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("AUTHORISED BY")
                        .font(.caption2.weight(.bold)).foregroundStyle(.gray)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 1)
                        .padding(.top, 20)
                    Text("Signature")
                        .font(.caption2).foregroundStyle(Color.gray.opacity(0.5))
                }
            }
            .padding(.vertical, 12)

            slipDivider

            // ── DISCLAIMER ──────────────────────────────────────────
            Text("This packing slip is for shipment verification only and does not include pricing. Maison Lumière is not responsible for delays caused by the carrier after handover. For queries, contact the store directly.")
                .font(.caption2)
                .italic()
                .foregroundStyle(.gray)
                .padding(.top, 8)

            // ── BARCODE PLACEHOLDER ─────────────────────────────────
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    HStack(spacing: 1) {
                        ForEach(Array(session.token.unicodeScalars.prefix(12)), id: \.value) { scalar in
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: scalar.value % 3 == 0 ? 3 : 1.5, height: 28)
                        }
                    }
                    Text(session.token)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.black)
                }
                Spacer()
            }
            .padding(.top, 10)
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

    private func shipInfoCell(label: String, value: String) -> some View {
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
    
    // MARK: - Tracking Section
    private var trackingInputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Update Shipment Details")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
            
            LuxuryTextField(title: "Carrier Name (e.g. DHL, FedEx)", text: $carrier)
            LuxuryTextField(title: "Tracking/Reference Number", text: $trackingNumber)
            
            Toggle("Mark as Shipped", isOn: $isShipped)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding(.vertical, 4)
            
            Button {
                saveShipmentDetails()
            } label: {
                if isSavingTracking {
                    ProgressView().tint(.white)
                } else {
                    Text("Save Shipment Info")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isSavingTracking)
        }
        .rsmsCard()
    }
    
    // MARK: - Actions Footer
    private var actionsFooter: some View {
        HStack(spacing: 16) {
            Button {
                sharePackingSlip()
            } label: {
                Label("Download/Share", systemImage: "square.and.arrow.up.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RSMSTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button {
                printPackingSlip()
            } label: {
                Label("Print Slip", systemImage: "printer.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RSMSTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(RSMSTheme.surfacePrimary)
        .overlay(VStack { Divider().overlay(RSMSTheme.border); Spacer() })
    }
    
    // MARK: - Logic / Printing / Sharing
    
    private func saveShipmentDetails() {
        isSavingTracking = true
        Task {
            do {
                let shippedDate = isShipped ? (slip.shippedAt ?? Date()) : nil
                let updated = ShipFromStoreSlip(
                    id: slip.id,
                    orderId: slip.orderId,
                    storeId: slip.storeId,
                    trackingNumber: trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : trackingNumber,
                    carrier: carrier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : carrier,
                    packingSlipURL: slip.packingSlipURL,
                    packedBy: slip.packedBy,
                    shippedAt: shippedDate,
                    createdAt: slip.createdAt
                )
                try await appVM.dataStore.updateShipFromStoreSlip(updated)
                
                // If marked as shipped, synchronize other state (session status, reservations, and order record)
                if isShipped {
                    if session.status != .completed {
                        var updatedSession = session
                        updatedSession.status = .completed
                        try? await appVM.dataStore.updateCheckoutSession(updatedSession)
                    }
                    
                    let reservations = appVM.dataStore.inventoryReservations.filter { $0.checkoutSessionId == session.id }
                    for res in reservations {
                        if res.status != .fulfilled {
                            var updatedRes = res
                            updatedRes.status = .fulfilled
                            try? await appVM.dataStore.updateInventoryReservation(updatedRes)
                        }
                    }
                    
                    let existingOrder = appVM.dataStore.orders.first(where: { $0.checkoutSessionId == session.id })
                    if existingOrder == nil {
                        let total = appVM.dataStore.cartTotal(for: session.cartId)
                        let address = appVM.dataStore.checkoutShippingAddresses.first { $0.checkoutSessionId == session.id }
                        let addressStr = address.map { "\($0.address), \($0.city), \($0.state) - \($0.pincode)" }
                        let order = Order(
                            id: UUID(),
                            clientId: session.clientId,
                            transactionId: UUID(),
                            cartId: session.cartId,
                            status: .shipped,
                            totalAmount: total / 1.2,
                            discountAmount: 0,
                            finalAmount: total,
                            createdAt: Date(),
                            fulfillmentMethod: session.fulfillmentMethod?.rawValue,
                            pickupStoreId: nil,
                            shippingAddress: addressStr,
                            checkoutSessionId: session.id
                        )
                        try? await appVM.dataStore.createOrder(order)
                    }
                }
                
                appVM.dataStore.logAudit(
                    storeId: slip.storeId,
                    action: "Packing Slip Updated",
                    entityType: "ShipFromStoreSlip",
                    entityId: slip.id,
                    performedBy: appVM.currentUser?.id ?? UUID()
                )
                await MainActor.run {
                    isSavingTracking = false
                    withAnimation(reduceMotion ? nil : .default) {
                        showSuccessBanner = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSavingTracking = false
                }
            }
        }
    }
    
    @MainActor
    private func generatePDF() -> URL? {
        let printView = slipPaperView
            .frame(width: 612, height: 792) // Letter size
            .padding(40)
            .background(Color.white)
        
        let renderer = ImageRenderer(content: printView)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PackingSlip-\(session.token).pdf")
        
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: CGSize(width: 612, height: 792))
            guard let pdfContext = CGContext(tempURL as CFURL, mediaBox: &box, nil) else { return }
            pdfContext.beginPDFPage(nil)
            
            // Center the content on the PDF page
            let dx = (box.size.width - size.width) / 2
            let dy = (box.size.height - size.height) / 2
            pdfContext.translateBy(x: dx, y: dy)
            
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        return tempURL
    }
    
    private func sharePackingSlip() {
        if let url = generatePDF() {
            generatedPDFURL = url
            showShareSheet = true
        }
    }
    
    private func printPackingSlip() {
        if let url = generatePDF() {
            let printController = UIPrintInteractionController.shared
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = "Packing Slip \(session.token)"
            printInfo.outputType = .general
            printController.printInfo = printInfo
            printController.printingItem = url
            
            printController.present(animated: true) { _, _, _ in }
        }
    }
}

// Activity View wrapper for share sheet
struct PackingSlipShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
