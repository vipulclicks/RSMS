//
//  ComplianceInspectionSplitView.swift
//  RSMS
//

import SwiftUI

struct ComplianceInspectionSplitView: View {
    @Bindable var viewModel: ComplianceViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var status: ComplianceStatus = .compliant
    @State private var notes: String = ""
    @State private var photoUrls: [String] = []
    @State private var selectedPlanogramId: UUID? = nil
    
    // Error handling
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSubmitting = false
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT PANEL: Input Form
            VStack(alignment: .leading, spacing: 16) {
                Text("Inspection Checklist")
                    .font(.title2.bold())
                    .foregroundColor(RSMSTheme.textPrimary)
                    .padding()
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading) {
                            Text("Evaluation")
                                .font(.headline)
                                .foregroundColor(RSMSTheme.textSecondary)
                            
                            Picker("Status", selection: $status) {
                                ForEach(ComplianceStatus.allCases, id: \.self) { s in
                                    Text(s.displayName).tag(s)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(RSMSTheme.textSecondary)
                            TextEditor(text: $notes)
                                .frame(height: 150)
                                .padding(8)
                                .background(RSMSTheme.surfacePrimary)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(RSMSTheme.border))
                        }
                    }
                    .padding()
                }
            }
            .frame(width: 320)
            .background(RSMSTheme.surfacePrimary)
            
            Divider()
            
            // CENTER PANEL: Planogram Visualizer
            VStack {
                HStack {
                    Text("Store Display")
                        .font(.headline)
                        .foregroundColor(RSMSTheme.textPrimary)
                    
                    Spacer()
                    
                    if !viewModel.availablePlanograms.isEmpty {
                        Picker("Planogram", selection: $selectedPlanogramId) {
                            Text("Select Planogram").tag(UUID?.none)
                            ForEach(viewModel.availablePlanograms) { p in
                                Text(p.name).tag(p.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(RSMSTheme.primary)
                    }
                }
                .padding()
                
                Spacer()
                
                if let selectedId = selectedPlanogramId,
                   let planogram = viewModel.availablePlanograms.first(where: { $0.id == selectedId }),
                   let urlString = planogram.imageUrl,
                   let url = URL(string: urlString) {
                    
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Image(systemName: "photo.artframe")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(RSMSTheme.textTertiary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding()
                    
                } else {
                    Image(systemName: "photo.artframe")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .foregroundColor(RSMSTheme.textTertiary)
                    Text("Select a planogram to view layout")
                        .foregroundColor(RSMSTheme.textSecondary)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(RSMSTheme.background)
            
            Divider()
            
            // RIGHT PANEL: Evidence
            VStack(alignment: .leading, spacing: 16) {
                Text("Evidence")
                    .font(.title2.bold())
                    .foregroundColor(RSMSTheme.textPrimary)
                    .padding()
                
                Divider()
                
                EvidenceUploadView(photoUrls: $photoUrls, viewModel: viewModel)
            }
            .frame(width: 320)
            .background(RSMSTheme.surfacePrimary)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save Check") {
                    saveCheck()
                }
                .fontWeight(.bold)
                .disabled(isSubmitting)
            }
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
                            .foregroundColor(RSMSTheme.textPrimary)
                    }
                    .padding(32)
                    .background(RSMSTheme.surfacePrimary)
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
            photoURLs: photoUrls.isEmpty ? nil : photoUrls,
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
