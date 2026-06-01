//
//  ComplianceCheckListView.swift
//  RSMS
//

import SwiftUI

struct ComplianceCheckListView: View {
    @Bindable var viewModel: ComplianceViewModel
    @State private var searchText = ""
    @State private var filterStatus: ComplianceStatus? = nil
    @State private var sortOption: SortOption = .dateDesc
    
    enum SortOption: String, CaseIterable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case status = "Status"
    }
    
    var filteredChecks: [ComplianceCheck] {
        var checks = viewModel.complianceChecks
        
        if let status = filterStatus {
            checks = checks.filter { $0.status == status }
        }
        
        if !searchText.isEmpty {
            checks = checks.filter { $0.notes?.localizedCaseInsensitiveContains(searchText) == true }
        }
        
        switch sortOption {
        case .dateDesc:
            checks.sort { $0.checkedAt > $1.checkedAt }
        case .dateAsc:
            checks.sort { $0.checkedAt < $1.checkedAt }
        case .status:
            checks.sort { $0.status.rawValue < $1.status.rawValue }
        }
        
        return checks
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tint(RSMSTheme.primary)
            } else if viewModel.complianceChecks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(RSMSTheme.textTertiary)
                    Text("No Compliance Checks Found")
                        .font(.title2)
                        .foregroundColor(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredChecks) { check in
                    NavigationLink {
                        ComplianceCheckDetailsView(viewModel: viewModel, check: check)
                    } label: {
                        ComplianceCheckListRow(check: check)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Compliance Checks")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search notes...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    
                    Divider()
                    
                    Picker("Filter Status", selection: $filterStatus) {
                        Text("All").tag(ComplianceStatus?.none)
                        ForEach(ComplianceStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status as ComplianceStatus?)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

struct ComplianceCheckListRow: View {
    let check: ComplianceCheck
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(check.status.color)
                .frame(width: 12, height: 12)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(check.status.displayName)
                    .font(.headline)
                    .foregroundColor(check.status.color)
                
                HStack {
                    Label(check.checkedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    Spacer()
                    Label("Photos: \(check.photoURLs?.count ?? 0)", systemImage: "photo")
                }
                .font(.caption)
                .foregroundColor(RSMSTheme.textSecondary)
                
                if let notes = check.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(RSMSTheme.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(RSMSTheme.surfacePrimary)
        .cornerRadius(8)
        .padding(.vertical, 4)
    }
}
