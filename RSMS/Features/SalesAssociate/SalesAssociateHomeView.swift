import SwiftUI

// MARK: - Sidebar Sections

enum SalesAssociateSection: String, CaseIterable, Identifiable {
    case dashboard    = "Dashboard"
    case clients  = "Clients"
    case appointments = "Appointments"
//    case selling      = "Assisted Selling"
//    case pos          = "POS & Checkout"
//    case omnichannel  = "Omnichannel"
    case profile      = "Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:    return "square.grid.2x2.fill"
        case .clients:  return "person.crop.circle.fill"
        case .appointments: return "calendar"
//        case .selling:      return "wand.and.stars"
//        case .pos:          return "cart.fill"
//        case .omnichannel:  return "shippingbox.and.arrow.backward.fill"
        case .profile:      return "person.circle.fill"
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
                    self.appointmentVM = vm
                }
            }
        }
        .tint(RSMSTheme.primary)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && horizontalSizeClass == .regular {
                columnVisibility = .automatic
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
            ForEach(SalesAssociateSection.allCases) { section in
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

                        DashboardHeaderView(onProfileTapped: { navigationPath.append("Profile") })

                        KPIGridView(appointmentVM: appointmentVM, viewWidth: geometry.size.width)

                        UpcomingAppointmentsSection(appointmentVM: appointmentVM)

                        QuickActionsSection(
                            columnsCount: 2,
                            onNewClient: { showNewClientSheet = true }
//                            onNewSale: { navigationPath.append("POS") },
//                            onLookBuilder: { navigationPath.append("LookBuilder") },
//                            onOmnichannel: { navigationPath.append("Omnichannel") }
                        )
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .refreshable {
            await appointmentVM.loadData()
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
                SAClientBrowserView(onSelectClient: { client in
                    navigationPath.append(client)
                }, onAddClient: {
                    showNewClientSheet = true
                })
            case .appointments:
                AppointmentRemoteSellingView(viewModel: appointmentVM, navigationPath: $navigationPath)
//                case .selling:
//                    AssistedSellingView()
//                case .pos:
//                    POSCheckoutView()
//                case .omnichannel:
//                    OmnichannelView()
            case .profile:
                SalesAssociateProfileView()
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
                    SAClientBrowserView(onSelectClient: { client in
                        navigationPath.append(client)
                    }, onAddClient: {
                        showNewClientSheet = true
                    })
                case "Appointments":
                    AppointmentRemoteSellingView(viewModel: appointmentVM, navigationPath: $navigationPath)
//                case "POS":
//                    POSCheckoutView()
//                case "LookBuilder":
//                    LookBuilderView()
//                case "Omnichannel":
//                    OmnichannelView()
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
                AppointmentRemoteSellingView(viewModel: appointmentVM, navigationPath: $navigationPath)
            }
        }

        private func ipadDashboardView(_ appointmentVM: AppointmentViewModel) -> some View {
            GeometryReader { geometry in
                let width = min(geometry.size.width, 950)

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

                            DashboardHeaderView(onProfileTapped: { navigationPath.append("Profile") })
                                .padding(.horizontal, 4)

                            KPIGridView(appointmentVM: appointmentVM, viewWidth: width, isSidebarClosed: true)

                            VStack(alignment: .leading, spacing: 32) {
                                UpcomingAppointmentsSection(appointmentVM: appointmentVM)
                                
                                QuickActionsSection(
                                    columnsCount: 4,
                                    onNewClient: { showNewClientSheet = true }
//                                    onNewSale: { navigationPath.append("POS") },
//                                    onLookBuilder: { navigationPath.append("LookBuilder") },
//                                    onOmnichannel: { navigationPath.append("Omnichannel") }
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        .frame(maxWidth: 950)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 32)
                    }
                }
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
        .padding(.horizontal, 20)
    }
}

// MARK: - DashboardHeaderView

private struct DashboardHeaderView: View {
    @Environment(AppViewModel.self) private var appViewModel
    var onProfileTapped: () -> Void

    var body: some View {
        let firstName = appViewModel.currentUser?.fullName.components(separatedBy: " ").first ?? "there"
        let todayStr = RSMSDateFormatter.fullDate.string(from: .now)
        let storeName = appViewModel.currentUser?.storeId.map { appViewModel.dataStore.storeName(for: $0) } ?? "Unknown Store"

        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                HStack(spacing: 6) {
                    Text("\(greeting(for: .now)), \(firstName)")
                    Text("•")
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(RSMSTheme.primary)
                    Text(storeName)
                }
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(RSMSTheme.textSecondary)
            }
            Spacer()
            
            Button {
                onProfileTapped()
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.surfacePrimary)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(RSMSTheme.primary)
                }
            }
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
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

    var body: some View {
        let padding: CGFloat = viewWidth > 550 ? 24 : 20
        let availableWidth = viewWidth - (padding * 2)
        let spacing: CGFloat = viewWidth > 550 ? 16 : 12

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
        .padding(.horizontal, horizontalSizeClass == .regular ? 0 : 20)
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
//    let onNewSale: () -> Void
//    let onLookBuilder: () -> Void
//    let onOmnichannel: () -> Void

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
//                
//                QuickActionCard(
//                    icon: "shippingbox.and.arrow.backward",
//                    label: "Omnichannel",
//                    color: RSMSTheme.success,
//                    onTap: onOmnichannel
//                )
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 0 : 20)
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
    @Environment(AppViewModel.self) private var appViewModel
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    @State private var clientToDelete: ClientProfile? = nil
    @State private var showDeleteAlert = false
    
    let filters = ["All", "VIP", "Platinum", "Gold", "Silver"]
    
    private var filteredGroupedClients: [ClientGroup] {
        var clients = appViewModel.dataStore.clients
        
        // 1. Filter by Tier
        if selectedFilter != "All" {
            if selectedFilter == "VIP" {
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
                // Header, Search, and Filters stay pinned at the top
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clients")
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            
                            Text("\(filteredGroupedClients.flatMap { $0.clients }.count) contacts")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            circleButton(icon: "slider.horizontal.3") {
                                // Filter action
                            }
                            circleButton(icon: "plus") {
                                onAddClient()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(RSMSTheme.textSecondary)
                        TextField("Search", text: $searchText)
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(RSMSTheme.surfacePrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(RSMSTheme.border, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    )
                    .padding(.horizontal, 24)
                    
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
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
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
    
    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(RSMSTheme.surfacePrimary)
                    .frame(width: 42, height: 42)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(RSMSTheme.primary)
            }
        }
        .buttonStyle(.plain)
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
            
            // Activity & Chevron
            VStack(alignment: .trailing, spacing: 8) {
                Text("Today")
                    .font(.system(size: 13))
                    .foregroundStyle(RSMSTheme.textTertiary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
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
