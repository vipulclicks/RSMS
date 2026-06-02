//
//  ComplianceDashboardView.swift
//  RSMS
//

import SwiftUI

struct ComplianceDashboardView: View {
    @State private var viewModel = ComplianceViewModel()
    @Environment(AppViewModel.self) private var appViewModel
    
    // Navigation routes
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Store Compliance Heatmap")
                            .font(.system(size: 28, weight: .bold, design: .default))
                        Text("Monitor your store's merchandising compliance.")
                            .font(.system(size: 16))
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            navPath.append(ComplianceRoute.needsReviewQueue)
                        }) {
                            Label("Issue Board", systemImage: "square.split.2x1")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(RSMSTheme.primaryDark)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // KPI Row
                let checks = viewModel.complianceChecks
                let total = checks.count
                let compliant = checks.filter { $0.status == .compliant }.count
                let complianceRate = total > 0 ? Int((Double(compliant) / Double(total)) * 100) : 0
                let openIssues = checks.filter { $0.status == .nonCompliant || $0.status == .needsReview }.count
                
                HStack(spacing: 16) {
                    kpiCard(title: "Compliance Rate", value: "\(complianceRate)%", icon: "percent", color: complianceRate >= 90 ? RSMSTheme.success : RSMSTheme.warning)
                    
                    Button(action: {
                        navPath.append(ComplianceRoute.needsReviewQueue)
                    }) {
                        kpiCard(title: "Open Issues", value: "\(openIssues)", icon: "exclamationmark.triangle.fill", color: openIssues > 0 ? RSMSTheme.danger : RSMSTheme.success)
                    }
                    .buttonStyle(.plain)
                    
                    kpiCard(title: "Total Checks", value: "\(total)", icon: "checklist", color: RSMSTheme.info)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                
                // Legend
                HStack(spacing: 24) {
                    legendItem(color: RSMSTheme.info, title: "Compliant", subtitle: "Matches guidelines exactly")
                    legendItem(color: RSMSTheme.danger, title: "Non-Compliant", subtitle: "Requires immediate fixes")
                    legendItem(color: RSMSTheme.warning, title: "Needs Review", subtitle: "Manager review needed")
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                Divider()
                
                // Heatmap
                ComplianceHeatmapView(complianceVM: viewModel) { zone, latestCheck in
                    navPath.append(ComplianceRoute.zoneReference(zone))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(32)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Store Compliance")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.fetchChecks(for: appViewModel.currentStoreId)
                }
            }
            .navigationDestination(for: ComplianceRoute.self) { route in
                switch route {
                case .checkList:
                    ComplianceCheckListView(viewModel: viewModel)
                case .createCheck:
                    CreateComplianceCheckView(viewModel: viewModel)
                case .details(let check):
                    ComplianceCheckDetailsView(viewModel: viewModel, check: check)
                case .nonCompliantQueue:
                    NonCompliantFindingsView(viewModel: viewModel)
                case .needsReviewQueue:
                    ComplianceIssueBoardView(viewModel: viewModel)
                case .history:
                    ComplianceHistoryView(viewModel: viewModel)
                case .reports:
                    ComplianceReportView(viewModel: viewModel)
                case .inspectionWorkspace:
                    ComplianceInspectionSplitView(viewModel: viewModel)
                case .zoneReference(let zone):
                    ZoneReferenceView(viewModel: viewModel, zone: zone)
                case .inspectionForm(let zone):
                    InspectionWorkspaceView(viewModel: viewModel, zone: zone)
                }
            }
        }
    }
    
    private func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.textSecondary)
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSTheme.textPrimary)
            }
            Spacer()
        }
        .padding()
        .background(RSMSTheme.surfacePrimary)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 10, y: 4)
    }
    
    private func legendItem(color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Circle().fill(color).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundColor(RSMSTheme.textPrimary)
                Text(subtitle).font(.caption).foregroundColor(RSMSTheme.textSecondary)
            }
        }
    }
}

// MARK: - Navigation Routes

enum ComplianceRoute: Hashable {
    case checkList
    case createCheck
    case details(ComplianceCheck)
    case nonCompliantQueue
    case needsReviewQueue
    case history
    case reports
    case inspectionWorkspace
    case zoneReference(MerchandisingZone)
    case inspectionForm(MerchandisingZone)
}
