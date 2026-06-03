//
//  ComplianceCheckDetailsView.swift
//  RSMS
//

import SwiftUI

struct ComplianceCheckDetailsView: View {
    @Bindable var viewModel: ComplianceViewModel
    @State private var check: ComplianceCheck
    
    init(viewModel: ComplianceViewModel, check: ComplianceCheck) {
        self.viewModel = viewModel
        self._check = State(initialValue: check)
    }
    
    @Environment(AppViewModel.self) private var appVM
    
    @State private var showReport = false
    @State private var isUpdating = false
    @State private var selectedPhotoIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header Profile
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Inspection Report")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(RSMSTheme.textPrimary)
                        
                        Text(check.checkedAt.formatted(date: .complete, time: .shortened))
                            .font(.title3.weight(.medium))
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Large Status Badge
                    HStack(spacing: 8) {
                        Image(systemName: check.status.iconName)
                            .font(.system(size: 24, weight: .bold))
                        Text(check.status.displayName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(check.status.color.opacity(0.15))
                    .foregroundColor(check.status.color)
                    .clipShape(Capsule())
                }
                
                let parsed = parsedNotes
                
                // Content
                HStack(alignment: .top, spacing: 40) {
                    // Left Column: Details
                    VStack(alignment: .leading, spacing: 24) {
                        
                        detailCard(title: "Inspection Details", icon: "info.circle.fill") {
                            VStack(alignment: .leading, spacing: 16) {
                                let pId = check.planogramId
                                let planogramName = viewModel.availablePlanograms.first(where: { $0.id == pId })?.name ?? "Unknown Zone"
                                let zoneName = parsed.zone ?? planogramName
                                
                                infoRow(title: "Merchandising Zone", value: zoneName)
                                infoRow(title: "Inspector", value: appVM.dataStore.userName(for: check.checkedBy))
                                infoRow(title: "Report ID", value: String(check.id.uuidString.prefix(8)))
                            }
                        }
                        
                        if check.status == .compliant {
                            if !parsed.checkpoints.isEmpty {
                                checkpointListCard(title: "Checkpoints", icon: "checklist", items: parsed.checkpoints)
                            }
                        } else {
                            let fails = parsed.checkpoints.filter { $0.status == "❌" }
                            let reviews = parsed.checkpoints.filter { $0.status == "⚠️" }
                            
                            if !fails.isEmpty {
                                checkpointListCard(title: "Non-Compliant", icon: "xmark.circle.fill", iconColor: RSMSTheme.danger, items: fails) { text, oldStatus in
                                    resolveCheckpoint(text: text, oldStatus: oldStatus)
                                }
                            }
                            
                            if !reviews.isEmpty {
                                checkpointListCard(title: "Needs Review", icon: "exclamationmark.triangle.fill", iconColor: RSMSTheme.warning, items: reviews) { text, oldStatus in
                                    resolveCheckpoint(text: text, oldStatus: oldStatus)
                                }
                            }
                        }
                        
                        if let notes = parsed.inspectorNotes, !notes.isEmpty {
                            detailCard(title: "Inspector Notes", icon: "note.text") {
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(RSMSTheme.textSecondary)
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.06))
                                    .cornerRadius(12)
                            }
                        }
                        
                    }
                    .frame(maxWidth: 450)
                    
                    // Right Column: Evidence Gallery
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Evidence Gallery")
                            .font(.title2.bold())
                            .foregroundColor(RSMSTheme.textPrimary)
                        
                        if let urls = check.photoURLs, !urls.isEmpty {
                            TabView(selection: $selectedPhotoIndex) {
                                ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                                    AsyncImage(url: URL(string: urlString)) { phase in
                                        if let image = phase.image {
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                    .tag(index)
                                }
                            }
                            .frame(height: 550)
                            .tabViewStyle(.page(indexDisplayMode: .always))
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(24)
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                        } else {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(RSMSTheme.surfacePrimary)
                                        .frame(width: 120, height: 120)
                                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                                    Image(systemName: "camera.badge.ellipsis")
                                        .font(.system(size: 48, weight: .light))
                                        .foregroundColor(RSMSTheme.primaryDark.opacity(0.6))
                                }
                                Text("No Photographic Evidence")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(RSMSTheme.textPrimary)
                                Text("This inspection was logged without attaching any photos.")
                                    .font(.subheadline)
                                    .foregroundColor(RSMSTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 550)
                            .background(RSMSTheme.surfaceSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(RSMSTheme.border.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                            )
                            .cornerRadius(24)
                        }
                    }
                }
            }
            .padding(40)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(item: generateReportText()) {
                        Label("Share Report", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { showReport = true }) {
                        Label("Generate PDF", systemImage: "doc.text")
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
    
    // MARK: - Components & Helpers
    
    private var parsedNotes: (zone: String?, checkpoints: [(status: String, text: String)], inspectorNotes: String?) {
        let text = check.notes ?? ""
        var zone: String?
        var checkpoints: [(status: String, text: String)] = []
        var inspectorNotes: String?
        
        let lines = text.components(separatedBy: .newlines)
        var currentSection = ""
        
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("[Zone:") {
                zone = t.replacingOccurrences(of: "[Zone: ", with: "").replacingOccurrences(of: "]", with: "")
            } else if t == "[Checkpoints]" {
                currentSection = "checkpoints"
            } else if t == "[Inspector Notes]" {
                currentSection = "notes"
            } else if !t.isEmpty {
                if currentSection == "checkpoints" {
                    if t.hasPrefix("✅") || t.hasPrefix("❌") || t.hasPrefix("⚠️") {
                        let status = String(t.prefix(1))
                        let textContent = String(t.dropFirst(2))
                        checkpoints.append((status, textContent))
                    } else {
                        checkpoints.append(("", t))
                    }
                } else if currentSection == "notes" {
                    if inspectorNotes == nil { inspectorNotes = "" }
                    inspectorNotes! += t + "\n"
                }
            }
        }
        
        return (zone, checkpoints, inspectorNotes?.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(RSMSTheme.textSecondary)
                .frame(width: 150, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(RSMSTheme.textPrimary)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func checkpointListCard(title: String, icon: String, iconColor: Color = RSMSTheme.primary, items: [(status: String, text: String)], onResolve: ((String, String) -> Void)? = nil) -> some View {
        detailCard(title: title, icon: icon, iconColor: iconColor) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(items.indices, id: \.self) { i in
                    let cp = items[i]
                    HStack(alignment: .top, spacing: 16) {
                        let isCompliant = cp.status == "✅"
                        let isFail = cp.status == "❌"
                        
                        Image(systemName: isCompliant ? "checkmark.circle.fill" : (isFail ? "xmark.circle.fill" : "exclamationmark.triangle.fill"))
                            .foregroundColor(isCompliant ? RSMSTheme.success : (isFail ? RSMSTheme.danger : RSMSTheme.warning))
                            .font(.system(size: 22))
                        Text(cp.text)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(RSMSTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                            
                        Spacer()
                        
                        if appVM.currentUser?.role == .inventoryController && !isCompliant && onResolve != nil {
                            Button(action: {
                                withAnimation {
                                    onResolve?(cp.text, cp.status)
                                }
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Resolve")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(RSMSTheme.success)
                            .clipShape(Capsule())
                        }
                    }
                    if i < items.count - 1 {
                        Divider().padding(.leading, 38)
                    }
                }
            }
        }
    }
    
    private func detailCard<Content: View>(title: String, icon: String, iconColor: Color = RSMSTheme.primary, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(RSMSTheme.textPrimary)
            }
            .padding(.bottom, 8)
            
            content()
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 15, y: 5)
    }
    
    private func resolveCheckpoint(text: String, oldStatus: String) {
        guard let notes = check.notes else { return }
        
        let targetLine = "\(oldStatus) \(text)"
        let replacementLine = "✅ \(text)"
        
        let newNotes = notes.replacingOccurrences(of: targetLine, with: replacementLine)
        check.notes = newNotes
        
        let p = parsedNotes
        let hasFails = p.checkpoints.contains(where: { $0.status == "❌" })
        let hasWarnings = p.checkpoints.contains(where: { $0.status == "⚠️" })
        
        if !hasFails && !hasWarnings {
            check.status = .compliant
        } else if !hasFails {
            check.status = .needsReview
        }
        
        updateStatus(to: check.status)
    }

    private func updateStatus(to newStatus: ComplianceStatus) {
        check.status = newStatus
        isUpdating = true
        Task {
            do {
                try await viewModel.updateCheck(check)
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
}
