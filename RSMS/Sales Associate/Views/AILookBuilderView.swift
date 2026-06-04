//
//  AILookBuilderView.swift
//  RSMS
//

import SwiftUI

struct AILookBuilderView: View {
    @State private var viewModel: AILookBuilderViewModel
    @State private var viewMode: ViewMode = .generate
    @Environment(\.dismiss) private var dismiss
    
    enum ViewMode {
        case generate
        case saved
    }
    
    init(client: ClientProfile, dataStore: DataStore, associateId: UUID) {
        _viewModel = State(initialValue: AILookBuilderViewModel(client: client, dataStore: dataStore, associateId: associateId))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View Mode Selector
            Picker("View Mode", selection: $viewMode) {
                Text("Generate").tag(ViewMode.generate)
                Text("Saved Looks").tag(ViewMode.saved)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(RSMSTheme.surfacePrimary)
            
            Divider().background(RSMSTheme.border)
            
            if viewMode == .generate {
                // Occasion Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Occasion")
                        .font(.headline)
                        .foregroundColor(RSMSTheme.textPrimary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Occasion.allCases) { occasion in
                                OccasionPill(
                                    title: occasion.rawValue,
                                    isSelected: viewModel.selectedOccasion == occasion
                                ) {
                                    viewModel.selectedOccasion = occasion
                                    Task {
                                        await viewModel.generateLooks()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(RSMSTheme.surfacePrimary)
                
                Divider().background(RSMSTheme.border)
            }
            
            // Content
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(RSMSTheme.primary)
                        Text(viewMode == .generate ? "Curating looks based on \(viewModel.client.fullName)'s preferences..." : "Loading saved looks...")
                            .font(.body)
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(RSMSTheme.danger)
                        Text(error)
                            .font(.body)
                            .foregroundColor(RSMSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            Task {
                                if viewMode == .generate {
                                    await viewModel.generateLooks()
                                } else {
                                    await viewModel.fetchSavedLooks()
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    if viewMode == .generate {
                        if viewModel.generatedLooks.isEmpty {
                            VStack(spacing: 8) {
                                Text("Select an occasion to generate personalized looks.")
                                    .font(.body)
                                    .foregroundColor(RSMSTheme.textSecondary)
                            }
                        } else {
                            ScrollView {
                                VStack(spacing: 24) {
                                    ForEach(viewModel.generatedLooks) { look in
                                        let isSaved = viewModel.isLookSaved(look)
                                        LookCardView(
                                            look: look,
                                            isSaved: isSaved,
                                            onSaveToggle: {
                                                Task {
                                                    if isSaved {
                                                        await viewModel.unsaveLook(look)
                                                    } else {
                                                        await viewModel.saveLook(look)
                                                    }
                                                }
                                            },
                                            sharePayload: viewModel.sharePayload(for: look)
                                        )
                                    }
                                }
                                .padding()
                            }
                        }
                    } else {
                        if viewModel.savedOutfits.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bookmark")
                                    .font(.largeTitle)
                                    .foregroundColor(RSMSTheme.textSecondary)
                                Text("No saved looks found for \(viewModel.client.fullName).")
                                    .font(.body)
                                    .foregroundColor(RSMSTheme.textSecondary)
                            }
                        } else {
                            ScrollView {
                                VStack(spacing: 24) {
                                    ForEach(viewModel.savedOutfits) { outfit in
                                        let look = viewModel.generatedLook(from: outfit)
                                        LookCardView(
                                            look: look,
                                            isSaved: true,
                                            onSaveToggle: {
                                                Task {
                                                    await viewModel.unsaveLook(look)
                                                }
                                            },
                                            sharePayload: viewModel.sharePayload(for: look)
                                        )
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RSMSTheme.background)
        }
        .navigationTitle("AI Look Builder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        }
        .onAppear {
            Task {
                await viewModel.fetchSavedLooks()
                if viewModel.generatedLooks.isEmpty {
                    await viewModel.generateLooks()
                }
            }
        }
        .onChange(of: viewMode) { _, newValue in
            if newValue == .saved {
                Task {
                    await viewModel.fetchSavedLooks()
                }
            }
        }
    }
}

struct OccasionPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? RSMSTheme.surfacePrimary : RSMSTheme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? RSMSTheme.primary : RSMSTheme.surfaceSecondary)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : RSMSTheme.border, lineWidth: 1)
                )
        }
    }
}
