import SwiftUI

struct BoutiqueEventsView: View {
    @State private var viewModel = BoutiqueEventsViewModel()
    @State private var showingCreateEventModal = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppViewModel.self) private var appVM
    @State private var animateGrid = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    let events = viewModel.events(from: appVM.dataStore).sorted(by: { $0.date < $1.date })
                    let todaysEvents = events.filter { Calendar.current.isDateInToday($0.date) }
                    let upcomingEvents = events.filter { !Calendar.current.isDateInToday($0.date) }
                    
                    if viewModel.isLoading && events.isEmpty {
                        ProgressView("Loading Events...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if events.isEmpty {
                        ContentUnavailableView("No Events", systemImage: "calendar.badge.exclamationmark", description: Text("Click 'Create Event' to schedule a Trunk Show or VIP Preview."))
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Events")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            
                            if todaysEvents.isEmpty {
                                Text("No events scheduled for today.")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 24)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(RSMSTheme.surfacePrimary)
                                            .shadow(color: Color.black.opacity(0.02), radius: 4, y: 2)
                                    )
                            } else {
                                eventGrid(for: todaysEvents)
                            }
                        }
                        .padding(.bottom, 16)
                        
                        if !upcomingEvents.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Upcoming Events")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                
                                eventGrid(for: upcomingEvents)
                            }
                            .padding(.bottom, 32)
                        }
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 16 : 32)
                .padding(.top, 24)
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationTitle("Events & Previews")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCreateEventModal) {
                CreateEventFormView(viewModel: viewModel)
            }
            .task {
                if let storeId = appVM.currentStoreId {
                    await viewModel.fetchEvents(storeId: storeId, dataStore: appVM.dataStore)
                    animateGrid = true
                }
            }
        }
    }
    
    private func eventGrid(for events: [ClientEvent]) -> some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel)) {
                    EventCard(event: event, appVM: appVM, viewModel: viewModel)
                }
                .buttonStyle(.plain)
                .opacity(animateGrid ? 1 : 0)
                .offset(y: animateGrid ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateGrid)
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            SectionHeader(title: "Events Dashboard", subtitle: "Manage Trunk Shows & VIP Previews")
            Spacer()
            Button {
                showingCreateEventModal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Event")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RSMSTheme.primaryDark)
                .clipShape(Capsule())
                .shadow(color: RSMSTheme.primaryDark.opacity(0.3), radius: 8, y: 4)
            }
        }
    }
    
    private var columns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible())]
        } else {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }
}

struct EventCard: View {
    let event: ClientEvent
    let appVM: AppViewModel
    let viewModel: BoutiqueEventsViewModel
    @State private var isHovered = false
    
    var body: some View {
        let invitations = viewModel.invitations(for: event.id, from: appVM.dataStore)
        let attendingCount = invitations.filter { $0.status == .confirmed || $0.status == .attended }.count
        
        VStack(spacing: 0) {
            // Top Section (Main Info)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.type.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(RSMSTheme.cream) // Always cream for contrast
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Group {
                                if event.type == .trunkShow {
                                    LinearGradient(colors: [RSMSTheme.primaryDark, RSMSTheme.primaryDark.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                } else {
                                    LinearGradient(colors: [RSMSTheme.gold, RSMSTheme.gold.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                }
                            }
                        )
                        .clipShape(Capsule())
                        .shadow(color: (event.type == .trunkShow ? RSMSTheme.primaryDark : RSMSTheme.gold).opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // Title
                    Text(event.title)
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Venue & Time
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.gold)
                            Text(event.location ?? "TBA")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                                .lineLimit(1)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.gold)
                            Text(event.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                    }
                }
                
                Spacer(minLength: 12)
                
                // Stylized Date Block
                VStack(spacing: 2) {
                    Text(event.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(RSMSTheme.gold)
                    Text(event.date.formatted(.dateTime.day()))
                        .font(.system(.headline, design: .serif).weight(.medium))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RSMSTheme.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(16)
            
            // Bottom Section (RSVP Summary)
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("\(invitations.count) Invited")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                
                Spacer()
                
                if attendingCount > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(RSMSTheme.success)
                            .frame(width: 5, height: 5)
                        Text("\(attendingCount) Attending")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.success)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RSMSTheme.surfaceSecondary.opacity(0.5)) // slightly darker bottom
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(RSMSTheme.surfacePrimary)
                
                // Subtle gradient overlay for luxury feel
                LinearGradient(
                    colors: [RSMSTheme.gold.opacity(0.05), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHovered ? RSMSTheme.gold.opacity(0.6) : RSMSTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.03), radius: isHovered ? 12 : 8, y: isHovered ? 6 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .task {
            // Pre-fetch invitations for this event so the card can display counts
            await viewModel.fetchInvitations(for: event.id, dataStore: appVM.dataStore)
        }
    }
}
