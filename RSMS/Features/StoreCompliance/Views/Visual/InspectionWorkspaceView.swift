//
//  InspectionWorkspaceView.swift
//  RSMS
//

import SwiftUI

struct InspectionWorkspaceView: View {
    @Bindable var viewModel: ComplianceViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Log Compliance Check")
                                .font(.largeTitle.bold())
                                .foregroundStyle(RSMSTheme.textPrimary)
                                
                            HStack(spacing: 8) {
                                Circle().fill(RSMSTheme.success).frame(width: 8, height: 8)
                                let storeCode = appViewModel.dataStore.stores.first(where: { $0.id == appViewModel.currentStoreId })?.code ?? "Unknown"
                                Text("Audit ongoing for \(zone.name) • Store \(storeCode)")
                                    .font(.subheadline)
                                    .foregroundColor(RSMSTheme.textSecondary)
                            }
                        }
                        
                        if horizontalSizeClass == .regular {
                            HStack(alignment: .top, spacing: 32) {
                                // Left Column
                                VStack(alignment: .leading, spacing: 20) {
                                    ForEach(Array($checkpoints.enumerated()), id: \.element.id) { index, $checkpoint in
                                        checkpointRow(for: $checkpoint, index: index)
                                    }
                                }
                                
                                // Right Column
                                VStack(alignment: .leading, spacing: 20) {
                                    evidencePhotosCard
                                    inspectorNotesCard
                                }
                                .frame(width: 400)
                            }
                        } else {
                            // Single Column
                            VStack(alignment: .leading, spacing: 20) {
                                ForEach(Array($checkpoints.enumerated()), id: \.element.id) { index, $checkpoint in
                                    checkpointRow(for: $checkpoint, index: index)
                                }
                                evidencePhotosCard
                                inspectorNotesCard
                            }
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
                    .padding(horizontalSizeClass == .compact ? 20 : 40)
                }
                .frame(maxWidth: .infinity)
                .background(RSMSTheme.background)
            }
            
            if isSubmitting || showingSuccessMessage {
                Color.black.opacity(0.4)
                
                VStack(spacing: 24) {
                    if showingSuccessMessage {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(RSMSTheme.success)
                            .transition(.scale.combined(with: .opacity))
                        
                        VStack(spacing: 8) {
                            Text("Success")
                                .font(.title3.bold())
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("Notification is sent to the Supporting staff")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                        .font(.headline)
                        .padding(.top, 8)
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
    
    private func checkpointRow(for checkpoint: Binding<InspectionCheckpoint>, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(checkpoint.wrappedValue.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(RSMSTheme.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 4) {
                ForEach([ComplianceStatus.compliant, .needsReview, .nonCompliant], id: \.self) { status in
                    let isSelected = checkpoint.wrappedValue.status == status
                    let displayName: String = {
                        switch status {
                        case .compliant: return "Compliant"
                        case .needsReview: return "Review"
                        case .nonCompliant: return "Failed"
                        }
                    }()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            checkpoint.wrappedValue.status = status
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: status.iconName)
                                .foregroundColor(status.color)
                            Text(displayName)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? RSMSTheme.background : Color.clear)
                        .foregroundColor(isSelected ? RSMSTheme.textPrimary : RSMSTheme.textTertiary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? status.color.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color.black.opacity(0.05) : .clear, radius: 2, x: 0, y: 1)
                    }
                }
            }
            
            if checkpoint.wrappedValue.status == .nonCompliant || checkpoint.wrappedValue.status == .needsReview {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Add notes explaining the issue...", text: checkpoint.notes, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.subheadline)
                        .padding(12)
                        .background(RSMSTheme.background)
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
                                .background(RSMSTheme.primaryDark)
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
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
    }

    private var evidencePhotosCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("EVIDENCE PHOTOS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .tracking(1.0)
                Spacer()
                Button(action: { showPhotoUpload = true }) {
                    Label("Add Photo", systemImage: "camera.fill")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RSMSTheme.primaryDark)
                        .clipShape(Capsule())
                }
            }
            
            if uploadedPhotoUrls.isEmpty {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(RSMSTheme.surfaceSecondary)
                            .frame(width: 60, height: 60)
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(RSMSTheme.textTertiary)
                    }
                    Text("No evidence attached")
                        .font(.subheadline.bold())
                        .foregroundColor(RSMSTheme.textPrimary)
                    Text("Drag and drop or tap to upload")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(RSMSTheme.surfacePrimary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.border, style: StrokeStyle(lineWidth: 2, dash: [6]))
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
            
            if uploadedPhotoUrls.isEmpty {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8).fill(RSMSTheme.surfaceSecondary).frame(width: 60, height: 60)
                        .overlay(Image(systemName: "camera").foregroundColor(RSMSTheme.textTertiary))
                    RoundedRectangle(cornerRadius: 8).fill(RSMSTheme.surfaceSecondary).frame(width: 60, height: 60)
                        .overlay(Image(systemName: "camera").foregroundColor(RSMSTheme.textTertiary))
                }
            }
        }
        .padding(24)
        .background(RSMSTheme.surfacePrimary)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }

    private var inspectorNotesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("INSPECTOR NOTES")
                .font(.caption.weight(.bold))
                .foregroundStyle(RSMSTheme.textSecondary)
                .tracking(1.0)
            
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $notes)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(12)
                    .background(RSMSTheme.background)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
                
                Text("\(notes.count) / 500")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.textTertiary)
                    .padding(12)
            }
            .overlay(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Add small notes here...")
                        .font(.subheadline)
                        .foregroundColor(RSMSTheme.textTertiary)
                        .padding(16)
                        .padding(.top, 4)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(24)
        .background(RSMSTheme.surfacePrimary)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
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
