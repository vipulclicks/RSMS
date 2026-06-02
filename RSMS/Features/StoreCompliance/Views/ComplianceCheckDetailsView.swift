//
//  ComplianceCheckDetailsView.swift
//  RSMS
//

import SwiftUI

struct ComplianceCheckDetailsView: View {
    @Bindable var viewModel: ComplianceViewModel
    let check: ComplianceCheck
    
    @Environment(AppViewModel.self) private var appVM
    
    @State private var showReport = false
    @State private var isUpdating = false
    @State private var selectedPhotoIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header Profile
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compliance Inspection")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(RSMSTheme.textPrimary)
                        
                        Text(check.checkedAt.formatted(date: .complete, time: .shortened))
                            .font(.title3)
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Large Status Badge
                    HStack(spacing: 8) {
                        Image(systemName: check.status.iconName)
                            .font(.system(size: 24))
                        Text(check.status.displayName)
                            .font(.system(size: 20, weight: .bold))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(check.status.color.opacity(0.15))
                    .foregroundColor(check.status.color)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(check.status.color.opacity(0.5), lineWidth: 2)
                    )
                }
                
                Divider()
                
                // Content
                HStack(alignment: .top, spacing: 32) {
                    // Left Column: Details
                    VStack(alignment: .leading, spacing: 24) {
                        detailCard(title: "Inspector Notes", icon: "doc.text") {
                            Text(check.notes ?? "No notes provided.")
                                .font(.body)
                                .foregroundColor(check.notes == nil ? .gray : RSMSTheme.textPrimary)
                        }
                        
                        detailCard(title: "Area Information", icon: "map") {
                            VStack(alignment: .leading, spacing: 12) {
                                let pId = check.planogramId
                                if let planogram = viewModel.availablePlanograms.first(where: { $0.id == pId }) {
                                    Text("Merchandising Zone: \(planogram.name)")
                                } else {
                                    Text("Zone ID: \(check.planogramId.uuidString)")
                                }
                                
                                let inspectorName = appVM.dataStore.userName(for: check.checkedBy)
                                Text("Inspector: \(inspectorName)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(maxWidth: 400)
                    
                    // Right Column: Evidence Gallery
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Evidence Gallery")
                            .font(.title2.bold())
                        
                        if let urls = check.photoURLs, !urls.isEmpty {
                            TabView(selection: $selectedPhotoIndex) {
                                ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                                    AsyncImage(url: URL(string: urlString)) { phase in
                                        if let image = phase.image {
                                            image.resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                    .tag(index)
                                }
                            }
                            .frame(height: 500)
                            .tabViewStyle(.page(indexDisplayMode: .always))
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(16)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "camera.on.rectangle")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No evidence provided during this inspection.")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 400)
                            .background(RSMSTheme.surfaceSecondary)
                            .cornerRadius(16)
                        }
                    }
                }
            }
            .padding(40)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Inspection Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(item: generateReportText()) {
                        Label("Share Report", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { showReport = true }) {
                        Label("Generate PDF (Placeholder)", systemImage: "doc.text")
                    }
                    Button(action: {}) {
                        Label("Edit", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(RSMSTheme.primary)
                }
            }
        }
        .navigationDestination(isPresented: $showReport) {
            ComplianceReportView(viewModel: viewModel)
        }
    }
    
    private func updateStatus(to newStatus: ComplianceStatus) {
        var updatedCheck = check
        updatedCheck.status = newStatus
        isUpdating = true
        Task {
            do {
                try await viewModel.updateCheck(updatedCheck)
            } catch {
                print(error)
            }
            isUpdating = false
        }
    }
    
    private func generateReportText() -> String {
        """
        Compliance Check Report
        Date: \(check.checkedAt.formatted(date: .long, time: .shortened))
        Status: \(check.status.displayName)
        
        Store ID: \(check.storeId.uuidString)
        Planogram ID: \(check.planogramId.uuidString)
        Inspector ID: \(check.checkedBy.uuidString)
        
        Notes:
        \(check.notes ?? "None")
        """
    }
    
    private func detailCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(RSMSTheme.primary)
                Text(title)
                    .font(.headline)
            }
            
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}
