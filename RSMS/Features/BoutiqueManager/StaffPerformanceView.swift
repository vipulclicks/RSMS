import SwiftUI

struct StaffView: View {
    @Environment(AppViewModel.self) private var appVM
    
    @State private var shiftPlanningVM = StaffManagementViewModel()
    @State private var showingNewAssociateSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if shiftPlanningVM.isLoading {
                    ProgressView("Loading Staff...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = shiftPlanningVM.errorMessage {
                    ContentUnavailableView(
                        "Error Loading Data",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        allStaffSection
                    }
                    .padding(32)
                }
                .background(RSMSTheme.background.ignoresSafeArea())
                .navigationTitle("Staff")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingNewAssociateSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("New Employee")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    }
                }
                .sheet(isPresented: $showingNewAssociateSheet) {
                    CreateAssociateView {
                        Task {
                            if let storeId = appVM.currentStoreId {
                                await shiftPlanningVM.load(dataStore: appVM.dataStore, storeId: storeId)
                            }
                        }
                    }
                }
                }
            } // closes Group
            .task {
                if let storeId = appVM.currentStoreId {
                    await shiftPlanningVM.load(dataStore: appVM.dataStore, storeId: storeId)
                }
            }
        } // closes NavigationStack
    }

    private var allStaffSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "All Staff", subtitle: "Sales Associates and Inventory Controllers")
            
            let filteredStaff = shiftPlanningVM.allStaff.filter { $0.id != appVM.currentUser?.id }
            
            if filteredStaff.isEmpty {
                Text("No staff found.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredStaff) { staff in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(RSMSTheme.gold.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                
                                Text(String(staff.fullName.prefix(1)))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(RSMSTheme.gold)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(staff.fullName)
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                
                                Text(staff.role.displayName)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                
                                if let email = staff.email as String? {
                                    Text(email)
                                        .font(.caption2)
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                            }
                            Spacer()
                        }
                        .rsmsCard(padding: 16)
                    }
                }
            }
        }
    }
}

struct PerformanceView: View {
    @Environment(AppViewModel.self) private var appVM
    
    @State private var navPath = [SalesGoalRoute]()
    @State private var salesGoalVM = SalesGoalViewModel()

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if salesGoalVM.isLoading {
                    ProgressView("Loading Performance Data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = salesGoalVM.errorMessage {
                    ContentUnavailableView(
                        "Error Loading Data",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        salesGoalsSection
                    }
                    .padding(32)
                }
                .background(RSMSTheme.background.ignoresSafeArea())
                .navigationTitle("Performance")
                .navigationDestination(for: SalesGoalRoute.self) { route in
                    switch route {
                    case .assignGoalForm:
                        AssignGoalFormView(viewModel: salesGoalVM, navPath: $navPath)
                    case .staffPicker:
                        StaffPickerView(viewModel: salesGoalVM, navPath: $navPath)
                    }
                }
                }
            } // closes Group
            .task {
                if let storeId = appVM.currentStoreId {
                    await salesGoalVM.load(dataStore: appVM.dataStore, storeId: storeId)
                }
            }
        } // closes NavigationStack
    }

    private var salesGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Sales Goals")
                Spacer()
                Button {
                    navPath.append(.assignGoalForm)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Goal")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.gold.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            if salesGoalVM.availableStaff.isEmpty {
                Text("No sales associates available.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(salesGoalVM.availableStaff) { staff in
                        StaffGoalCard(staff: staff, viewModel: salesGoalVM)
                    }
                }
            }
        }
    }
}
