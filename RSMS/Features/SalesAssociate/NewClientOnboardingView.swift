//
//  NewClientOnboardingView.swift
//  RSMS
//
//  Multi-step client onboarding sheet for creating a new ClientProfile.
//  Uses LuxuryFormComponents for consistent luxury styling.
//

import SwiftUI

struct NewClientOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var viewModel = NewClientOnboardingViewModel()

    // Anniversary Sub-Form State
    @State private var isAddingAnniversary = false
    @State private var newAnnTitle = "Birthday"
    @State private var newAnnDate = Date()
    @State private var newAnnReminder = true
    @State private var newAnnNotes = ""

    // Wishlist Search State
    @State private var productSearchText = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                RSMSTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 20) {
                            stepContent
                            navigationButtons
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }

                if viewModel.showSuccessBanner {
                    successBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .alert("Missing Information", isPresented: $viewModel.showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter the client's full name before proceeding.")
            }
            .onAppear {
                viewModel.dataStore = dataStore
                if let currentUser = dataStore.users.first { // Default to current user's store if possible
                    viewModel.preferredStoreId = currentUser.storeId
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<viewModel.stepCount, id: \.self) { index in
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(index <= viewModel.currentStep
                                  ? RSMSTheme.primary : RSMSTheme.surfacePrimary)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(
                                    index <= viewModel.currentStep
                                    ? RSMSTheme.primary : RSMSTheme.border,
                                    lineWidth: 1.5
                                )
                            )
                        if index < viewModel.currentStep {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RSMSTheme.cream)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    index == viewModel.currentStep
                                    ? RSMSTheme.cream : RSMSTheme.textTertiary
                                )
                        }
                    }

                    if index < viewModel.stepCount - 1 {
                        Rectangle()
                            .fill(index < viewModel.currentStep
                                  ? RSMSTheme.primary : RSMSTheme.border)
                            .frame(height: 2)
                    }
                }
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 0: identityStep
        case 1: preferencesStep
        case 2: datesStep
        case 3: wishlistStep
        case 4: consentStep
        default: EmptyView()
        }
    }

    // MARK: Step 1 — Identity

    private var identityStep: some View {
        LuxuryFormCard(title: "Client Identity", icon: "person.fill") {
            LuxuryTextField(title: "Full Name *", text: $viewModel.fullName)
            LuxuryTextField(title: "Email", text: $viewModel.email)
            LuxuryTextField(title: "Phone", text: $viewModel.phone)
        }
    }

    // MARK: Step 2 — Preferences & Sizing

    private var preferencesStep: some View {
        VStack(spacing: 20) {
            LuxuryFormCard(title: "Shoes & Belts", icon: "shoe.fill") {
                HStack(spacing: 16) {
                    LuxurySizeField(title: "Shoe Size", text: $viewModel.shoeSize, presets: LuxurySizePresets.shoes)
                    LuxuryPicker(title: "Shoe Fit", selection: $viewModel.shoeFit, options: ["Regular", "Wide", "Narrow"])
                }
                HStack(spacing: 16) {
                    LuxurySizeField(title: "Belt Size", text: $viewModel.beltSize, presets: LuxurySizePresets.belts)
                    LuxuryTextField(title: "Buckle Pref", text: $viewModel.bucklePref)
                }
            }

            LuxuryFormCard(title: "Jewellery & Watches", icon: "sparkles") {
                HStack(spacing: 16) {
                    LuxurySizeField(title: "Ring Size", text: $viewModel.ringSize, presets: LuxurySizePresets.rings)
                    LuxurySizeField(title: "Bracelet Size", text: $viewModel.braceletSize, presets: LuxurySizePresets.bracelets)
                }
                HStack(spacing: 16) {
                    LuxurySizeField(title: "Necklace Length", text: $viewModel.necklaceLength, presets: LuxurySizePresets.necklaces)
                    LuxurySizeField(title: "Wrist Size", text: $viewModel.wristSize, presets: LuxurySizePresets.wristSizes)
                }
                HStack(spacing: 16) {
                    LuxuryPicker(title: "Preferred Metal", selection: $viewModel.preferredMetal, options: ["", "Gold", "Platinum", "Silver", "Rose Gold"])
                    LuxuryPicker(title: "Strap Material", selection: $viewModel.strapMaterial, options: ["Metal", "Leather", "Rubber"])
                }
                LuxuryTextField(title: "Watch Case Preference", text: $viewModel.watchCasePref)
            }

            LuxuryFormCard(title: "Handbags & Perfumes", icon: "handbag.fill") {
                HStack(spacing: 16) {
                    LuxuryPicker(title: "Bag Size", selection: $viewModel.bagSize, options: ["Mini", "Small", "Medium", "Large"])
                    LuxuryPicker(title: "Bag Style", selection: $viewModel.bagStyle, options: ["Tote", "Crossbody", "Clutch", "Shoulder", "Satchel"])
                }
                HStack(spacing: 16) {
                    LuxuryPicker(title: "Bag Material", selection: $viewModel.bagMaterial, options: ["Leather", "Canvas", "Exotic"])
                    LuxuryPicker(title: "Fragrance Family", selection: $viewModel.fragranceFamily, options: ["Woody", "Floral", "Oriental", "Citrus", "Fresh"])
                }
                HStack(spacing: 16) {
                    LuxuryPicker(title: "Fragrance Strength", selection: $viewModel.fragranceStrength, options: ["EDT", "EDP", "Parfum"])
                    LuxuryPicker(title: "Scent Preference", selection: $viewModel.scentPref, options: ["Mild", "Strong", "Long-lasting"])
                }
            }

            LuxuryFormCard(title: "Style & Brands", icon: "heart.fill") {
                LuxuryTextField(title: "Favourite Categories (comma-separated)", text: $viewModel.favoriteCategories)
                LuxuryTextField(title: "Favourite Metals (comma-separated)", text: $viewModel.favoriteMetals)
                LuxuryTextField(title: "Favourite Gemstones (comma-separated)", text: $viewModel.favoriteGemstones)
                LuxuryTextField(title: "Favourite Brands", text: $viewModel.favoriteBrands)
                LuxuryTextField(title: "Favourite Colors", text: $viewModel.favoriteColors)
                HStack(spacing: 16) {
                    LuxuryPicker(title: "Style", selection: $viewModel.stylePreference,
                                 options: ["Classic", "Modern", "Sporty Luxury", "Bohemian", "Minimalist"])
                    LuxuryPicker(title: "Shopping", selection: $viewModel.shoppingPreference,
                                 options: ["In-store", "In-store appointment", "Remote Selling", "Online"])
                }
            }
        }
    }

    // MARK: Step 3 — Important Dates

    private var datesStep: some View {
        VStack(spacing: 20) {
            LuxuryFormCard(title: "Important Dates", icon: "calendar") {
                if viewModel.anniversaries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.largeTitle)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text("No special dates added yet")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.anniversaries) { ann in
                            HStack {
                                Image(systemName: ann.title.contains("Birthday") ? "cake.emoji" : "heart.fill")
                                    .foregroundStyle(RSMSTheme.primary)
                                    .font(.subheadline)
                                    .padding(8)
                                    .background(RSMSTheme.primary.opacity(0.1), in: Circle())
                                    .overlay(
                                        Image(systemName: "calendar")
                                            .font(.caption2)
                                            .foregroundStyle(RSMSTheme.primary)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ann.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Text(ann.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                    if !ann.notes.isEmpty {
                                        Text(ann.notes)
                                            .font(.caption2)
                                            .foregroundStyle(RSMSTheme.textTertiary)
                                    }
                                }
                                Spacer()

                                Button(role: .destructive) {
                                    if let idx = viewModel.anniversaries.firstIndex(where: { $0.id == ann.id }) {
                                        viewModel.anniversaries.remove(at: idx)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.subheadline)
                                        .foregroundStyle(RSMSTheme.danger)
                                }
                            }
                            .padding(10)
                            .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))
                        }
                    }
                }

                if !isAddingAnniversary {
                    Button {
                        withAnimation(.spring()) {
                            isAddingAnniversary = true
                        }
                    } label: {
                        Label("Add Special Date", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RSMSTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RSMSTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.primary.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.top, 8)
                }
            }

            if isAddingAnniversary {
                LuxuryFormCard(title: "New Special Date", icon: "calendar.badge.plus") {
                    LuxuryPicker(title: "Occasion", selection: $newAnnTitle, options: ["Birthday", "Wedding Anniversary", "Graduation", "Engagement", "Other"])
                    DatePicker("Date", selection: $newAnnDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(RSMSTheme.primary)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    Toggle("Enable Reminder", isOn: $newAnnReminder)
                        .tint(RSMSTheme.primary)
                        .font(.subheadline)
                    LuxuryTextField(title: "Notes (optional)", text: $newAnnNotes)

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            withAnimation(.spring()) {
                                isAddingAnniversary = false
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))

                        Button("Add Date") {
                            let newAnn = NewAnniversaryInput(
                                title: newAnnTitle,
                                date: newAnnDate,
                                reminderEnabled: newAnnReminder,
                                notes: newAnnNotes
                            )
                            viewModel.anniversaries.append(newAnn)
                            // Reset state
                            newAnnTitle = "Birthday"
                            newAnnDate = Date()
                            newAnnReminder = true
                            newAnnNotes = ""
                            withAnimation(.spring()) {
                                isAddingAnniversary = false
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RSMSTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    // MARK: Step 4 — Wishlist Setup

    private var wishlistStep: some View {
        LuxuryFormCard(title: "Client Wishlist (Optional)", icon: "star.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select items the client is interested in adding to their wishlist:")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    TextField("Search products...", text: $productSearchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                .padding(10)
                .background(RSMSTheme.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.border, lineWidth: 1))

                let filteredProducts = dataStore.products.filter {
                    productSearchText.isEmpty || $0.name.localizedCaseInsensitiveContains(productSearchText) || $0.sku.localizedCaseInsensitiveContains(productSearchText)
                }

                if filteredProducts.isEmpty {
                    Text("No products found")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(filteredProducts) { product in
                                let isSelected = viewModel.selectedProductIds.contains(product.id)

                                VStack(spacing: 0) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .font(.title3)
                                            .foregroundStyle(RSMSTheme.primary)
                                            .frame(width: 40, height: 40)
                                            .background(RSMSTheme.primary.opacity(0.08), in: Circle())

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(product.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(RSMSTheme.textPrimary)
                                            Text("SKU: \(product.sku) • ₹\(Int(product.price).formatted())")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.textSecondary)
                                        }
                                        Spacer()

                                        Button {
                                            withAnimation(.spring(duration: 0.3)) {
                                                viewModel.toggleProductSelection(product.id)
                                            }
                                        } label: {
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.title3)
                                                .foregroundStyle(isSelected ? RSMSTheme.primary : RSMSTheme.border)
                                        }
                                    }
                                    .padding(8)

                                    if isSelected {
                                        TextField("Notes (e.g. size preference)", text: Binding(
                                            get: { viewModel.productNotes[product.id] ?? "" },
                                            set: { viewModel.productNotes[product.id] = $0 }
                                        ))
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(RSMSTheme.background, in: RoundedRectangle(cornerRadius: 6))
                                        .padding(.horizontal, 8)
                                        .padding(.bottom, 8)
                                    }
                                }
                                .background(isSelected ? RSMSTheme.primary.opacity(0.03) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? RSMSTheme.primary.opacity(0.3) : RSMSTheme.border, lineWidth: 1))
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
    }

    // MARK: Step 5 — Privacy & Consent

    private var consentStep: some View {
        VStack(spacing: 20) {


            LuxuryFormCard(title: "Preferred Channels", icon: "paperplane.fill") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select how the client prefers to be contacted:")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)

                    Grid(horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            channelToggle(title: "Email", icon: "envelope.fill", isOn: $viewModel.preferredEmail)
                            channelToggle(title: "SMS", icon: "message.fill", isOn: $viewModel.preferredSMS)
                        }
                        GridRow {
                            channelToggle(title: "Phone Call", icon: "phone.fill", isOn: $viewModel.preferredPhone)
                            channelToggle(title: "WhatsApp", icon: "phone.bubble.left.fill", isOn: $viewModel.preferredWhatsApp)
                        }
                    }
                }
            }

            LuxuryFormCard(title: "Summary & Notes", icon: "note.text") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Associate Notes")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(RSMSTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSTheme.border, lineWidth: 1)
                        )
                        .foregroundStyle(RSMSTheme.textPrimary)
                }

                // Summary
                VStack(alignment: .leading, spacing: 6) {
                    Text("ONBOARDING RECAP")
                        .font(.caption2.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .padding(.bottom, 4)

                    recapRow(label: "Name", value: viewModel.fullName)
                    recapRow(label: "Dates", value: "\(viewModel.anniversaries.count) added")
                    recapRow(label: "Wishlist", value: "\(viewModel.selectedProductIds.count) items selected")

                }
                .font(.subheadline)
                .padding(.top, 8)
            }
        }
    }

    private func channelToggle(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) {
                isOn.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(isOn.wrappedValue ? RSMSTheme.cream : RSMSTheme.primary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isOn.wrappedValue ? RSMSTheme.cream : RSMSTheme.textPrimary)
                Spacer()
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(isOn.wrappedValue ? RSMSTheme.cream : RSMSTheme.border)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isOn.wrappedValue ? RSMSTheme.primaryGradient : LinearGradient(colors: [RSMSTheme.surfacePrimary], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isOn.wrappedValue ? RSMSTheme.primary : RSMSTheme.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func recapRow(label: String, value: String, valueColor: Color = RSMSTheme.textPrimary) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(RSMSTheme.textSecondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep > 0 {
                Button {
                    viewModel.previousStep()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(RSMSTheme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Button {
                if viewModel.isLastStep {
                    Task {
                        await viewModel.saveClient()
                        dismiss()
                    }
                } else {
                    viewModel.nextStep()
                }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(RSMSTheme.cream)
                    } else {
                        Text(viewModel.isLastStep ? "Save Client" : "Continue")
                        if !viewModel.isLastStep {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .font(.headline)
                .foregroundStyle(RSMSTheme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RSMSTheme.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 12, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(viewModel.isSaving)
        }
        .padding(.top, 8)
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(RSMSTheme.primary)
                .font(.title3)
            Text("Client profile created successfully")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(RSMSTheme.primary.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .padding(.top, 16)
    }
}

// MARK: - Preview

#Preview {
    let mock = DataStore()
    return NewClientOnboardingView()
        .environment(mock)
}
