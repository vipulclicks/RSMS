//
//  ComplianceIssueBoardView.swift
//  RSMS
//

import SwiftUI
import UniformTypeIdentifiers

struct ComplianceIssueBoardView: View {
    var viewModel: ComplianceViewModel
    
    // We maintain local state for immediate drag-and-drop feedback,
    // and then sync it with the database.
    @State private var columns: [ComplianceStatus: [ComplianceCheck]] = [
        .needsReview: [],
        .nonCompliant: [],
        .compliant: []
    ]
    enum BoardFilter: String, CaseIterable {
        case unsolved = "Unsolved"
        case solved = "Solved"
    }
    
    @State private var selectedFilter: BoardFilter = .unsolved
    
    var body: some View {
        let _ = viewModel.complianceChecks // Force SwiftUI observation tracking
        VStack(spacing: 24) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(BoardFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)
            .padding(.bottom, 8)
            
            HStack(spacing: 24) {
                if selectedFilter == .unsolved {
                    boardColumn(title: "Needs Review", status: .needsReview)
                    boardColumn(title: "Non-Compliant", status: .nonCompliant)
                } else {
                    boardColumn(title: "Solved", status: .compliant)
                }
            }
        }
        .padding(32)
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Issue Board")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadColumns()
        }
        .onChange(of: viewModel.complianceChecks) { _, _ in
            loadColumns()
        }
    }
    
    // MARK: - Board Column
    
    private func boardColumn(title: String, status: ComplianceStatus) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Circle().fill(status.color).frame(width: 12, height: 12)
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(RSMSTheme.textPrimary)
                Spacer()
                Text("\(columns[status]?.count ?? 0)")
                    .font(.subheadline.bold())
                    .foregroundColor(RSMSTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 8)
            
            // Cards Drop Area
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(columns[status] ?? []) { check in
                        NavigationLink(value: ComplianceRoute.details(check)) {
                            IssueCard(check: check, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                        .onDrag {
                            let itemProvider = NSItemProvider(object: check.id.uuidString as NSString)
                            return itemProvider
                        }
                    }
                    
                    // Empty drop target padding
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(status.color.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(status.color.opacity(0.2), lineWidth: 1)
        )
        // Enable dropping onto the entire column
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            handleDrop(providers: providers, targetStatus: status)
        }
    }
    
    // MARK: - Actions
    
    private func loadColumns() {
        columns[.needsReview] = viewModel.complianceChecks.filter { $0.status == .needsReview }
        columns[.nonCompliant] = viewModel.complianceChecks.filter { $0.status == .nonCompliant }
        columns[.compliant] = viewModel.complianceChecks.filter { $0.status == .compliant }
    }
    
    private func handleDrop(providers: [NSItemProvider], targetStatus: ComplianceStatus) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadObject(ofClass: NSString.self) { string, error in
            guard let uuidString = string as? String,
                  let checkId = UUID(uuidString: uuidString) else { return }
            
            DispatchQueue.main.async {
                // Find the check
                guard let check = viewModel.complianceChecks.first(where: { $0.id == checkId }) else { return }
                
                // If it's already in the target column, do nothing
                if check.status == targetStatus { return }
                
                // 1. Update local state immediately for snappy UI
                var updatedCheck = check
                updatedCheck.status = targetStatus
                
                // Remove from old column
                if let oldIndex = columns[check.status]?.firstIndex(where: { $0.id == checkId }) {
                    columns[check.status]?.remove(at: oldIndex)
                }
                
                // Add to new column
                columns[targetStatus]?.insert(updatedCheck, at: 0)
                
                // 2. Persist to Supabase
                Task {
                    do {
                        try await viewModel.updateCheck(updatedCheck)
                    } catch {
                        print("Failed to update status on drop: \(error)")
                        // If it fails, reload from source of truth
                        loadColumns()
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Issue Card

struct IssueCard: View {
    let check: ComplianceCheck
    let viewModel: ComplianceViewModel
    
    @Environment(AppViewModel.self) private var appVM
    
    // Extracted Zone Name if present in notes
    private var parsedZoneName: String? {
        guard let notes = check.notes else { return nil }
        if let range = notes.range(of: "\\[Zone: (.*?)\\]", options: .regularExpression) {
            let zoneString = String(notes[range])
            return zoneString.replacingOccurrences(of: "[Zone: ", with: "").replacingOccurrences(of: "]", with: "")
        }
        return nil
    }
    
    // Cleaned notes without the Zone tag
    private var cleanNotes: String? {
        guard let notes = check.notes else { return nil }
        return notes.replacingOccurrences(of: "\\[Zone: .*?\\]\n", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Zone Name & Planogram
            VStack(alignment: .leading, spacing: 6) {
                if let zone = parsedZoneName {
                    Text(zone)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSTheme.textPrimary)
                }
                
                let pId = check.planogramId
                if let planogram = viewModel.availablePlanograms.first(where: { $0.id == pId }) {
                    HStack(spacing: 4) {
                        Image(systemName: "map")
                        Text(planogram.name)
                    }
                    .font(.caption)
                    .foregroundColor(RSMSTheme.textSecondary)
                }
            }
            
            // Evidence Indicator
            if let urls = check.photoURLs, !urls.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.caption2)
                    Text("\(urls.count) Photos")
                        .font(.caption)
                }
                .foregroundColor(RSMSTheme.textSecondary)
                .padding(.top, 2)
            }
            
            Divider().padding(.vertical, 4)
            
            // Footer: Timestamp & Real Inspector
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(check.checkedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .foregroundColor(RSMSTheme.textSecondary)
                
                Spacer()
                
                // Real inspector initials pulled from DataStore
                let inspectorName = appVM.dataStore.userName(for: check.checkedBy)
                let initials = getInitials(from: inspectorName)
                
                HStack(spacing: 6) {
                    Text(inspectorName)
                        .font(.caption)
                        .foregroundColor(RSMSTheme.textSecondary)
                    
                    Text(initials)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(RSMSTheme.primaryDark))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "??"
    }
}
