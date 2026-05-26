import SwiftUI

enum StaffRoute: Hashable {
    case allStaff
    case assignGoalForm
    case staffPicker
    case staffProfile(UserProfile)
}

struct StaffView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var shiftPlanningVM = StaffManagementViewModel()
    @State private var salesGoalVM = SalesGoalViewModel()
    @State private var showingNewAssociateSheet = false
    @State private var navPath = [StaffRoute]()

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if shiftPlanningVM.isLoading || salesGoalVM.isLoading {
                    ProgressView("Loading Staff & Goals...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = shiftPlanningVM.errorMessage ?? salesGoalVM.errorMessage {
                    ContentUnavailableView(
                        "Error Loading Data",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        allStaffSection
                        salesGoalsSection
                    }
                    .padding(horizontalSizeClass == .compact ? 16 : 32)
                }
                .background(RSMSTheme.background.ignoresSafeArea())
                .navigationTitle("Staff")
                .navigationDestination(for: StaffRoute.self) { route in
                    switch route {
                    case .allStaff:
                        AllStaffListView(shiftPlanningVM: shiftPlanningVM, navPath: $navPath)
                    case .assignGoalForm:
                        AssignGoalFormView(viewModel: salesGoalVM, navPath: $navPath)
                    case .staffPicker:
                        StaffPickerView(viewModel: salesGoalVM, navPath: $navPath)
                    case .staffProfile(let staff):
                        StaffProfileDetailView(staff: staff)
                    }
                }
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
                    await salesGoalVM.load(dataStore: appVM.dataStore, storeId: storeId)
                }
            }
        } // closes NavigationStack
    }

    private var allStaffSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                SectionHeader(title: "Staff Members", subtitle: "Sales Associates and Inventory Controllers")
                Spacer()
                Button {
                    navPath.append(.allStaff)
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textSecondary)
                }
                .padding(.bottom, 8)
            }
            
            let filteredStaff = shiftPlanningVM.allStaff.filter { $0.id != appVM.currentUser?.id }
            
            if filteredStaff.isEmpty {
                Text("No staff found.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(filteredStaff.prefix(5)) { staff in
                            Button {
                                navPath.append(.staffProfile(staff))
                            } label: {
                                StaffCardViewStandalone(staff: staff)
                                    .frame(width: 280)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(salesGoalVM.availableStaff) { staff in
                            StaffGoalCard(staff: staff, viewModel: salesGoalVM) {
                                salesGoalVM.draftSelectedStaff = staff
                                salesGoalVM.loadPreviousGoal()
                                navPath.append(.assignGoalForm)
                            }
                            .frame(width: horizontalSizeClass == .compact ? 320 : 380)
                        }
                    }
                }
            }
        }
    }
}

struct AllStaffListView: View {
    @Bindable var shiftPlanningVM: StaffManagementViewModel
    @Binding var navPath: [StaffRoute]
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            let columns = horizontalSizeClass == .compact 
                ? [GridItem(.flexible())] 
                : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                
            LazyVGrid(columns: columns, spacing: 24) {
                let filteredStaff = shiftPlanningVM.allStaff.filter { $0.id != appVM.currentUser?.id }
                ForEach(filteredStaff) { staff in
                    Button {
                        navPath.append(.staffProfile(staff))
                    } label: {
                        StaffCardViewStandalone(staff: staff)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(horizontalSizeClass == .compact ? 16 : 32)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("All Staff Members")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StaffCardViewStandalone: View {
    let staff: UserProfile
    var body: some View {
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
                    .lineLimit(1)
                
                Text(staff.role.displayName)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                if let email = staff.email as String? {
                    Text(email)
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .rsmsCard(padding: 16)
    }
}

