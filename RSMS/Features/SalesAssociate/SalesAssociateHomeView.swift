import SwiftUI

// MARK: - Sidebar Sections

enum SalesAssociateSection: String, CaseIterable, Identifiable {
    case dashboard    = "Dashboard"
    case clients      = "Clients"
    case appointments = "Appointments"
    case returnsExchange = "Returns & Exchanges"
//    case selling      = "Assisted Selling"
    case omnichannel  = "Omnichannel"
    case profile      = "Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:       return "house.fill"
        case .clients:         return "person.crop.circle.fill"
        case .appointments:    return "calendar"
        case .returnsExchange: return "arrow.uturn.backward.circle.fill"
//        case .selling:      return "wand.and.stars"
        case .omnichannel:     return "shippingbox.and.arrow.backward.fill"
        case .profile:         return "person.circle.fill"
        }
    }
}

// MARK: - Root View

struct SalesAssociateHomeView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var selectedSection: SalesAssociateSection? = .dashboard
    @State private var navigationPath = NavigationPath()
    @State private var showNewClientSheet = false
    @State private var showAppointmentsSheet = false
    @State private var appointmentVM: AppointmentViewModel?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showNotifications = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let appointmentVM {
                mainContentView(appointmentVM)
            } else {
                ZStack {
                    RSMSTheme.backgroundGradient.ignoresSafeArea()
                    ProgressView()
                        .tint(RSMSTheme.primary)
                }
                .task {
                    let vm = AppointmentViewModel(
                        dataStore: appViewModel.dataStore,
                        associateId: appViewModel.currentUser?.id ?? UUID(),
                        storeId: appViewModel.currentUser?.storeId ?? UUID()
                    )
                    await vm.loadData()
                    try? await appViewModel.dataStore.fetchAppNotifications()
                    self.appointmentVM = vm
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if horizontalSizeClass == .regular {
                    columnVisibility = .automatic
                }
                // Auto-refresh notifications and sourcing requests when the app comes back to foreground
                Task {
                    try? await appViewModel.dataStore.fetchAppNotifications()
                    try? await appViewModel.dataStore.fetchInventorySourcingRequests()
                }
            }
        }
    }

    // MARK: - Adaptivity Content Routing

    @ViewBuilder
    private func mainContentView(_ appointmentVM: AppointmentViewModel) -> some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebar(appointmentVM)
            } detail: {
                NavigationStack(path: $navigationPath) {
                    detailView(appointmentVM, section: selectedSection)
                }
            }
            .navigationSplitViewStyle(.prominentDetail)
        } else {
            iphoneTabView(appointmentVM)
        }
    }
    
    private func iphoneTabView(_ appointmentVM: AppointmentViewModel) -> some View {
        TabView(selection: $selectedSection) {
            ForEach(SalesAssociateSection.allCases.filter { $0 != .profile }) { section in
                NavigationStack(path: $navigationPath) {
                    detailView(appointmentVM, section: section)
                }
                .tabItem {
                    Label(section.rawValue, systemImage: section.icon)
                }
                .tag(Optional(section))
            }
        }
        .onChange(of: selectedSection) {
            navigationPath = NavigationPath()
        }
    }

    // MARK: - iPhone Dashboard

    private func iphoneDashboardView(_ appointmentVM: AppointmentViewModel) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                RSMSTheme.backgroundGradient.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if appointmentVM.isLoading {
                            ProgressView()
                                .tint(RSMSTheme.primary)
                                .frame(maxWidth: .infinity, minHeight: 120)
                        }

                        if let error = appointmentVM.errorMessage {
                            errorBanner(appointmentVM: appointmentVM, error: error)
                        }

                        greetingHeaderSection

                        KPIGridView(appointmentVM: appointmentVM, viewWidth: geometry.size.width)

                        UpcomingAppointmentsSection(appointmentVM: appointmentVM)

                        TopClientsSection()

                        VStack(spacing: 24) {
                            SalesGoalProgressCard()
                            PendingActionsCard()
                            RecentTransactionsCard()
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .refreshable {
            await appointmentVM.loadData()
            try? await appViewModel.dataStore.fetchAppNotifications()
            try? await appViewModel.dataStore.fetchStockItems(storeId: appViewModel.currentUser?.storeId)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            nativeToolbarItems()
        }
    }

    // MARK: - iPad Sidebar & Detail

        private func sidebar(_ appointmentVM: AppointmentViewModel) -> some View {
            List(selection: $selectedSection) {
                Section {
                    ForEach(SalesAssociateSection.allCases.filter { $0 != .profile }) { section in
                        let isSelected = selectedSection == section
                        
                        HStack(spacing: 16) {
                            Image(systemName: section.icon)
                                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? RSMSTheme.primary : RSMSTheme.textPrimary)
                                .frame(width: 24)
                            
                            Text(section.rawValue)
                                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? RSMSTheme.primary : RSMSTheme.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .tag(section)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(RSMSTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Sales Associate")
        }



        private var logoutButton: some View {
            Button {
                appViewModel.logout()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(RSMSTheme.danger)
            }
            .accessibilityLabel("Sign Out")
        }

    @ViewBuilder
    private func detailView(_ appointmentVM: AppointmentViewModel, section: SalesAssociateSection?) -> some View {
        Group {
            switch section {
            case .dashboard:
                if horizontalSizeClass == .regular {
                    ipadDashboardView(appointmentVM)
                } else {
                    iphoneDashboardView(appointmentVM)
                }
            case .clients:
                SAClientBrowserView(
                    onSelectClient: { client in
                        navigationPath.append(client)
                    },
                    onAddClient: {
                        showNewClientSheet = true
                    },
                    navigationPath: $navigationPath,
                    showNotifications: $showNotifications
                )
            case .appointments:
                AppointmentRemoteSellingView(
                    viewModel: appointmentVM,
                    navigationPath: $navigationPath,
                    showNotifications: $showNotifications
                )
            case .returnsExchange:
                ReturnsDashboardView(dataStore: appViewModel.dataStore)

            case .omnichannel:
                OmnichannelView()
                    .toolbar {
                        nativeToolbarItems()
                    }
            case .profile:
                SalesAssociateProfileView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showNotifications = true
                            } label: {
                                let unreadCount = appViewModel.dataStore.appNotifications.filter { $0.recipientId == appViewModel.currentUser?.id && !$0.isRead }.count
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.primary)
                                    if unreadCount > 0 {
                                        Circle()
                                            .fill(RSMSTheme.danger)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                            }
                        }
                    }
            case .none:
                if horizontalSizeClass == .regular {
                    ipadDashboardView(appointmentVM)
                } else {
                    iphoneDashboardView(appointmentVM)
                }
            }
        }
            .navigationDestination(for: ClientProfile.self) { client in
                ClientProfileDetailView(client: client, dataStore: appViewModel.dataStore, associateId: appViewModel.currentUser?.id ?? UUID())
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "Clients":
                    SAClientBrowserView(
                        onSelectClient: { client in
                            navigationPath.append(client)
                        },
                        onAddClient: {
                            showNewClientSheet = true
                        },
                        navigationPath: $navigationPath,
                        showNotifications: $showNotifications
                    )
                case "Appointments":
                    AppointmentRemoteSellingView(
                        viewModel: appointmentVM,
                        navigationPath: $navigationPath,
                        showNotifications: $showNotifications
                    )
                case "ReturnsExchange":
                    ReturnsDashboardView(dataStore: appViewModel.dataStore)

                case "Omnichannel":
                    OmnichannelView()
                case "Profile":
                    SalesAssociateProfileView()
                case "LookBuilder":
                    LookBuilderView()
                case "AllTransactions":
                    SalesAssociateAllTransactionsView(
                        transactions: appViewModel.dataStore.transactions.filter { $0.associateId == (appViewModel.currentUser?.id ?? UUID()) }
                    )
                case "SourcingRequests":
                    InventorySourcingRequestListView()
                default:
                    Text("Coming Soon")
                }
            }
            .sheet(isPresented: $showNewClientSheet) {
                NewClientOnboardingView()
                    .environment(appViewModel.dataStore)
            }
            .sheet(isPresented: $showAppointmentsSheet) {
                AppointmentRemoteSellingView(
                    viewModel: appointmentVM,
                    navigationPath: $navigationPath,
                    showNotifications: $showNotifications
                )
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsSheetView()
            }

        }

        private func ipadDashboardView(_ appointmentVM: AppointmentViewModel) -> some View {
            GeometryReader { geometry in
                let width = geometry.size.width

                ZStack(alignment: .top) {
                    RSMSTheme.backgroundGradient.ignoresSafeArea()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 32) {
                            if appointmentVM.isLoading {
                                ProgressView()
                                    .tint(RSMSTheme.primary)
                                    .frame(maxWidth: .infinity, minHeight: 120)
                            }

                            if let error = appointmentVM.errorMessage {
                                errorBanner(appointmentVM: appointmentVM, error: error)
                            }

                            greetingHeaderSection

                            KPIGridView(appointmentVM: appointmentVM, viewWidth: width)

                            let isPortrait = width < 850

                            if isPortrait {
                                VStack(alignment: .leading, spacing: 24) {
                                    UpcomingAppointmentsSection(appointmentVM: appointmentVM)
                                    TopClientsSection()
                                    SalesGoalProgressCard()
                                    PendingActionsCard()
                                    RecentTransactionsCard()
                                }
                                .padding(.horizontal, 20)
                            } else {
                                let availableWidth = max(0, width - 40 - 24)
                                let leftWidth = max(0, availableWidth * 0.5)
                                let rightWidth = max(0, availableWidth * 0.5)

                                HStack(alignment: .top, spacing: 24) {
                                    VStack(alignment: .leading, spacing: 28) {
                                        UpcomingAppointmentsSection(appointmentVM: appointmentVM)
                                        PendingActionsCard()
                                        RecentTransactionsCard()
                                    }
                                    .frame(width: leftWidth, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 28) {
                                        SalesGoalProgressCard()
                                        TopClientsSection()
                                    }
                                    .frame(width: rightWidth, alignment: .leading)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 24)
                    }
                }
            }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            nativeToolbarItems()
        }
    }
    // MARK: - Shared Helpers

    private func errorBanner(appointmentVM: AppointmentViewModel, error: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(RSMSTheme.warning)
            Text(error)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Button("Retry") {
                Task { await appointmentVM.loadData() }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(RSMSTheme.primary)
        }
        .padding(12)
        .background(RSMSTheme.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, horizontalSizeClass == .regular ? 20 : 16)
    }

    @ToolbarContentBuilder
    private func nativeToolbarItems(
        plusAction: (() -> Void)? = nil
    ) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                if let plusAction {
                    Button(action: plusAction) {
                        Image(systemName: "plus").accessibilityLabel("Add")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RSMSTheme.primary)
                    }
                }
                
                Button {
                    showNotifications = true
                } label: {
                    let unreadCount = appViewModel.dataStore.appNotifications.filter { $0.recipientId == appViewModel.currentUser?.id && !$0.isRead }.count
                    
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.primary)
                        
                        if unreadCount > 0 {
                            Circle()
                                .fill(RSMSTheme.danger)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                
                Button {
                    navigationPath.append("Profile")
                } label: {
                    let initials = appViewModel.currentUser?.fullName.split(separator: " ").prefix(2)
                        .compactMap { $0.first.map(String.init) }.joined().uppercased() ?? ""
                    ProfileAvatarView(avatarURL: appViewModel.currentUser?.avatarURL, initials: initials, size: 30)
                }
            }
        }
    }

    private var greetingHeaderSection: some View {
        let firstName = appViewModel.currentUser?.fullName
            .components(separatedBy: " ").first ?? "there"

        return HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting(for: .now) + ", " + firstName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.textPrimary)

                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month().year()))
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func greeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}



// MARK: - KPIGridView

private struct KPIGridView: View {
    let appointmentVM: AppointmentViewModel
    let viewWidth: CGFloat
    var isSidebarClosed: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let padding: CGFloat = horizontalSizeClass == .regular ? 20 : 16
        let availableWidth = viewWidth - (padding * 2)
        let spacing: CGFloat = horizontalSizeClass == .regular ? 16 : 12

        let columns: [GridItem] = {
            let columnsCount: Int
            if isSidebarClosed {
                columnsCount = 4
            } else if availableWidth >= 700 {
                columnsCount = 4
            } else if availableWidth >= 480 {
                columnsCount = 3
            } else {
                columnsCount = 2
            }
            return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount)
        }()

        LazyVGrid(columns: columns, spacing: spacing) {
            KPICard(
                icon: "indianrupeesign.circle.fill",
                value: appointmentVM.todaySalesFormatted,
                label: "Today's Sales",
                trend: nil,
                trendColor: RSMSTheme.success
            )

            KPICard(
                icon: "calendar.circle.fill",
                value: appointmentVM.todaysAppointmentsCount,
                label: "Today's Appointments",
                trend: nil,
                iconColor: RSMSTheme.info
            )

            KPICard(
                icon: "person.2.circle.fill",
                value: appointmentVM.clientsServedTodayCount,
                label: "Clients Served",
                trend: nil,
                iconColor: RSMSTheme.success
            )

            KPICard(
                icon: "clock.circle.fill",
                value: appointmentVM.nextAppointmentDisplay,
                label: "Next Appointment",
                trend: nil,
                iconColor: RSMSTheme.primary
            )
        }
        .padding(.horizontal, padding)
    }
}

// MARK: - UpcomingAppointmentsSection

private struct UpcomingAppointmentsSection: View {
    let appointmentVM: AppointmentViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Today's Appointments")
                Spacer()
                
                NavigationLink(value: "Appointments") {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.primary)
                }
            }

            if appointmentVM.upcomingAppointments.isEmpty {
                EmptyAppointmentsCard()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appointmentVM.upcomingAppointments.prefix(5)) { appointment in
                            NavigationLink(value: appointment) {
                                AppointmentQuickCard(
                                    appointment: appointment,
                                    clientName: appointmentVM.clientName(for: appointment.clientId),
                                    statusColor: appointmentVM.statusColor(appointment.status)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 0 : 16)
    }
}

private struct EmptyAppointmentsCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(RSMSTheme.primary.opacity(0.5))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No appointments today")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text("Enjoy a calm day or schedule a new consultation.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rsmsCard()
    }
}

// MARK: - TopClientsSection

private struct TopClientsSection: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let transactions = appViewModel.dataStore.transactions
        let clients = appViewModel.dataStore.clients

        let spendingDict: [UUID: Double] = transactions.reduce(into: [:]) { dict, tx in
            if let clientId = tx.clientId {
                dict[clientId, default: 0] += tx.totalAmount
            }
        }

        let topClients = clients.sorted { 
            (spendingDict[$0.id] ?? 0) > (spendingDict[$1.id] ?? 0)
        }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(
                    title: "Top Clients",
                    subtitle: "By Spending"
                )
                Spacer()
                
                NavigationLink(value: "Clients") {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.primary)
                }
            }

            if topClients.isEmpty {
                Text("No client data available")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                GeometryReader { geo in
                    let maxClients = min(5, topClients.count)
                    let displayedClients = Array(topClients.prefix(maxClients))
                    
                    let spacing: CGFloat = 8
                    let totalSpacing = spacing * CGFloat(maxClients - 1)
                    
                    let cardWidth = min(140, (geo.size.width - totalSpacing) / CGFloat(maxClients))
                    let avatarSize = cardWidth * 0.82 

                    HStack(spacing: spacing) {
                        ForEach(displayedClients) { client in
                            NavigationLink(value: client) {
                                ClientAvatarCard(client: client, spending: spendingDict[client.id], avatarSize: avatarSize, cardWidth: cardWidth)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120) // Adjust height to fit the dynamic cards without clipping
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 0 : 16)
    }
}

// MARK: - Client Browser & Row for Navigation Stack

struct ClientGroup: Identifiable {
    let id = UUID()
    let letter: String
    let clients: [ClientProfile]
}

struct SAClientBrowserView: View {
    let onSelectClient: (ClientProfile) -> Void
    var onAddClient: () -> Void = {}
    @Binding var navigationPath: NavigationPath
    @Binding var showNotifications: Bool
    @Environment(AppViewModel.self) private var appViewModel
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    @State private var clientToDelete: ClientProfile? = nil
    @State private var showDeleteAlert = false
    
    let filters = ["All", "Privé", "Platinum", "Gold", "Silver", "Standard"]
    
    private var filteredGroupedClients: [ClientGroup] {
        var clients = appViewModel.dataStore.clients
        
        // 1. Filter by Tier
        if selectedFilter != "All" {
            if selectedFilter == "Privé" || selectedFilter == "Prive" || selectedFilter == "VIP" {
                clients = clients.filter { $0.vipTier == VIPTier.prive }
            } else {
                clients = clients.filter { $0.vipTier.rawValue.caseInsensitiveCompare(selectedFilter) == .orderedSame }
            }
        }
        
        // 2. Filter by Search Text
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            clients = clients.filter {
                $0.fullName.lowercased().contains(q) ||
                ($0.email?.lowercased().contains(q) ?? false)
            }
        }
        
        // 3. Group by first letter
        let grouped = Dictionary(grouping: clients) { client in
            String(client.fullName.prefix(1)).uppercased()
        }
        
        let groups = grouped.map { ClientGroup(letter: $0.key, clients: $0.value.sorted(by: { $0.fullName < $1.fullName })) }
        return groups.sorted(by: { $0.letter < $1.letter })
    }

    var body: some View {
        ZStack {
            RSMSTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search and Filters stay pinned at the top
                VStack(spacing: 16) {
                    Spacer().frame(height: 12)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedFilter = filter
                                    }
                                } label: {
                                    Text(filter)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(selectedFilter == filter ? .white : RSMSTheme.textSecondary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(selectedFilter == filter ? RSMSTheme.primary : RSMSTheme.surfacePrimary)
                                                .shadow(color: .black.opacity(selectedFilter == filter ? 0.1 : 0.03), radius: 4, y: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.bottom, 16)

                // Client Groups in a List for Swipe-to-Delete
                List {
                    if filteredGroupedClients.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.largeTitle)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            Text("No clients found")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredGroupedClients) { group in
                            Section {
                                ForEach(group.clients) { client in
                                    Button {
                                        onSelectClient(client)
                                    } label: {
                                        SAClientRow(client: client)
                                            .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            clientToDelete = client
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Text(group.letter)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("Clients")
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search...")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                onAddClient()
                            } label: {
                                Image(systemName: "plus").accessibilityLabel("Add")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            
                            Button {
                                showNotifications = true
                            } label: {
                                let unreadCount = appViewModel.dataStore.appNotifications.filter { $0.recipientId == appViewModel.currentUser?.id && !$0.isRead }.count
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.primary)
                                    
                                    if unreadCount > 0 {
                                        Circle()
                                            .fill(RSMSTheme.danger)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                            }
                            
                            Button {
                                navigationPath.append("Profile")
                            } label: {
                                let initials = appViewModel.currentUser?.fullName.split(separator: " ").prefix(2)
                                    .compactMap { $0.first.map(String.init) }.joined().uppercased() ?? ""
                                ProfileAvatarView(avatarURL: appViewModel.currentUser?.avatarURL, initials: initials, size: 30)
                            }
                        }
                    }
                }
            }
        }  .alert(
            "Confirm Delete",
            isPresented: $showDeleteAlert,
            presenting: clientToDelete
        ) { client in
            Button("Delete", role: .destructive) {
                Task {
                    try? await appViewModel.dataStore.deleteClient(id: client.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { client in
            Text("Are you sure you want to delete \(client.fullName)? This action cannot be undone.")
        }
    }
    

}

private struct SAClientRow: View {
    let client: ClientProfile
    
    private var initials: String {
        client.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined().uppercased()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                if client.vipTier == VIPTier.prive {
                    Circle()
                        .stroke(RSMSTheme.gold, lineWidth: 1.5)
                        .frame(width: 52, height: 52)
                }
                
                Circle()
                    .fill(RSMSTheme.primary)
                    .frame(width: 48, height: 48)
                
                Text(initials)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            
            // Name, Badge & Email
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(client.fullName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    if client.vipTier != .standard {
                        Text(client.vipTier.rawValue.uppercased())
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(badgeBackground, in: Capsule())
                            .foregroundStyle(badgeForeground)
                    }
                }
                
                Text(client.email ?? "No Email")
                    .font(.footnote)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        )
        .contentShape(Rectangle())
    }
    
    private var badgeBackground: Color {
        if client.vipTier == VIPTier.prive {
            return RSMSTheme.textPrimary
        }
        return badgeForeground.opacity(0.15)
    }
    
    private var badgeForeground: Color {
        switch client.vipTier {
        case VIPTier.prive: return RSMSTheme.cream
        case VIPTier.platinum: return .purple
        case VIPTier.silver: return .gray
        case VIPTier.gold: return .orange
        default: return .clear
        }
    }
}

// MARK: - Dashboard Cards

private struct SalesGoalProgressCard: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        let userId = appViewModel.currentUser?.id ?? UUID()
        let goal = appViewModel.dataStore.salesGoals
            .first { $0.staffId == userId }

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sales Goal")

            VStack(alignment: .leading, spacing: 14) {
                if let goal {
                    let progress = min(
                        goal.achievedAmount / max(goal.targetAmount, 1),
                        1.0
                    )
                    let percent = Int(progress * 100)
                    let isComplete = progress >= 1.0

                    HStack(alignment: .firstTextBaseline) {
                        Text("₹\(Int(goal.achievedAmount).formatted())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.textPrimary)

                        Spacer()

                        Text("\(percent)%")
                            .font(.headline)
                            .foregroundStyle(isComplete ? RSMSTheme.success : RSMSTheme.primary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(RSMSTheme.primary.opacity(0.10))
                                .frame(height: 8)

                            Capsule()
                                .fill(isComplete ? RSMSTheme.success : RSMSTheme.primary)
                                .frame(width: max(0, geo.size.width * progress), height: 8)
                                .animation(.easeOut(duration: 0.6), value: progress)
                        }
                    }
                    .frame(height: 8)
                    .accessibilityElement()
                    .accessibilityLabel("Goal progress")
                    .accessibilityValue("\(percent) percent of \(goal.period.rawValue) target reached")

                    Text("Target ₹\(Int(goal.targetAmount).formatted()) · \(goal.period.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)

                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "target")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .accessibilityHidden(true)

                        Text("No active goal assigned")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(RSMSTheme.surfacePrimary)
            )
        }
    }
}

private struct PendingActionsCard: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        let userId = appViewModel.currentUser?.id ?? UUID()
        let pendingSourcing = appViewModel.dataStore.inventorySourcingRequests
            .filter { $0.salesAssociateId == userId && $0.status == .requested }
        let unreadCount = appViewModel.dataStore.appNotifications
            .filter { $0.recipientId == userId && !$0.isRead }.count

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pending")

            VStack(spacing: 8) {
                if pendingSourcing.isEmpty && unreadCount == 0 {
                    allClearRow
                } else {
                    if unreadCount > 0 {
                        pendingRow(
                            icon: "bell.badge",
                            iconColor: RSMSTheme.warning,
                            title: "\(unreadCount) unread \(unreadCount == 1 ? "notification" : "notifications")",
                            subtitle: "Tap the bell icon above to view",
                            destination: nil   // bell is in the toolbar; no nav push needed
                        )
                    }
                    if !pendingSourcing.isEmpty {
                        pendingRow(
                            icon: "shippingbox",
                            iconColor: RSMSTheme.info,
                            title: "\(pendingSourcing.count) sourcing \(pendingSourcing.count == 1 ? "request" : "requests") pending",
                            subtitle: "Review and respond",
                            destination: "SourcingRequests"
                        )
                    }
                }
            }
        }
    }

    private var allClearRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .symbolRenderingMode(.hierarchical)
                .font(.title3)
                .foregroundStyle(RSMSTheme.success)
                .accessibilityHidden(true)

            Text("All caught up")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RSMSTheme.surfacePrimary)
        )
    }

    @ViewBuilder
    private func pendingRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        destination: String?
    ) -> some View {
        let content = HStack(spacing: 14) {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(RSMSTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }

            Spacer()

            if destination != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 44)  // HIG minimum touch target
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RSMSTheme.surfacePrimary)
        )

        if let destination {
            NavigationLink(value: destination) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

private struct RecentTransactionsCard: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        let userId = appViewModel.currentUser?.id ?? UUID()
        let recent = Array(
            appViewModel.dataStore.transactions
                .filter { $0.associateId == userId }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(3)
        )

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title: "Recent Sales")
                Spacer()
                NavigationLink(value: "AllTransactions") {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.primary)
                }
            }

            VStack(spacing: 1) {
                if recent.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "cart")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .accessibilityHidden(true)

                        Text("No sales recorded yet")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)

                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(RSMSTheme.surfacePrimary)
                    )
                } else {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, tx in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Receipt #\(tx.id.uuidString.prefix(6).uppercased())")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(RSMSTheme.textPrimary)

                                Text(tx.createdAt, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }

                            Spacer()

                            Text("₹\(Int(tx.totalAmount).formatted())")
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(RSMSTheme.surfacePrimary)
                        // Top corners rounded on first row, bottom on last
                        .clipShape(
                            .rect(
                                topLeadingRadius: index == 0 ? 20 : 4,
                                bottomLeadingRadius: index == recent.count - 1 ? 20 : 4,
                                bottomTrailingRadius: index == recent.count - 1 ? 20 : 4,
                                topTrailingRadius: index == 0 ? 20 : 4
                            )
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("iPhone — Sales Associate") {
    let vm = AppViewModel()
    vm.currentUser = .previewAssociate
    return SalesAssociateHomeView()
        .environment(vm)
        .environment(vm.dataStore)
}

#Preview("iPad", traits: .fixedLayout(width: 1024, height: 768)) {
    let vm = AppViewModel()
    vm.currentUser = .previewAssociate
    return SalesAssociateHomeView()
        .environment(vm)
        .environment(vm.dataStore)
}
