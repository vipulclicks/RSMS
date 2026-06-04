//
//  CreateComplianceCheckView.swift
//  RSMS
//

import SwiftUI

struct CreateComplianceCheckView: View {
    @Bindable var viewModel: ComplianceViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var status: ComplianceStatus = .compliant
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var selectedPlanogramId: UUID? = nil
    
    // Error handling
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // For photo upload
    @State private var showPhotoUpload = false
    @State private var uploadedPhotoUrls: [String] = []
    
    var body: some View {
        Form {
            Section(header: Text("Check Details")) {
                Picker("Status", selection: $status) {
                    ForEach(ComplianceStatus.allCases, id: \.self) { s in
                        HStack {
                            Image(systemName: s.iconName)
                                .foregroundColor(s.color)
                            Text(s.displayName)
                        }.tag(s)
                    }
                }
                
                if !viewModel.availablePlanograms.isEmpty {
                    Picker("Planogram", selection: $selectedPlanogramId) {
                        Text("Select Planogram").tag(UUID?.none)
                        ForEach(viewModel.availablePlanograms) { p in
                            Text(p.name).tag(p.id as UUID?)
                        }
                    }
                } else {
                    Text("No Planograms Available")
                        .foregroundColor(RSMSTheme.textTertiary)
                }
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
            
            Section(header: Text("Evidence")) {
                if !uploadedPhotoUrls.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(uploadedPhotoUrls, id: \.self) { url in
                                VStack {
                                    Image(systemName: "photo.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(RSMSTheme.primary)
                                        .frame(width: 60, height: 60)
                                        .background(RSMSTheme.surfaceSecondary)
                                        .cornerRadius(8)
                                    Text("Uploaded")
                                        .font(.caption2)
                                        .foregroundColor(RSMSTheme.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Button(action: {
                    showPhotoUpload = true
                }) {
                    Label("Manage Photos", systemImage: "camera.fill")
                        .foregroundColor(RSMSTheme.primary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("New Check")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveCheck()
                }
                .fontWeight(.bold)
                .disabled(isSubmitting)
            }
        }
        .sheet(isPresented: $showPhotoUpload) {
            EvidenceUploadView(photoUrls: $uploadedPhotoUrls, viewModel: viewModel)
        }
        .alert("Cannot Save", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isSubmitting {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Saving Check...")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(32)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 20)
                }
            }
        }
    }
    
    private func saveCheck() {
        guard let storeId = appViewModel.currentStoreId else {
            alertMessage = "Store context is missing. Please ensure you are assigned to a store."
            showAlert = true
            return
        }
        
        guard let userId = appViewModel.currentUser?.id else {
            alertMessage = "User context is missing. Please ensure you are logged in."
            showAlert = true
            return
        }
        
        guard let pId = selectedPlanogramId else {
            alertMessage = "Please select a Planogram before saving."
            showAlert = true
            return
        }
        
        let newCheck = ComplianceCheck(
            id: UUID(),
            storeId: storeId,
            planogramId: pId,
            checkedBy: userId,
            status: status,
            notes: notes.isEmpty ? nil : notes,
            photoURLs: uploadedPhotoUrls.isEmpty ? nil : uploadedPhotoUrls,
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
