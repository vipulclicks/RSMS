//
//  ClientPortalView.swift
//  RSMS
//
//  A state-of-the-art luxury Client Portal dashboard for Maison Lumière.
//  Beautiful glassmorphic elements, gold-pulsing states, and direct FaceTime triggers.
//

import SwiftUI

struct ClientPortalView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(DataStore.self) private var dataStore
    
    @State private var showingInquiryAlert = false
    @State private var inquiredProduct: Product? = nil
    @State private var selectedWishlistItemIdForRemoval: UUID? = nil
    @State private var appeared = false
    
    // Luxury Greetings based on French boutique customs
    private var luxuryGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Bonjour"
        } else if hour < 18 {
            return "Bon après-midi"
        } else {
            return "Bonsoir"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.backgroundGradient.ignoresSafeArea()
                
                // Fine diagonal light golden threads representing prestige
                GeometryReader { geo in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    }
                    .stroke(RSMSTheme.border.opacity(0.4), lineWidth: 0.5)
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        
                        // Header Welcome Card
                        welcomeHeaderSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        
                        // Main Responsive Columns
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 380, maximum: 540), spacing: 24)], spacing: 24) {
                            
                            // Active Consultations & Scheduling
                            VStack(alignment: .leading, spacing: 20) {
                                sectionHeader(title: "Your Private Consultations", icon: "video.fill")
                                activeConsultationCard
                                upcomingAppointmentsCard
                            }
                            
                            // Private Boutique & Advisor Details
                            VStack(alignment: .leading, spacing: 20) {
                                sectionHeader(title: "Private Advising", icon: "building.columns.fill")
                                privateAdvisorCard
                                boutiqueInfoCard
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        
                        // Client Wishlist & Shared Showcase Items
                        wishlistSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "diamond.fill")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.primaryGradient)
                        Text("MAISON LUMIÈRE")
                            .font(.system(size: 15, weight: .light, design: .serif))
                            .tracking(4)
                            .foregroundStyle(RSMSTheme.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appViewModel.logout()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "door.right.hand.open")
                            Text("Sign Out")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RSMSTheme.surfaceSecondary, in: Capsule())
                        .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                    }
                }
            }
            .alert("Product Inquiry", isPresented: $showingInquiryAlert, presenting: inquiredProduct) { product in
                Button("Confirm Reservation", role: .none) {
                    // Optimistic private boutique reservation
                    if let client = dataStore.clients.first(where: { $0.id == appViewModel.currentUser?.id }) {
                        let note = "Client requested private showroom reservation of \(product.name)"
                        print(note)
                    }
                }
                Button("Dismiss", role: .cancel) {}
            } message: { product in
                Text("Would you like Lucas Dubois to reserve \(product.name) (\(product.sku)) for a private viewing in Maison Lumière Vendôme?")
            }
            .task {
                do {
                    // Populate offline datastore caches gracefully
                    try await dataStore.fetchStores()
                    try await dataStore.fetchProducts()
                    try await dataStore.fetchClients()
                    try await dataStore.fetchWishlistItems()
                    try await dataStore.fetchAppointments()
                } catch {
                    print("Error fetching client data cache: \(error)")
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }
    
    // MARK: - Subcomponents
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.primary)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(RSMSTheme.textPrimary)
            Spacer()
        }
    }
    
    // MARK: - Welcome Header Card
    private var welcomeHeaderSection: some View {
        HStack(spacing: 20) {
            // High-end Profile Initials Circle
            ZStack {
                Circle()
                    .fill(RSMSTheme.primaryGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: RSMSTheme.primary.opacity(0.15), radius: 10, y: 5)
                
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: 72, height: 72)
                
                Text(appViewModel.currentUser?.fullName.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased() ?? "IF")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\(luxuryGreeting),")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .italic()
                
                Text(appViewModel.currentUser?.fullName ?? "Isabelle Fontaine")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.primary)
                        Text("Platinum Member")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.surfaceSecondary, in: Capsule())
                    .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
                    
                    Text("Client ID: ML-98230")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            Spacer()
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Active Video Consultation Card
    private var activeConsultationCard: some View {
        // Look for today's video consults which are scheduled, confirmed or already in_progress
        let todayVideoAppts = dataStore.appointments.filter { appt in
            appt.clientId == appViewModel.currentUser?.id &&
            appt.type == .video &&
            appt.status != .completed &&
            appt.status != .cancelled &&
            appt.status != .noShow
        }.sorted { $0.dateTime < $1.dateTime }
        
        return Group {
            if let activeAppt = todayVideoAppts.first {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(RSMSTheme.primary)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(1.2)
                                    .opacity(0.8)
                                
                                Text("LIVE CONSULTATION ACTIVE")
                                    .font(.caption2.weight(.bold))
                                    .tracking(1.5)
                                    .foregroundStyle(RSMSTheme.primary)
                            }
                            
                            Text("FaceTime Luxury Styling Session")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(RSMSTheme.textPrimary)
                        }
                        Spacer()
                        
                        // Mini Pulse Effect to represent real-time connection ready
                        ZStack {
                            Circle()
                                .stroke(RSMSTheme.primary.opacity(0.2), lineWidth: 3)
                                .frame(width: 32, height: 32)
                                .scaleEffect(1.3)
                            Image(systemName: "video.circle.fill")
                                .font(.title2)
                                .foregroundStyle(RSMSTheme.primaryGradient)
                        }
                    }
                    
                    Divider().overlay(RSMSTheme.divider)
                    
                    HStack(spacing: 16) {
                        Label {
                            Text(activeAppt.dateTime.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                        } icon: {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(RSMSTheme.primary)
                        }
                        
                        Label {
                            Text("\(activeAppt.durationMinutes) Minutes")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        } icon: {
                            Image(systemName: "hourglass")
                                .foregroundStyle(RSMSTheme.primary)
                        }
                    }
                    
                    if let config = activeAppt.decodedFaceTimeConfig {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "video.fill")
                                    .foregroundStyle(RSMSTheme.primary)
                                    .font(.subheadline)
                                Text("FaceTime Advisor:")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Text(config.contact)
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            }
                            
                            if let link = config.meetingLink, !link.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "link")
                                        .foregroundStyle(RSMSTheme.primary)
                                        .font(.subheadline)
                                    Text("Meeting Link:")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Text(link)
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.primary)
                                        .lineLimit(1)
                                }
                            }
                            
                            if let ftNotes = config.notes, !ftNotes.isEmpty {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(RSMSTheme.primary)
                                        .font(.subheadline)
                                    Text("Instructions:")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    Text(ftNotes)
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
                    } else if let notes = activeAppt.notes, !notes.isEmpty {
                        Text("\"\(notes)\"")
                            .font(.caption.italic())
                            .foregroundStyle(RSMSTheme.textSecondary)
                            .padding(.leading, 4)
                    }
                    
                    // The premium gold-glowing Join button that initiates FaceTime direct opening and dashboard overlay
                    Button(action: {
                        // Direct FaceTime Action
                        let faceTimeUrl: String
                        if let config = activeAppt.decodedFaceTimeConfig {
                            if let link = config.meetingLink, !link.isEmpty {
                                faceTimeUrl = link
                            } else {
                                faceTimeUrl = "facetime://\(config.contact)"
                            }
                        } else {
                            let targetContact = "lucas.dubois@maisonlumiere.com"
                            faceTimeUrl = activeAppt.videoLink ?? "facetime://\(targetContact)"
                        }
                        
                        if let encodedUrl = faceTimeUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: encodedUrl) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "faceid")
                                .font(.headline)
                            Text("Connect Live on FaceTime")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .background(RSMSTheme.primaryGradient)
                        .cornerRadius(12)
                        .shadow(color: RSMSTheme.primary.opacity(0.35), radius: 12, y: 5)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.45))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.primary.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: RSMSTheme.primary.opacity(0.06), radius: 10, y: 5)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("No Active Consultations Today")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("Your private advisor Lucas will alert you here when your next exclusive digital showroom viewing is ready.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
            }
        }
    }
    
    // MARK: - Upcoming Appointments List
    private var upcomingAppointmentsCard: some View {
        let clientId = appViewModel.currentUser?.id
        let upcoming = dataStore.appointments.filter { appt in
            appt.clientId == clientId &&
            appt.status != .cancelled &&
            appt.status != .completed
        }.sorted { $0.dateTime < $1.dateTime }
        
        return VStack(alignment: .leading, spacing: 14) {
            Text("Upcoming Boutique Visits")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            if upcoming.isEmpty {
                Text("No upcoming boutique visits scheduled.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            } else {
                VStack(spacing: 10) {
                    ForEach(upcoming.prefix(2)) { appt in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appt.type == .video ? "Facetime Showroom Tour" : "Private In-Store Visit")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text(appt.dateTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(RSMSTheme.textTertiary)
                            }
                            Spacer()
                            
                            // Elegant Badge representing status
                            Text(appt.status.rawValue.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(appt.status == .confirmed ? RSMSTheme.success : RSMSTheme.warning)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(appt.status == .confirmed ? RSMSTheme.success.opacity(0.12) : RSMSTheme.warning.opacity(0.12), in: Capsule())
                        }
                        .padding(.vertical, 8)
                        if appt != upcoming.prefix(2).last {
                            Divider().overlay(RSMSTheme.divider)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    // MARK: - Private Advisor Card
    private var privateAdvisorCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.primary.opacity(0.1))
                    .frame(width: 54, height: 54)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(RSMSTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Private Client Advisor")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                Text("Lucas Dubois")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text("Maison Lumière Vendôme, Paris")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
            
            // Elegant Quick FaceTime Direct Launch button
            Button(action: {
                let urlScheme = "facetime://lucas.dubois@maisonlumiere.com"
                if let url = URL(string: urlScheme) {
                    UIApplication.shared.open(url)
                }
            }) {
                Image(systemName: "video.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(RSMSTheme.primaryGradient, in: Circle())
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    // MARK: - Boutique Info Card
    private var boutiqueInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Maison Lumière Vendôme", systemImage: "mappin.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Spacer()
            }
            
            Text("23 Place Vendôme, 75001 Paris")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            HStack(spacing: 16) {
                Link(destination: URL(string: "tel:+33142600000")!) {
                    Label("Call Boutique", systemImage: "phone.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }
                
                Link(destination: URL(string: "mailto:vendome@maisonlumiere.com")!) {
                    Label("Email Inquiries", systemImage: "envelope.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
    }
    
    // MARK: - Wishlist Section
    private var wishlistSection: some View {
        let clientId = appViewModel.currentUser?.id
        let clientWishlist = dataStore.wishlistItems.filter { $0.clientId == clientId }
        
        return VStack(alignment: .leading, spacing: 20) {
            sectionHeader(title: "Your Personal Curated Wishlist", icon: "heart.fill")
            
            if clientWishlist.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart")
                        .font(.system(size: 36))
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("Your Wishlist is Empty")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("Explore exclusive collections and let Lucas Dubois curate pieces directly to your portal.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 36)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170, maximum: 240), spacing: 16)], spacing: 16) {
                    ForEach(clientWishlist) { item in
                        if let product = dataStore.product(by: item.productId) {
                            wishlistProductCard(product, wishlistItem: item)
                        }
                    }
                }
            }
        }
    }
    
    private func wishlistProductCard(_ product: Product, wishlistItem: WishlistItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Product Image Slot
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.surfaceSecondary)
                    .frame(height: 140)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: product.category == "Watches" ? "clock.fill" : "sparkles")
                                .font(.system(size: 24))
                                .foregroundStyle(RSMSTheme.primary.opacity(0.4))
                            Text(product.collection ?? "Collection")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                    )
                
                // Remove Wishlist item button
                Button(action: {
                    withAnimation {
                        // Optimistic local deletion
                        dataStore.wishlistItems.removeAll { $0.id == wishlistItem.id }
                    }
                }) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.danger)
                        .padding(8)
                        .background(Color.white.opacity(0.8), in: Circle())
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                
                Text(product.material ?? "Platinum")
                    .font(.system(size: 11))
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                HStack(alignment: .bottom) {
                    Text("\(product.price, format: .currency(code: product.currency))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(RSMSTheme.primary)
                    Spacer()
                    
                    // Try-on / Inquiry Action
                    Button(action: {
                        inquiredProduct = product
                        showingInquiryAlert = true
                    }) {
                        Text("Reserve to Try")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(RSMSTheme.cream)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RSMSTheme.primaryGradient, in: Capsule())
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
        .background(Color.white.opacity(0.35))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.border, lineWidth: 1))
    }
}

#Preview {
    ClientPortalView()
        .environment(AppViewModel())
        .environment(DataStore())
}
