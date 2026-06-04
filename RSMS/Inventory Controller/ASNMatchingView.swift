//
//  ASNMatchingView.swift
//  RSMS
//
//  Receive inventory against an Advanced Shipment Notice (ASN).
//  Three states: Search → Review line items → Confirmed receipt.
//  All data read/written through Supabase via DataStore.
//

import SwiftUI
import VisionKit
import AVFoundation

struct ASNMatchingView: View {

    @Environment(AppViewModel.self) private var appVM
    @State private var vm = ASNMatchingViewModel()
    @State private var rawScannedCode: String? = nil
    @State private var showScanner = false
    @State private var cameraAuthorized = false
    @State private var cameraAuthDenied = false

    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()

            switch vm.state {
            case .idle, .notFound:
                searchView
            case .matched:
                reviewView
            case .confirmed:
                confirmedView
            case .error(let msg):
                errorView(message: msg)
            }
        }
        .navigationTitle("ASN Matching")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.state == .matched {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { vm.reset() }
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
        .onChange(of: rawScannedCode) { _, code in
            guard let code else { return }
            rawScannedCode = nil
            vm.asnQuery = code
            Task {
                if let storeId = appVM.currentStoreId {
                    await vm.fetchAndSearch(in: appVM.dataStore, storeId: storeId)
                }
            }
            showScanner = false
        }
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                asnScannerView
                    .navigationTitle("Scan ASN Label")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showScanner = false }
                                .foregroundStyle(RSMSTheme.gold)
                        }
                    }
            }
        }
    }

    // MARK: - Search View

    private var searchView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Enter ASN Number")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Type or scan the ASN label from the incoming shipment")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }

                // Input card
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        TextField("e.g. ASN-2026-05-987654", text: $vm.asnQuery)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .font(.body.monospaced())
                            .padding(14)
                            .background(RSMSTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(RSMSTheme.gold.opacity(0.3), lineWidth: 1)
                            )
                            .onSubmit { submitSearch() }

                        Button(action: { showScanner = true }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(RSMSTheme.background)
                                .frame(width: 50, height: 50)
                                .background(RSMSTheme.gold)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button(action: submitSearch) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("Search Shipment")
                                .font(.headline)
                        }
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            vm.asnQuery.trimmingCharacters(in: .whitespaces).isEmpty
                                ? RSMSTheme.gold.opacity(0.4)
                                : RSMSTheme.gold
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vm.asnQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )

                // Not found banner
                if vm.state == .notFound {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(RSMSTheme.warning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Shipment Not Found")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("No in-transit ASN matches \"\(vm.asnQuery)\" for this store.")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                    .padding(16)
                    .background(RSMSTheme.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(RSMSTheme.warning.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(24)
        }
        .animation(.spring(response: 0.35), value: vm.state)
    }

    // MARK: - Review View

    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Movement header card
                if let movement = vm.matchedMovement {
                    movementHeaderCard(movement)
                }

                // Line items
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("LINE ITEMS")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(RSMSTheme.gold)
                        Spacer()
                        Text("\(vm.lineItems.count) products")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(vm.lineItems.enumerated()), id: \.element.id) { index, lineItem in
                            lineItemRow(lineItem)

                            if index < vm.lineItems.count - 1 {
                                Rectangle()
                                    .fill(RSMSTheme.divider)
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
                }

                // Confirm button
                Button {
                    Task {
                        if let storeId = appVM.currentStoreId, let user = appVM.currentUser {
                            await vm.receive(
                                dataStore: appVM.dataStore,
                                user: user,
                                storeId: storeId
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if vm.isSubmitting {
                            ProgressView().tint(RSMSTheme.background)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm Receipt")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(RSMSTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(RSMSTheme.success)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(vm.isSubmitting)
            }
            .padding(24)
        }
    }

    private func movementHeaderCard(_ movement: InventoryMovement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(movement.asnNumber ?? "—")
                        .font(.title3.bold().monospaced())
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(movement.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                Spacer()
                Text("IN TRANSIT")
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(RSMSTheme.warning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RSMSTheme.warning.opacity(0.12))
                    .clipShape(Capsule())
            }

            Rectangle().fill(RSMSTheme.divider).frame(height: 0.5)

            HStack(spacing: 24) {
                infoChip(label: "SOURCE", value: movement.sourceId)
                infoChip(label: "EXPECTED", value: "\(movement.itemsExpected ?? vm.lineItems.count) items")
                if let shipped = movement.shippedAt {
                    infoChip(label: "SHIPPED", value: shipped.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .padding(18)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    private func infoChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(RSMSTheme.textTertiary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .lineLimit(1)
        }
    }

    private func lineItemRow(_ lineItem: ASNLineItem) -> some View {
        HStack(spacing: 14) {
            // Product icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: categoryIcon(lineItem.product.category))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(RSMSTheme.gold)
            }

            // Product info
            VStack(alignment: .leading, spacing: 3) {
                Text(lineItem.product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                Text("Expected: \(lineItem.expectedQty) units")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            Spacer()

            // Received qty stepper
            HStack(spacing: 0) {
                Button {
                    let current = vm.receivedQtys[lineItem.id] ?? lineItem.expectedQty
                    if current > 0 {
                        vm.receivedQtys[lineItem.id] = current - 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(width: 32, height: 32)
                }

                Text("\(vm.receivedQtys[lineItem.id] ?? lineItem.expectedQty)")
                    .font(.subheadline.bold())
                    .foregroundStyle(
                        receivedMatchesExpected(lineItem)
                            ? RSMSTheme.success
                            : RSMSTheme.warning
                    )
                    .frame(minWidth: 28, alignment: .center)

                Button {
                    let current = vm.receivedQtys[lineItem.id] ?? lineItem.expectedQty
                    vm.receivedQtys[lineItem.id] = current + 1
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .background(RSMSTheme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func receivedMatchesExpected(_ lineItem: ASNLineItem) -> Bool {
        (vm.receivedQtys[lineItem.id] ?? lineItem.expectedQty) == lineItem.expectedQty
    }

    // MARK: - Confirmed View

    private var confirmedView: some View {
        VStack(spacing: 28) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(RSMSTheme.success.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(RSMSTheme.success)
                    .symbolEffect(.bounce, value: vm.state == .confirmed)
            }

            VStack(spacing: 8) {
                Text("Shipment Received")
                    .font(.title2.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Inventory has been updated in Supabase")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            // Summary card
            VStack(spacing: 0) {
                summaryRow(label: "ASN Number", value: vm.matchedMovement?.asnNumber ?? "—")
                Rectangle().fill(RSMSTheme.divider).frame(height: 0.5).padding(.horizontal, 16)
                summaryRow(label: "Items Received", value: "\(vm.totalReceived) / \(vm.totalExpected)")
                Rectangle().fill(RSMSTheme.divider).frame(height: 0.5).padding(.horizontal, 16)
                summaryRow(
                    label: "Variances Raised",
                    value: "\(vm.varianceCount)",
                    valueColor: vm.varianceCount > 0 ? RSMSTheme.warning : RSMSTheme.success
                )
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
            .padding(.horizontal, 24)

            Button("Receive Another Shipment") {
                withAnimation(.spring(response: 0.35)) { vm.reset() }
            }
            .font(.headline)
            .foregroundStyle(RSMSTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RSMSTheme.gold)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func summaryRow(label: String, value: String, valueColor: Color = RSMSTheme.textPrimary) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.danger)
            Text("Something went wrong")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Try Again") { vm.reset() }
                .font(.headline)
                .foregroundStyle(RSMSTheme.gold)
        }
        .padding(32)
    }

    // MARK: - ASN Scanner Sheet

    private var asnScannerView: some View {
        ZStack(alignment: .bottom) {
            RSMSTheme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                if cameraAuthDenied {
                    // Permission denied — show settings link
                    VStack(spacing: 14) {
                        Image(systemName: "camera.slash.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(RSMSTheme.gold.opacity(0.5))
                        Text("Camera Access Required")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Please allow camera access in Settings to scan ASN labels.")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.background)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.gold)
                        .clipShape(Capsule())
                    }
                    .padding()
                } else if !cameraAuthorized {
                    ProgressView().tint(RSMSTheme.gold)
                        .padding(.top, 80)
                } else if DataScannerViewController.isSupported {
                    DataScannerRepresentable(scannedCode: $rawScannedCode)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(RSMSTheme.border, lineWidth: 1)
                        )
                        .frame(maxHeight: 360)
                        .padding()
                } else {
                    Text("Camera scanner unavailable on this device")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .padding()
                }

                Text("Point the camera at the ASN barcode on the shipment label")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .task {
            await requestCameraAccess()
        }
    }

    // MARK: - Camera Permission

    @MainActor
    private func requestCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorized = granted
            cameraAuthDenied = !granted
        case .denied, .restricted:
            cameraAuthorized = false
            cameraAuthDenied = true
        @unknown default:
            cameraAuthorized = false
            cameraAuthDenied = true
        }
    }

    // MARK: - Helpers

    private func submitSearch() {
        Task {
            if let storeId = appVM.currentStoreId {
                await vm.fetchAndSearch(in: appVM.dataStore, storeId: storeId)
            }
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "handbags", "leather goods": return "handbag.fill"
        case "watches":                    return "watch.analog"
        case "shoes", "heels":             return "shoe.fill"
        case "jewelry", "jewellery":       return "sparkles"
        case "accessories":                return "eyeglasses"
        case "fragrances":                 return "bubbles.and.sparkles"
        default:                           return "shippingbox.fill"
        }
    }
}

// MARK: - Previews

#Preview("ASN Matching — Search") {
    NavigationStack {
        ASNMatchingView()
            .environment(AppViewModel())
    }
}
