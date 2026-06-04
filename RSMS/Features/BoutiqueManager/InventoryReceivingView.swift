//
//  InventoryReceivingView.swift
//  RSMS
//

import SwiftUI
import VisionKit
import AVFoundation

struct InventoryReceivingView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel = InventoryReceivingViewModel()
    @State private var scannedCode: String?
    @State private var manualCode = ""

    // Camera authorization
    @State private var cameraAuthorized = false
    @State private var cameraAuthDenied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let summary = viewModel.completionSummary {
                    completionCard(summary)
                }

                scannerCard
                batchCard
                summaryCard
            }
            .padding(24)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Inventory Receiving")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.preload(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
            await requestCameraAccess()
        }
        .onChange(of: scannedCode) { _, newCode in
            guard let newCode else { return }
            scannedCode = nil
            Task {
                await viewModel.process(
                    scannedCode: newCode,
                    dataStore: appVM.dataStore,
                    storeId: appVM.currentStoreId
                )
            }
        }
    }

    private var scannerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Receive & Put Away",
                subtitle: "Scan inbound items, capture quantities, then assign storage locations before posting stock."
            )

            Group {
                if cameraAuthDenied {
                    // Permission denied — show settings link
                    VStack(spacing: 14) {
                        Image(systemName: "camera.slash.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(RSMSTheme.gold.opacity(0.5))
                        Text("Camera Access Required")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Please allow camera access in Settings.")
                            .font(.caption)
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
                    .frame(maxWidth: .infinity)
                    .frame(height: 230)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                } else if !cameraAuthorized {
                    ProgressView().tint(RSMSTheme.gold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                } else if DataScannerViewController.isSupported {
                    DataScannerRepresentable(scannedCode: $scannedCode)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(RSMSTheme.border, lineWidth: 1)
                        )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(RSMSTheme.gold.opacity(0.5))
                        Text("Camera scanner is unavailable on this device.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.textPrimary)
                        Text("Use manual SKU or RFID tag entry below.")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 230)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .frame(height: 230)

            HStack(spacing: 12) {
                TextField("Scan or enter SKU / RFID tag", text: $manualCode)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .padding(14)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
                    .onSubmit { submitManualCode() }

                Button(action: submitManualCode) {
                    Image(systemName: "plus.viewfinder")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(RSMSTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(manualCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack(spacing: 10) {
                Image(systemName: viewModel.feedback.icon)
                    .foregroundStyle(viewModel.feedback.color)
                Text(viewModel.feedback.message ?? "Ready to capture incoming inventory.")
                    .font(.subheadline)
                    .foregroundStyle(viewModel.feedback.message == nil ? RSMSTheme.textSecondary : viewModel.feedback.color)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(viewModel.feedback.color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .rsmsCard()
    }

    private var batchCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Receiving Batch",
                subtitle: "Adjust quantities and storage locations before completing put-away."
            )

            HStack(spacing: 12) {
                TextField("Apply location to all items", text: bulkLocationBinding)
                    .textInputAutocapitalization(.never)
                    .padding(14)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )

                Button("Apply") {
                    viewModel.applyBulkLocation()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.primary)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(RSMSTheme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if viewModel.draftItems.isEmpty {
                ContentUnavailableView(
                    "No Received Items Yet",
                    systemImage: "shippingbox",
                    description: Text("Scan inbound inventory to build a receiving batch.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.draftItems) { line in
                        batchLineRow(line)
                    }
                }
            }
        }
        .rsmsCard()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Posting Summary",
                subtitle: "Confirm quantities and assigned locations before stock is updated."
            )

            HStack(spacing: 14) {
                metricCard(value: "\(viewModel.totalUnits)", label: "Units")
                metricCard(value: "\(viewModel.draftItems.count)", label: "SKUs")
                metricCard(value: "\(viewModel.assignedLocations.count)", label: "Locations")
            }

            Button {
                guard let user = appVM.currentUser else { return }
                Task {
                    await viewModel.finalize(dataStore: appVM.dataStore, user: user)
                }
            } label: {
                HStack {
                    if viewModel.isFinalizing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Complete Receiving & Put-Away")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.draftItems.isEmpty || viewModel.isFinalizing || appVM.currentUser == nil)
        }
        .rsmsCard()
    }

    private func completionCard(_ summary: ReceivingCompletionSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Receiving Completed")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Batch \(summary.movement.id.uuidString.prefix(8)) posted at \(summary.movement.receivedAt?.formatted(date: .abbreviated, time: .shortened) ?? "now").")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(RSMSTheme.success)
            }

            HStack(spacing: 14) {
                metricCard(value: "\(summary.totalUnits)", label: "Units Received")
                metricCard(value: "\(summary.totalSKUs)", label: "SKUs")
                metricCard(value: "\(summary.locations.count)", label: "Put-Away Zones")
            }

            if !summary.locations.isEmpty {
                Text(summary.locations.joined(separator: " • "))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.success.opacity(0.1))
                    .clipShape(Capsule())
            }

            Button("Start New Batch") {
                viewModel.startNewBatch()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(RSMSTheme.primary)
        }
        .rsmsCard()
    }

    private func batchLineRow(_ line: ReceivingBatchLine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(line.product.name)
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(line.product.sku)
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.textSecondary)
                }

                Spacer()

                Button {
                    viewModel.removeLine(id: line.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(RSMSTheme.danger)
                }
            }

            if let stockItem = line.existingStockItem {
                Text("Current stock: \(stockItem.quantity) units\(stockItem.location.map { " in \($0)" } ?? "")")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                Text("New stock record will be created for this boutique.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            HStack(spacing: 14) {
                Stepper(value: quantityBinding(for: line.id), in: 1...999) {
                    Text("Qty: \(line.quantity)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }

                TextField("Put-away location", text: locationBinding(for: line.id))
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
            }
        }
        .padding(18)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    private func metricCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var bulkLocationBinding: Binding<String> {
        Binding(
            get: { viewModel.bulkLocation },
            set: { viewModel.bulkLocation = $0 }
        )
    }

    private func quantityBinding(for lineId: UUID) -> Binding<Int> {
        Binding(
            get: { viewModel.draftItems.first(where: { $0.id == lineId })?.quantity ?? 1 },
            set: { viewModel.updateQuantity($0, for: lineId) }
        )
    }

    private func locationBinding(for lineId: UUID) -> Binding<String> {
        Binding(
            get: { viewModel.draftItems.first(where: { $0.id == lineId })?.location ?? "" },
            set: { viewModel.updateLocation($0, for: lineId) }
        )
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if viewModel.draftItems.isEmpty {
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.primary.opacity(0.35))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSTheme.primaryGradient)
        }
    }

    private func submitManualCode() {
        let trimmed = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        manualCode = ""
        Task {
            await viewModel.process(
                scannedCode: trimmed,
                dataStore: appVM.dataStore,
                storeId: appVM.currentStoreId
            )
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
}

#Preview {
    NavigationStack {
        InventoryReceivingView()
            .environment(AppViewModel())
    }
}
