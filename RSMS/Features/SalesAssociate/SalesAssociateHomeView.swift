import SwiftUI

// MARK: - Sidebar Sections

enum SalesAssociateSection: String, CaseIterable, Identifiable {
    case dashboard    = "Dashboard"
    case clients      = "Clients"
    case appointments = "Appointments"
    case pos          = "POS & Checkout"
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
        case .pos:             return "cart.fill"
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
        .onChange(of: selectedSection) { _ in
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

                        QuickActionsSection(
                            columnsCount: 2,
                            onNewClient: { showNewClientSheet = true },
                            onOmnichannel: { navigationPath.append("Omnichannel") }
                        )
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
            case .pos:
                POSCheckoutView()
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
                                        .font(.system(size: 18))
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
                case "POS":
                    POSCheckoutView()
                case "ReturnsExchange":
                    ReturnsDashboardView(dataStore: appViewModel.dataStore)

                case "Omnichannel":
                    OmnichannelView()
                case "Profile":
                    SalesAssociateProfileView()
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

                            VStack(alignment: .leading, spacing: 32) {
                                UpcomingAppointmentsSection(appointmentVM: appointmentVM)
                                
                                QuickActionsSection(
                                    columnsCount: width >= 700 ? 4 : (width >= 500 ? 3 : 2),
                                    onNewClient: { showNewClientSheet = true },
                                    onOmnichannel: { navigationPath.append("Omnichannel") }
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 32)
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
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(RSMSTheme.primary)
                    }
                }
                
                Button {
                    showNotifications = true
                } label: {
                    let unreadCount = appViewModel.dataStore.appNotifications.filter { $0.recipientId == appViewModel.currentUser?.id && !$0.isRead }.count
                    
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18))
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
        let firstName = appViewModel.currentUser?.fullName.components(separatedBy: " ").first ?? "there"
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(greeting(for: .now)), \(firstName)")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 20 : 16)
        .padding(.top, 16)
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

// MARK: - MyClientsSection

private struct MyClientsSection: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let clients = ClientProfile.allClients

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(
                    title: "My Clients",
                    subtitle: "\(clients.count) total"
                )
                Spacer()
                
                NavigationLink(value: "Clients") {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.primary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(clients.prefix(8)) { client in
                        NavigationLink(value: client) {
                            ClientAvatarCard(client: client)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 20)
    }
}

// MARK: - QuickActionsSection

private struct QuickActionsSection: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let columnsCount: Int
    let onNewClient: () -> Void
    let onOmnichannel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions")
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columnsCount),
                spacing: 12
            ) {
                QuickActionCard(
                    icon: "person.badge.plus",
                    label: "New Client",
                    color: RSMSTheme.primary,
                    onTap: onNewClient
                )
                
//                QuickActionCard(
//                    icon: "cart.badge.plus",
//                    label: "New Sale",
//                    color: RSMSTheme.info,
//                    onTap: onNewSale
//                )
//
//                QuickActionCard(
//                    icon: "wand.and.stars",
//                    label: "Look Builder",
//                    color: RSMSTheme.warning,
//                    onTap: onLookBuilder
//                )
                
                QuickActionCard(
                    icon: "shippingbox.and.arrow.backward",
                    label: "Omnichannel",
                    color: RSMSTheme.success,
                    onTap: onOmnichannel
                )
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
    @State private var isSearchExpanded = false
    
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
                                        .font(.system(size: 15, weight: .medium))
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
                                .font(.system(size: 48))
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
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                        }
                    }
                    

                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Clients")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSearchExpanded {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(RSMSTheme.textSecondary)
                                .font(.system(size: 14))
                            
                            TextField("Search...", text: $searchText)
                                .font(.system(size: 15))
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
                        .frame(width: 240)
                        
                        Button("Cancel") {
                            withAnimation(.easeOut(duration: 0.2)) {
                                searchText = ""
                                isSearchExpanded = false
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(RSMSTheme.primary)
                    }
                } else {
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.easeIn(duration: 0.2)) {
                                isSearchExpanded = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(RSMSTheme.primary)
                        }
                        
                        Button {
                            onAddClient()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(RSMSTheme.primary)
                        }
                        
                        Button {
                            showNotifications = true
                        } label: {
                            let unreadCount = appViewModel.dataStore.appNotifications.filter { $0.recipientId == appViewModel.currentUser?.id && !$0.isRead }.count
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .font(.system(size: 18))
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
        .alert(
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            // Name, Badge & Email
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(client.fullName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    if client.vipTier != .standard {
                        Text(client.vipTier.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(badgeBackground, in: Capsule())
                            .foregroundStyle(badgeForeground)
                    }
                }
                
                Text(client.email ?? "No Email")
                    .font(.system(size: 14))
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
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
