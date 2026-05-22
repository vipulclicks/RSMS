import SwiftUI

// MARK: - Sidebar Sections

enum SalesAssociateSection: String, CaseIterable, Identifiable {
    case dashboard    = "Dashboard"
    case clients  = "Clients"
    case appointments = "Appointments"
    case selling      = "Assisted Selling"
    case pos          = "POS & Checkout"
    case omnichannel  = "Omnichannel"
    case profile      = "Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:    return "square.grid.2x2.fill"
        case .clients:  return "person.crop.circle.fill"
        case .appointments: return "calendar"
        case .selling:      return "wand.and.stars"
        case .pos:          return "cart.fill"
        case .omnichannel:  return "shippingbox.and.arrow.backward.fill"
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
    @State private var showSidebarSheet = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss

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
    }

    // MARK: - Adaptivity Content Routing

    @ViewBuilder
    private func mainContentView(_ appointmentVM: AppointmentViewModel) -> some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebar(appointmentVM)
            } detail: {
                NavigationStack(path: $navigationPath) {
                    detailView(appointmentVM)
                }
            }
            .navigationSplitViewStyle(.prominentDetail)
        } else {
            ZStack(alignment: .leading) {
                NavigationStack(path: $navigationPath) {
                    detailView(appointmentVM)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showSidebarSheet = true
                                    }
                                } label: {
                                    Image(systemName: "sidebar.left")
                                        .foregroundStyle(RSMSTheme.primary)
                                }
                                .accessibilityLabel("Menu")
                            }
                        }
                }
                
                if showSidebarSheet {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSidebarSheet = false
                            }
                        }
                        .zIndex(1)
                    
                    NavigationStack {
                        sidebar(appointmentVM)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showSidebarSheet = false
                                        }
                                    } label: {
                                        Image(systemName: "sidebar.right")
                                            .foregroundStyle(RSMSTheme.primary)
                                    }
                                }
                            }
                    }
                    .frame(width: min(UIScreen.main.bounds.width - 60, 320))
                    .background(RSMSTheme.backgroundGradient)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 5, y: 0)
                    .padding(.top, 44)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .leading))
                    .zIndex(2)
                    .onChange(of: selectedSection) { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSidebarSheet = false
                        }
                        navigationPath.removeLast(navigationPath.count)
                    }
                }
            }
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

                        DashboardHeaderView()

                        KPIGridView(appointmentVM: appointmentVM, viewWidth: geometry.size.width)

                        UpcomingAppointmentsSection(appointmentVM: appointmentVM)

                        QuickActionsSection(
                            columnsCount: 2,
                            onNewClient: { showNewClientSheet = true },
                            onNewSale: { navigationPath.append("POS") },
                            onLookBuilder: { navigationPath.append("LookBuilder") },
                            onOmnichannel: { navigationPath.append("Omnichannel") }
                        )
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    navigationPath.append("Profile")
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(RSMSTheme.primary)
                }
                .accessibilityLabel("Profile")
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
                                .foregroundStyle(isSelected ? RSMSTheme.primary : Color.black.opacity(0.85))
                                .frame(width: 24)
                            
                            Text(section.rawValue)
                                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? RSMSTheme.primary : Color.black.opacity(0.85))
                            
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
        private func detailView(_ appointmentVM: AppointmentViewModel) -> some View {
            Group {
                switch selectedSection {
                case .dashboard:
                    if horizontalSizeClass == .regular {
                        ipadDashboardView(appointmentVM)
                    } else {
                        iphoneDashboardView(appointmentVM)
                    }
                case .clients:
                    SAClientBrowserView(onSelectClient: { client in
                        navigationPath.append(client)
                    })
                case .appointments:
                    AppointmentRemoteSellingView(viewModel: appointmentVM, navigationPath: $navigationPath)
                case .selling:
                    AssistedSellingView()
                case .pos:
                    POSCheckoutView()
                case .omnichannel:
                    OmnichannelView()
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
                    })
                case "Appointments":
                    AppointmentRemoteSellingView(viewModel: appointmentVM, navigationPath: $navigationPath)
                case "POS":
                    POSCheckoutView()
                case "LookBuilder":
                    LookBuilderView()
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

                            DashboardHeaderView()
                                .padding(.horizontal, 4)

                            KPIGridView(appointmentVM: appointmentVM, viewWidth: width, isSidebarClosed: true)

                            VStack(alignment: .leading, spacing: 32) {
                                UpcomingAppointmentsSection(appointmentVM: appointmentVM)
                                
                                QuickActionsSection(
                                    columnsCount: 4,
                                    onNewClient: { showNewClientSheet = true },
                                    onNewSale: { navigationPath.append("POS") },
                                    onLookBuilder: { navigationPath.append("LookBuilder") },
                                    onOmnichannel: { navigationPath.append("Omnichannel") }
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
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigationPath.append("Profile")
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(RSMSTheme.primary)
                    }
                    .accessibilityLabel("Profile")
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

    var body: some View {
        let firstName = appViewModel.currentUser?.fullName.components(separatedBy: " ").first ?? "there"
        let todayStr = RSMSDateFormatter.fullDate.string(from: .now)
        let storeName = appViewModel.currentUser?.storeId.map { appViewModel.dataStore.storeName(for: $0) } ?? "Unknown Store"

        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting(for: .now)), \(firstName)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.primary)
                    Text(storeName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
            Spacer()
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
                value: appointmentVM.todaySalesGoalTarget,
                label: "Today's Sales",
                trend: "+12% vs yesterday",
                trendColor: RSMSTheme.success
            )

            KPICard(
                icon: "calendar.circle.fill",
                value: String(appointmentVM.upcomingAppointments.count),
                label: "Today's Appointments",
                trend: nil,
                iconColor: RSMSTheme.info
            )

            KPICard(
                icon: "person.2.circle.fill",
                value: "3",
                label: "Clients Served",
                trend: nil,
                iconColor: RSMSTheme.success
            )

            KPICard(
                icon: "clock.circle.fill",
                value: appointmentVM.upcomingAppointments.first.map {
                    RSMSDateFormatter.dateTime.string(from: $0.dateTime)
                } ?? "None today",
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
    let onNewSale: () -> Void
    let onLookBuilder: () -> Void
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
                
                QuickActionCard(
                    icon: "cart.badge.plus",
                    label: "New Sale",
                    color: RSMSTheme.info,
                    onTap: onNewSale
                )
                
                QuickActionCard(
                    icon: "wand.and.stars",
                    label: "Look Builder",
                    color: RSMSTheme.warning,
                    onTap: onLookBuilder
                )
                
                QuickActionCard(
                    icon: "shippingbox.and.arrow.backward",
                    label: "Omnichannel",
                    color: RSMSTheme.success,
                    onTap: onOmnichannel
                )
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 0 : 20)
    }
}

// MARK: - Client Browser & Row for Navigation Stack

struct SAClientBrowserView: View {
    @Environment(DataStore.self) private var dataStore
    let onSelectClient: (ClientProfile) -> Void
    @State private var searchText = ""
    @State private var showSearchBar = false
    @State private var showOnboarding = false

    private var clients: [ClientProfile] {
        dataStore.clients
    }

    private var filteredClients: [ClientProfile] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return clients }
        return clients.filter {
            $0.fullName.lowercased().contains(q) ||
            ($0.email?.lowercased().contains(q) ?? false) ||
            ($0.phone?.contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if showSearchBar {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    
                    TextField("Search by name, email, or phone...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(RSMSTheme.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            List {
                ForEach(filteredClients) { client in
                    Button {
                        onSelectClient(client)
                    } label: {
                        SAClientRow(client: client)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(RSMSTheme.background)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Clients")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .fontWeight(.medium)
                    }
                    .accessibilityLabel("Search Clients")
                    
                    Button {
                        showOnboarding = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .fontWeight(.medium)
                    }
                    .accessibilityLabel("Add New Client")
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            NewClientOnboardingView()
                .environment(dataStore)
        }
        .overlay {
            if filteredClients.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}

private struct SAClientRow: View {
    let client: ClientProfile

    private var initials: String {
        client.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.primary.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(initials)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(RSMSTheme.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(client.fullName)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    StatusBadge(
                        text: client.vipTier.rawValue.uppercased(),
                        color: tierColor(client.vipTier)
                    )
                }
                if let contact = client.email ?? client.phone {
                    Text(contact)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if !client.privacyConsentGiven {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(RSMSTheme.warning)
                    .font(.caption)
                    .accessibilityLabel("Privacy consent not given")
            }

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func tierColor(_ tier: VIPTier) -> Color {
        switch tier {
        case .standard: return RSMSTheme.textSecondary
        case .silver:   return Color(red: 192/255, green: 192/255, blue: 192/255)
        case .gold:     return RSMSTheme.primary
        case .platinum: return Color(red: 176/255, green: 196/255, blue: 222/255)
        case .prive:    return RSMSTheme.danger
        }
    }
}

// MARK: - Previews

#Preview("iPhone — Sales Associate") {
    let vm = AppViewModel()
    vm.login(as: .salesAssociate)
    return SalesAssociateHomeView()
        .environment(vm)
        .environment(vm.dataStore)
}

#Preview("iPad", traits: .fixedLayout(width: 1024, height: 768)) {
    let vm = AppViewModel()
    vm.login(as: .salesAssociate)
    return SalesAssociateHomeView()
        .environment(vm)
        .environment(vm.dataStore)
}
