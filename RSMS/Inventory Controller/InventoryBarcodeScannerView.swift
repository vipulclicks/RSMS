//
//  InventoryBarcodeScannerView.swift
//  RSMS
//
//  Barcode scanner with manual SKU entry fallback.
//  Uses VisionKit DataScannerViewController where available;
//  falls back gracefully on unsupported devices without crashing.
//  Product lookup, stock updates, and audit logging are wired to Supabase via DataStore.
//  Colors sourced from RSMSTheme.
//

import SwiftUI
import VisionKit

// MARK: - Main Scanner View

struct InventoryBarcodeScannerView: View {

    var initialMode: ScanMode = .stockIn

    @Environment(AppViewModel.self) private var appVM
    @State private var scannerVM = BarcodeScannerViewModel()
    @State private var rawScannedCode: String? = nil
    @State private var manualInput: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            RSMSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                modeBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                viewfinderSection
                    .padding(.horizontal, 16)

                if DataScannerViewController.isSupported {
                    Text("Point the camera at a product barcode")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                Spacer()

                manualEntryPanel
                    .padding(.horizontal, 16)
                    .padding(.bottom, sessionLog.isEmpty ? 16 : 8)

                if !scannerVM.sessionLog.isEmpty {
                    sessionLogSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }

            // Loading overlay on viewfinder
            if case .loading = scannerVM.state {
                VStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(RSMSTheme.background.opacity(0.6))
                        .overlay(ProgressView().tint(RSMSTheme.gold))
                        .frame(height: 320)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .padding(.top, 52) // below picker
            }
        }
        .task {
            scannerVM.scanMode = initialMode
            await scannerVM.preload(
                dataStore: appVM.dataStore,
                storeId: appVM.currentStoreId
            )
        }
        .onChange(of: rawScannedCode) { _, newCode in
            guard let code = newCode else { return }
            rawScannedCode = nil
            Task {
                await scannerVM.process(
                    barcode: code,
                    dataStore: appVM.dataStore,
                    storeId: appVM.currentStoreId
                )
            }
        }
        .sheet(
            isPresented: Binding(
                get: { scannerVM.state.isResultState },
                set: { if !$0 { scannerVM.resetState() } }
            )
        ) {
            ScanResultSheet(scannerVM: scannerVM)
                .environment(appVM)
        }
    }

    // MARK: - Mode Banner

    private var modeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: scannerVM.scanMode.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(scannerVM.scanMode.badgeColor)
            Text(scannerVM.scanMode.rawValue.uppercased())
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(scannerVM.scanMode.badgeColor)
            Spacer()
            Circle()
                .fill(scannerVM.scanMode.badgeColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(scannerVM.scanMode.badgeColor.opacity(0.3))
                        .frame(width: 16, height: 16)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(scannerVM.scanMode.badgeColor.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Viewfinder

    private var viewfinderSection: some View {
        Group {
            if DataScannerViewController.isSupported {
                DataScannerRepresentable(scannedCode: $rawScannedCode)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
            } else {
                scannerUnavailableView
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .padding(.top, 8)
    }

    private var scannerUnavailableView: some View {
        VStack(spacing: 14) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 52))
                .foregroundStyle(RSMSTheme.gold.opacity(0.35))
            Text("Camera scanner unavailable\non this device")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
                .multilineTextAlignment(.center)
            Text("Use the manual entry panel below")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Manual Entry Panel

    private var manualEntryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ENTER CODE MANUALLY")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.gold)

            HStack(spacing: 10) {
                TextField("SKU or barcode (e.g. WA-CHR-RG-42)", text: $manualInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(12)
                    .background(RSMSTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RSMSTheme.gold.opacity(0.25), lineWidth: 1)
                    )
                    .onSubmit { submitManualEntry() }

                Button(action: submitManualEntry) {
                    Image(systemName: "magnifyingglass")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(RSMSTheme.background)
                        .frame(width: 46, height: 46)
                        .background(
                            manualInput.trimmingCharacters(in: .whitespaces).isEmpty
                                ? RSMSTheme.gold.opacity(0.4)
                                : RSMSTheme.gold
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(manualInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Session Log

    private var sessionLog: [ScanLogEntry] { scannerVM.sessionLog }

    private var sessionLogSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SESSION LOG")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(RSMSTheme.gold)
                Spacer()
                Button("CLEAR") {
                    withAnimation { scannerVM.clearSession() }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.gold.opacity(0.7))
            }

            VStack(spacing: 0) {
                ForEach(sessionLog.prefix(5)) { entry in
                    sessionLogRow(entry)
                    if entry.id != sessionLog.prefix(5).last?.id {
                        Rectangle()
                            .fill(RSMSTheme.divider)
                            .frame(height: 0.5)
                            .padding(.horizontal, 12)
                    }
                }
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
        }
    }

    private func sessionLogRow(_ entry: ScanLogEntry) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(entry.mode.badgeColor.opacity(0.12))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: entry.mode.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(entry.mode.badgeColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.productName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                Text(entry.sku)
                    .font(.caption2.monospaced())
                    .foregroundStyle(RSMSTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.mode.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(entry.mode.badgeColor)
                Text(entry.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func submitManualEntry() {
        let trimmed = manualInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        manualInput = ""
        Task {
            await scannerVM.process(
                barcode: trimmed,
                dataStore: appVM.dataStore,
                storeId: appVM.currentStoreId
            )
        }
    }
}

// MARK: - DataScannerRepresentable

struct DataScannerRepresentable: UIViewControllerRepresentable {

    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {

        @Binding var scannedCode: String?

        init(scannedCode: Binding<String?>) {
            _scannedCode = scannedCode
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard let item = addedItems.first else { return }
            extract(item)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            extract(item)
        }

        private func extract(_ item: RecognizedItem) {
            if case .barcode(let barcode) = item,
               let payload = barcode.payloadStringValue {
                scannedCode = payload
            }
        }
    }
}

// MARK: - Previews

#Preview("Stock In") {
    InventoryBarcodeScannerView(initialMode: .stockIn)
        .environment(AppViewModel())
}

#Preview("Verify") {
    NavigationStack {
        InventoryBarcodeScannerView(initialMode: .verification)
            .navigationTitle("Verify Inventory")
            .navigationBarTitleDisplayMode(.inline)
    }
    .environment(AppViewModel())
}

