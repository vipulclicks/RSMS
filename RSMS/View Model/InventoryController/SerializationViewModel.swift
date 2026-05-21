//
//  SerializationViewModel.swift
//  RSMS
//
//  ViewModel for the Serialization & Authentication screen.
//  CRUD for serial captures and authenticity certificates.
//

import SwiftUI

@Observable
final class SerializationViewModel {

    private let dataStore: DataStore
    private let storeId: UUID
    private let userId: UUID

    var searchQuery = ""
    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, storeId: UUID, userId: UUID) {
        self.dataStore = dataStore
        self.storeId   = storeId
        self.userId    = userId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchSerialCaptures()
            try await dataStore.fetchAuthCertificates()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Serial Captures
    var serialCaptures: [SerialCapture] { dataStore.serialCaptures }

    var filteredCaptures: [SerialCapture] {
        guard !searchQuery.isEmpty else { return serialCaptures }
        let q = searchQuery.lowercased()
        return serialCaptures.filter {
            $0.serialNumber.lowercased().contains(q) ||
            dataStore.productName(for: $0.productId).lowercased().contains(q)
        }
    }

    func captureSerial(productId: UUID, serialNumber: String) async throws {
        let capture = SerialCapture(
            id: UUID(), productId: productId,
            serialNumber: serialNumber, capturedBy: userId, capturedAt: .now
        )
        try await dataStore.createSerialCapture(capture)
        dataStore.logAudit(storeId: storeId, action: "Serial Captured", entityType: "SerialCapture", entityId: capture.id, performedBy: userId, details: serialNumber)
    }

    func searchBySerial(_ serial: String) -> SerialCapture? {
        serialCaptures.first { $0.serialNumber.lowercased() == serial.lowercased() }
    }

    // MARK: - Certificates
    var certificates: [AuthCertificate] { dataStore.authCertificates }

    func certificate(for productId: UUID) -> AuthCertificate? {
        certificates.first { $0.productId == productId }
    }

    func issueCertificate(productId: UUID, serialNumber: String, certificateURL: String?) async throws {
        let cert = AuthCertificate(
            id: UUID(), productId: productId, serialNumber: serialNumber,
            certificateURL: certificateURL, issuedAt: .now, issuedBy: userId
        )
        try await dataStore.createAuthCertificate(cert)
        dataStore.logAudit(storeId: storeId, action: "Certificate Issued", entityType: "AuthCertificate", entityId: cert.id, performedBy: userId)
    }

    // MARK: - Helpers
    func productName(for id: UUID) -> String { dataStore.productName(for: id) }
    func userName(for id: UUID) -> String { dataStore.userName(for: id) }
}
