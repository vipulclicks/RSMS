//
//  ComplianceDashboardView.swift
//  RSMS
//

import SwiftUI

struct ComplianceDashboardView: View {
    @State private var viewModel = ComplianceDashboardViewModel()
    @Environment(AppViewModel.self) private var appViewModel
    
    // Navigation state
    @State private var showAuditTemplates = false
    @State private var showIssueTracker = false
    
    // Colors
    private let textPrimary = Color.black.opacity(0.85)
    private let textSecondary = Color.gray
    private let backgroundGray = Color(white: 0.96)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    
                    if viewModel.isLoading {
                        ProgressView("Loading Dashboard...")
                            .padding(.top, 40)
                    } else {
                        kpiGrid
                        quickActions
                        
                        HStack(alignment: .top, spacing: 24) {
                            openIssuesPanel
                            recentAuditsPanel
                        }
                    }
                }
                .padding(32)
            }
            .background(backgroundGray)
            .navigationTitle("Store Compliance")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let storeId = appViewModel.currentStoreId {
                    Task {
                        await viewModel.loadDashboard(for: storeId)
                    }
                }
            }
            .navigationDestination(isPresented: $showAuditTemplates) {
                ChecklistLibraryView()
            }
            .navigationDestination(isPresented: $showIssueTracker) {
                Text("Issue Tracker View Coming Soon")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Compliance Overview")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(textPrimary)
                Text("Track adherence to VM guidelines and operational standards.")
                    .font(.system(size: 15))
                    .foregroundColor(textSecondary)
            }
            Spacer()
            
            Button(action: {
                showAuditTemplates = true
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Start Audit")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(RSMSTheme.primary)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
    }
    
    private var kpiGrid: some View {
        HStack(spacing: 20) {
            ComplianceKPICard(title: "Overall Score", value: String(format: "%.1f%%", viewModel.overallScore), icon: "chart.bar.fill", color: .green)
            ComplianceKPICard(title: "Open Issues", value: "\(viewModel.openIssuesCount)", icon: "exclamationmark.triangle.fill", color: .orange)
            ComplianceKPICard(title: "Audits Due Today", value: "\(viewModel.auditsDueTodayCount)", icon: "calendar.badge.exclamationmark", color: .red)
            
            let dateStr = viewModel.lastAuditDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A"
            ComplianceKPICard(title: "Last Audit", value: dateStr, icon: "clock.fill", color: .blue)
        }
    }
    
    private var quickActions: some View {
        HStack(spacing: 20) {
            QuickActionButton(title: "Issue Tracker", icon: "list.bullet.rectangle", color: .orange) {
                showIssueTracker = true
            }
            QuickActionButton(title: "Reports", icon: "doc.text.fill", color: .blue) {}
            QuickActionButton(title: "Schedule", icon: "calendar", color: .purple) {}
            QuickActionButton(title: "Analytics", icon: "chart.pie.fill", color: .green) {}
        }
    }
    
    private var openIssuesPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Issues")
                    .font(.headline)
                Spacer()
                Button("View All") { showIssueTracker = true }
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.primary)
            }
            
            VStack(spacing: 12) {
                if viewModel.openIssues.isEmpty {
                    Text("No open issues!")
                        .foregroundColor(.gray)
                        .padding(.vertical, 20)
                } else {
                    ForEach(viewModel.openIssues.prefix(4)) { issue in
                        HStack {
                            Circle()
                                .fill(issue.severity.color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(issue.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(issue.location)
                                    .font(.caption)
                                    .foregroundColor(textSecondary)
                            }
                            Spacer()
                            Text(issue.status.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.02), radius: 2)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private var recentAuditsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Audits")
                    .font(.headline)
                Spacer()
                Button("History") { }
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.primary)
            }
            
            VStack(spacing: 12) {
                if viewModel.recentActivity.isEmpty {
                    Text("No recent audits.")
                        .foregroundColor(.gray)
                        .padding(.vertical, 20)
                } else {
                    ForEach(viewModel.recentActivity.prefix(4)) { audit in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Audit Completed")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(audit.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(textSecondary)
                            }
                            Spacer()
                            if let score = audit.score {
                                Text(String(format: "%.0f%%", score))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(score >= 90 ? .green : (score >= 70 ? .orange : .red))
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.02), radius: 2)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Shared Components

struct ComplianceKPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .fontWeight(.medium)
                    .foregroundColor(.black.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.03), radius: 4)
        }
    }
}
