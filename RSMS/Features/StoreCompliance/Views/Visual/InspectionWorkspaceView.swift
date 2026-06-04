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
        var notes: String = ""
    }
    
    @State private var checkpoints = [
        InspectionCheckpoint(title: "Planogram Accuracy"),
        InspectionCheckpoint(title: "Item Alignment & Spacing"),
        InspectionCheckpoint(title: "Lighting & Illumination"),
        InspectionCheckpoint(title: "Marketing Signage"),
        InspectionCheckpoint(title: "Display Cleanliness")
    ]
    
    @State private var notes: String = ""
    @State private var uploadedPhotoUrls: [String] = []
    @State private var editingCheckpointId: UUID? = nil
    
    @State private var showPhotoUpload = false
    @State private var isSubmitting = false
    @State private var showingSuccessMessage = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var isFormComplete: Bool {
        checkpoints.allSatisfy { $0.status != nil }
    }
    
    var body: some View {
        ZStack {
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
                    .background(RSMSTheme.background)
                }
            }
            
            if isSubmitting || showingSuccessMessage {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if showingSuccessMessage {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(RSMSTheme.success)
                            .transition(.scale.combined(with: .opacity))
                        
                        VStack(spacing: 8) {
                            Text("Report Submitted")
                                .font(.title3.bold())
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("The Inventory Controller has been notified.")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(RSMSTheme.primaryDark)
                        
                        Text("Submitting Report...")
                            .font(.title3.bold())
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                }
                .padding(40)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(40)
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
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Add notes explaining the issue...", text: checkpoint.notes, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.subheadline)
                        .padding(12)
                        .background(RSMSTheme.surfaceSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
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
        
        let fails = checkpoints.filter { $0.status == .nonCompliant }
        let reviews = checkpoints.filter { $0.status == .needsReview }
        let passes = checkpoints.filter { $0.status == .compliant }
        
        var checksToCreate: [ComplianceCheck] = []
        
        // 1. Non-Compliant Report
        if !fails.isEmpty {
            var formattedNotes = "[Zone: \(zone.name)]\n[Checkpoints]\n"
            for cp in fails + passes {
                let icon = cp.status == .nonCompliant ? "❌" : "✅"
                var line = "\(icon) \(cp.title)"
                if !cp.notes.isEmpty { line += " - \(cp.notes)" }
                formattedNotes += line + "\n"
            }
            if !notes.isEmpty { formattedNotes += "\n[Inspector Notes]\n\(notes)" }
            
            var allPhotos = uploadedPhotoUrls
            for cp in fails { allPhotos.append(contentsOf: cp.photoUrls) }
            
            checksToCreate.append(ComplianceCheck(
                id: UUID(), storeId: storeId, planogramId: pId, checkedBy: userId,
                status: .nonCompliant, notes: formattedNotes,
                photoURLs: allPhotos.isEmpty ? nil : allPhotos, checkedAt: Date()
            ))
        }
        
        // 2. Needs Review Report
        if !reviews.isEmpty {
            var formattedNotes = "[Zone: \(zone.name)]\n[Checkpoints]\n"
            for cp in reviews + (fails.isEmpty ? passes : []) {
                let icon = cp.status == .needsReview ? "⚠️" : "✅"
                var line = "\(icon) \(cp.title)"
                if !cp.notes.isEmpty { line += " - \(cp.notes)" }
                formattedNotes += line + "\n"
            }
            // Only attach main inspector notes and general photos if this is the only report generated
            if !notes.isEmpty && fails.isEmpty { formattedNotes += "\n[Inspector Notes]\n\(notes)" }
            var allPhotos = fails.isEmpty ? uploadedPhotoUrls : []
            for cp in reviews { allPhotos.append(contentsOf: cp.photoUrls) }
            
            checksToCreate.append(ComplianceCheck(
                id: UUID(), storeId: storeId, planogramId: pId, checkedBy: userId,
                status: .needsReview, notes: formattedNotes,
                photoURLs: allPhotos.isEmpty ? nil : allPhotos, checkedAt: Date()
            ))
        }
        
        // 3. Fully Compliant Report
        if fails.isEmpty && reviews.isEmpty {
            var formattedNotes = "[Zone: \(zone.name)]\n[Checkpoints]\n"
            for cp in checkpoints {
                formattedNotes += "✅ \(cp.title)\n"
            }
            if !notes.isEmpty { formattedNotes += "\n[Inspector Notes]\n\(notes)" }
            
            checksToCreate.append(ComplianceCheck(
                id: UUID(), storeId: storeId, planogramId: pId, checkedBy: userId,
                status: .compliant, notes: formattedNotes,
                photoURLs: uploadedPhotoUrls.isEmpty ? nil : uploadedPhotoUrls, checkedAt: Date()
            ))
        }
        
        isSubmitting = true
        Task {
            do {
                // Fetch staff to find the Inventory Controller
                try? await appViewModel.dataStore.fetchUsers(storeId: storeId)
                let inventoryControllers = appViewModel.dataStore.users.filter { $0.role == .inventoryController }
                
                for check in checksToCreate {
                    try await viewModel.createCheck(check)
                    
                    for ic in inventoryControllers {
                        try? await appViewModel.dataStore.createNotification(
                            recipientId: ic.id,
                            title: "Compliance Check Submitted",
                            message: "A new compliance check was submitted for \(zone.name). Status: \(check.status.displayName)",
                            type: .complianceAlert,
                            relatedEntityId: check.id
                        )
                    }
                }
                
                await MainActor.run {
                    isSubmitting = false
                    withAnimation(.spring()) {
                        showingSuccessMessage = true
                    }
                }
                
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Show message for 2 seconds
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = "Failed to save: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
