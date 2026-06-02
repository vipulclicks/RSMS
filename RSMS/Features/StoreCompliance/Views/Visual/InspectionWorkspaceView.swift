//
//  InspectionWorkspaceView.swift
//  RSMS
//

import SwiftUI

struct InspectionWorkspaceView: View {
    @Bindable var viewModel: ComplianceViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    
    let zone: MerchandisingZone
    
    struct InspectionCheckpoint: Identifiable {
        let id = UUID()
        let title: String
        var status: ComplianceStatus?
        var photoUrls: [String] = []
    }
    
    @State private var checkpoints = [
        InspectionCheckpoint(title: "Products match planogram exactly"),
        InspectionCheckpoint(title: "All items properly aligned and spaced"),
        InspectionCheckpoint(title: "Lighting is functional and aimed correctly"),
        InspectionCheckpoint(title: "Marketing signage is current"),
        InspectionCheckpoint(title: "Display is clean and dust-free")
    ]
    
    @State private var notes: String = ""
    @State private var uploadedPhotoUrls: [String] = []
    @State private var editingCheckpointId: UUID? = nil
    
    @State private var showPhotoUpload = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var isFormComplete: Bool {
        checkpoints.allSatisfy { $0.status != nil }
    }
    
    var body: some View {
        GeometryReader { geo in
                HStack(spacing: 0) {
                    // Only the Inspection Workspace Form
                    
                    // Right Panel: Inspection Workspace
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            Text("Log Compliance Check")
                                .font(.largeTitle.bold())
                            
                            // Checkpoints
                            VStack(alignment: .leading, spacing: 24) {
                                ForEach($checkpoints) { $checkpoint in
                                    checkpointRow(for: $checkpoint)
                                }
                            }
                            
                            // Evidence Gallery
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Evidence Photos")
                                        .font(.title2.bold())
                                    Spacer()
                                    Button(action: { showPhotoUpload = true }) {
                                        Label("Add Photo", systemImage: "camera.fill")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(RSMSTheme.primary)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                if uploadedPhotoUrls.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 48))
                                            .foregroundColor(.gray.opacity(0.5))
                                        Text("No evidence attached")
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)
                                    .background(RSMSTheme.surfaceSecondary)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    )
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(uploadedPhotoUrls, id: \.self) { urlString in
                                                AsyncImage(url: URL(string: urlString)) { phase in
                                                    if let image = phase.image {
                                                        image.resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Rectangle().fill(Color.gray.opacity(0.2))
                                                    }
                                                }
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Inspector Notes")
                                    .font(.title2.bold())
                                TextEditor(text: $notes)
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .background(RSMSTheme.surfaceSecondary)
                                    .cornerRadius(12)
                            }
                            
                            Spacer(minLength: 40)
                            
                            Button(action: saveCheck) {
                                HStack {
                                    if isSubmitting {
                                        ProgressView().tint(.white)
                                    }
                                    Text("Submit Compliance Check")
                                        .font(.title3.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(!isFormComplete || isSubmitting ? Color.gray : RSMSTheme.primaryDark)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .disabled(!isFormComplete || isSubmitting)
                        }
                        .padding(40)
                    }
                    .frame(maxWidth: .infinity)
                    .background(RSMSTheme.background)
                }
            }
            .navigationTitle("Check: \(zone.name)")
            .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPhotoUpload, onDismiss: {
            editingCheckpointId = nil
        }) {
            EvidenceUploadView(photoUrls: bindingForSelectedCheckpoint(), viewModel: viewModel)
        }
        .alert("Cannot Save", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Components
    
    private func checkpointRow(for checkpoint: Binding<InspectionCheckpoint>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(checkpoint.wrappedValue.title)
                .font(.headline)
                .foregroundColor(RSMSTheme.textPrimary)
            
            HStack(spacing: 12) {
                ForEach([ComplianceStatus.compliant, .needsReview, .nonCompliant], id: \.self) { status in
                    let isSelected = checkpoint.wrappedValue.status == status
                    Button(action: {
                        withAnimation(.spring()) {
                            checkpoint.wrappedValue.status = status
                        }
                    }) {
                        HStack {
                            Image(systemName: status.iconName)
                            Text(status.displayName)
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? status.color : RSMSTheme.surfacePrimary)
                        .foregroundColor(isSelected ? .white : status.color)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? .clear : status.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            
            if checkpoint.wrappedValue.status == .nonCompliant || checkpoint.wrappedValue.status == .needsReview {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Evidence Required")
                            .font(.caption.weight(.bold))
                            .foregroundColor(RSMSTheme.danger)
                        Spacer()
                        Button(action: {
                            editingCheckpointId = checkpoint.wrappedValue.id
                            showPhotoUpload = true
                        }) {
                            Label("Add Photo", systemImage: "camera.fill")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RSMSTheme.danger)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if !checkpoint.wrappedValue.photoUrls.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(checkpoint.wrappedValue.photoUrls, id: \.self) { urlString in
                                    AsyncImage(url: URL(string: urlString)) { phase in
                                        if let image = phase.image {
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.2))
                                        }
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func bindingForSelectedCheckpoint() -> Binding<[String]> {
        Binding {
            guard let id = editingCheckpointId,
                  let cp = checkpoints.first(where: { $0.id == id }) else {
                return uploadedPhotoUrls
            }
            return cp.photoUrls
        } set: { newUrls in
            if let id = editingCheckpointId,
               let index = checkpoints.firstIndex(where: { $0.id == id }) {
                checkpoints[index].photoUrls = newUrls
            } else {
                uploadedPhotoUrls = newUrls
            }
        }
    }
    
    private var zoneIcon: String {
        switch zone.type {
        case .table: return "table.furniture"
        case .wall: return "cabinet"
        case .window: return "rectangle.split.3x1"
        case .cashWrap: return "creditcard.and.123"
        }
    }
    
    private func saveCheck() {
        guard let storeId = appViewModel.currentStoreId else {
            alertMessage = "Store context is missing."
            showAlert = true
            return
        }
        
        guard let userId = appViewModel.currentUser?.id else {
            alertMessage = "User context is missing."
            showAlert = true
            return
        }
        
        // Find the store's active planogram
        guard let pId = viewModel.availablePlanograms.first?.id else {
            alertMessage = "No active Planogram found for this store."
            showAlert = true
            return
        }
        
        guard isFormComplete else {
            alertMessage = "Please complete all checkpoints before submitting."
            showAlert = true
            return
        }
        
        let finalStatus: ComplianceStatus
        if checkpoints.contains(where: { $0.status == .nonCompliant }) {
            finalStatus = .nonCompliant
        } else if checkpoints.contains(where: { $0.status == .needsReview }) {
            finalStatus = .needsReview
        } else {
            finalStatus = .compliant
        }
        
        var formattedNotes = "[Zone: \(zone.name)]\n[Checkpoints]\n"
        for cp in checkpoints {
            let icon: String
            if cp.status == .compliant { icon = "✅" }
            else if cp.status == .nonCompliant { icon = "❌" }
            else { icon = "⚠️" }
            formattedNotes += "\(icon) \(cp.title)\n"
        }
        
        if !notes.isEmpty {
            formattedNotes += "\n[Inspector Notes]\n\(notes)"
        }
        
        var allPhotos = uploadedPhotoUrls
        for cp in checkpoints {
            allPhotos.append(contentsOf: cp.photoUrls)
        }
        
        let newCheck = ComplianceCheck(
            id: UUID(),
            storeId: storeId,
            planogramId: pId,
            checkedBy: userId,
            status: finalStatus,
            notes: formattedNotes,
            photoURLs: allPhotos.isEmpty ? nil : allPhotos,
            checkedAt: Date()
        )
        
        isSubmitting = true
        Task {
            do {
                try await viewModel.createCheck(newCheck)
                dismiss()
            } catch {
                isSubmitting = false
                alertMessage = "Failed to save: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}
