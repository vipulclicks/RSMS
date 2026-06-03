import SwiftUI

struct LoanerProductManagementView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = LoanerProductManagementViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ZStack {
            RSMSTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        analyticsSection
                        assignmentsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Loaner Management")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let storeId = appViewModel.currentStoreId {
                    await viewModel.loadData(dataStore: appViewModel.dataStore, storeId: storeId)
                }
            }
            .sheet(isPresented: $viewModel.isShowingNewAssignmentModal) {
                AssignLoanerModalView(viewModel: viewModel)
            }
            .sheet(item: $viewModel.selectedAssignment) { assignment in
                LoanerDetailModalView(viewModel: viewModel, assignment: assignment)
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Loaner Product Management")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            
            Spacer()
            
            Button {
                viewModel.isShowingNewAssignmentModal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Assign Loaner")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RSMSTheme.primary)
                .clipShape(Capsule())
                .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - Analytics Overview
    private var analyticsSection: some View {
        let isIPad = horizontalSizeClass == .regular
        let columns = isIPad ? Array(repeating: GridItem(.flexible(), spacing: 16), count: 4) : Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        
        return LazyVGrid(columns: columns, spacing: 16) {
            analyticsCard(
                title: "Available Loaners",
                count: "\(viewModel.availableLoanersCount(dataStore: appViewModel.dataStore))",
                icon: "box.truck",
                color: RSMSTheme.success
            )
            analyticsCard(
                title: "Assigned Loaners",
                count: "\(viewModel.assignedLoanersCount(dataStore: appViewModel.dataStore))",
                icon: "person.text.rectangle",
                color: RSMSTheme.info
            )
            analyticsCard(
                title: "Overdue Returns",
                count: "\(viewModel.overdueReturnsCount(dataStore: appViewModel.dataStore))",
                icon: "exclamationmark.circle",
                color: RSMSTheme.danger
            )
            analyticsCard(
                title: "Returned Today",
                count: "\(viewModel.returnedTodayCount(dataStore: appViewModel.dataStore))",
                icon: "arrow.uturn.left.circle",
                color: RSMSTheme.primary
            )
        }
    }
    
    private func analyticsCard(title: String, count: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                Spacer()

            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(count)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .textCase(.uppercase)
            }
        }
        .padding(20)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
    }
    
    // MARK: - Active Loaners Section
    
    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Loaner Activity")
                    .font(.title3.bold())
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    TextField("Search assignments...", text: $viewModel.searchText)
                        .font(.subheadline)
                        .frame(width: 200)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RSMSTheme.surfaceSecondary)
                .clipShape(Capsule())
            }
            
            let assignments = viewModel.filteredAssignments(dataStore: appViewModel.dataStore)
            
            if assignments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("No loaner assignments found.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                if horizontalSizeClass == .regular {
                    assignmentsTable(assignments)
                } else {
                    assignmentsList(assignments)
                }
            }
        }
    }
    
    private func assignmentsTable(_ assignments: [LoanerAssignment]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("PRODUCT").frame(width: 200, alignment: .leading)
                Text("CUSTOMER").frame(maxWidth: .infinity, alignment: .leading)
                Text("RETURN BY").frame(width: 120, alignment: .leading)
                Text("STATUS").frame(width: 120, alignment: .leading)
                Spacer()
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(RSMSTheme.textTertiary)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider().background(RSMSTheme.divider)
            
            ForEach(assignments) { assignment in
                Button {
                    viewModel.selectedAssignment = assignment
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(assignment.loanerProductName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text(assignment.sku)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        .frame(width: 200, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(assignment.customerName)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text(assignment.assignmentId)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(assignment.expectedReturnDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .frame(width: 120, alignment: .leading)
                        
                        statusChip(viewModel.getStatus(for: assignment))
                            .frame(width: 120, alignment: .leading)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(RSMSTheme.surfacePrimary)
                }
                .buttonStyle(.plain)
                
                Divider().background(RSMSTheme.divider)
            }
        }
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.02), radius: 10, y: 4)
    }
    
    private func assignmentsList(_ assignments: [LoanerAssignment]) -> some View {
        VStack(spacing: 16) {
            ForEach(assignments) { assignment in
                Button {
                    viewModel.selectedAssignment = assignment
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(assignment.assignmentId)
                                .font(.caption.monospacedDigit().bold())
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Spacer()
                            statusChip(viewModel.getStatus(for: assignment))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(assignment.loanerProductName)
                                .font(.subheadline.bold())
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("Customer: \(assignment.customerName)")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.primary)
                            Text("Return: \(assignment.expectedReturnDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(RSMSTheme.textSecondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                    .padding(16)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func statusChip(_ status: LoanerStatus) -> some View {
        let color: Color
        switch status {
        case .available: color = RSMSTheme.success
        case .assigned: color = RSMSTheme.info
        case .overdue: color = RSMSTheme.danger
        case .returned: color = RSMSTheme.primary
        case .maintenance: color = RSMSTheme.gold
        }
        
        return Text(status.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
