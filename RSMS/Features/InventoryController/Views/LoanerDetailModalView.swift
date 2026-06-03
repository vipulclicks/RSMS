import SwiftUI

struct LoanerDetailModalView: View {
    @Bindable var viewModel: LoanerProductManagementViewModel
    let assignment: LoanerAssignment
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        infoCard
                        workflowSection
                        recentActivitySection
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Assignment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        let allowedStatuses: [LoanerStatus] = [.assigned, .returned, .overdue, .available]
                        ForEach(allowedStatuses) { status in
                            if status.rawValue != assignment.status {
                                Button(status.rawValue) {
                                    Task {
                                        await viewModel.updateAssignmentStatus(
                                            assignment: assignment,
                                            newStatus: status,
                                            dataStore: appViewModel.dataStore
                                        )
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Update Status")
                                .font(.subheadline.bold())
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(RSMSTheme.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(RSMSTheme.primary)
                }
            }
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(assignment.loanerProductName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(assignment.assignmentId)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                statusChip(viewModel.getStatus(for: assignment))
                    .padding(.top, 4)
            }
            .padding(.vertical, 24)
            
            Divider().background(RSMSTheme.divider)
            
            VStack(spacing: 16) {
                infoRow(label: "Customer", value: assignment.customerName)
                infoRow(label: "Contact", value: assignment.customerContact)
                if let email = assignment.customerEmail {
                    infoRow(label: "Email", value: email)
                }
                infoRow(label: "Deposit", value: "₹\(String(format: "%.2f", assignment.securityDeposit))")
                infoRow(label: "Return By", value: assignment.expectedReturnDate.formatted(date: .abbreviated, time: .omitted))
                infoRow(label: "Condition", value: assignment.condition)
            }
            .padding(20)
            .background(RSMSTheme.surfaceSecondary)
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(RSMSTheme.divider, lineWidth: 1)
        )
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Workflow Actions
    
    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRODUCT RETURN WORKFLOW")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.textTertiary)
            
            VStack(spacing: 12) {
                if assignment.status != LoanerStatus.returned.rawValue && assignment.status != LoanerStatus.available.rawValue {
                    workflowButton(title: "Mark as Returned", icon: "arrow.uturn.left.circle", color: RSMSTheme.primary) {
                        Task { await viewModel.updateAssignmentStatus(assignment: assignment, newStatus: .returned, dataStore: appViewModel.dataStore) }
                    }
                    
                    workflowButton(title: "Mark as Overdue", icon: "exclamationmark.triangle.fill", color: RSMSTheme.danger) {
                        Task { await viewModel.updateAssignmentStatus(assignment: assignment, newStatus: .overdue, dataStore: appViewModel.dataStore) }
                    }
                } else {
                    workflowButton(title: "Refund Deposit", icon: "dollarsign.circle", color: RSMSTheme.success) {
                        // Demo action
                    }
                    
                    workflowButton(title: "Back to Inventory (Available)", icon: "box.truck", color: RSMSTheme.info) {
                        Task { await viewModel.updateAssignmentStatus(assignment: assignment, newStatus: .available, dataStore: appViewModel.dataStore) }
                    }
                }
            }
        }
    }
    
    private func workflowButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(color)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Timeline
    
    private var recentActivitySection: some View {
        let activities = viewModel.sortedActivities(dataStore: appViewModel.dataStore).filter { $0.assignmentId == assignment.assignmentId }
        return VStack(alignment: .leading, spacing: 16) {
            Text("LIFECYCLE TRACKING")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.gold)
            
            if activities.isEmpty {
                Text("No recent activity.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        let stageColor = viewModel.getStageColor(for: activity.stage)
                        HStack(spacing: 16) {
                            Circle()
                                .fill(stageColor.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .fill(stageColor)
                                        .frame(width: 10, height: 10)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(activity.stage)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Text(activity.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                
                                Text(activity.notes ?? "Status updated")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        if index < activities.count - 1 {
                            Divider().background(RSMSTheme.divider).padding(.leading, 64)
                        }
                    }
                }
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(RSMSTheme.divider, lineWidth: 1)
                )
            }
        }
    }
    
    private func statusChip(_ status: LoanerStatus) -> some View {
        let color = viewModel.getStageColor(for: status.rawValue)
        return Text(status.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
