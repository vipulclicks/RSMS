//
//  StoreLayoutOverviewView.swift
//  RSMS
//

import SwiftUI

struct StoreLayoutOverviewView: View {
    @State private var viewModel = PlanogramViewModel()
    @State private var isShowingEdit = false
    @State private var isEditingLayout = false
    @State private var showRenameAlert = false
    @State private var zoneToRename: MerchandisingZone?
    @State private var newName = ""
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    @Environment(AppViewModel.self) private var appVM
    
    // Luxury Colors
    private let backgroundGray = RSMSTheme.background
    private let textPrimary = RSMSTheme.textPrimary
    private let textSecondary = RSMSTheme.textSecondary
    private let badgeBg = RSMSTheme.surfacePrimary.opacity(0.2)
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Store Layout Overview")
                            .font(.system(.title, design: .default).weight(.bold))
                            .foregroundColor(textPrimary)
                        Text(isEditingLayout ? "Drag items to position them, or add new fixtures." : "Select a merchandising zone to view capacity and stock health.")
                            .font(.subheadline)
                            .foregroundColor(textSecondary)
                    }
                    Spacer()
                    
                    if isEditingLayout {
                        Button("Cancel") {
                            Task {
                                viewModel.zones.removeAll()
                                await viewModel.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId ?? UUID())
                                await MainActor.run {
                                    isEditingLayout = false
                                }
                            }
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.red)
                        .padding(.trailing, 16)
                        
                        Button(action: {
                            Task {
                                isSaving = true
                                do {
                                    try await viewModel.saveZonesLayout(storeId: appVM.currentStoreId ?? UUID())
                                    await MainActor.run {
                                        isEditingLayout = false
                                        isSaving = false
                                        showSuccessMessage = true
                                        Task {
                                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                                            await MainActor.run { showSuccessMessage = false }
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        isSaving = false
                                        errorMessage = error.localizedDescription
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 4)
                                }
                                Text(isSaving ? "Saving..." : "Save Layout")
                            }
                        }
                        .disabled(isSaving)
                        .font(.footnote.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(textPrimary)
                        .clipShape(Capsule())
                    } else {
                        Button("Edit Layout") {
                            isEditingLayout = true
                        }
                        .font(.footnote.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(textPrimary)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                
                Divider()
                
                // Main Content
                layoutMap
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(32)
                    .background(backgroundGray)
                    .overlay(
                        VStack {
                            Spacer()
                            if showSuccessMessage {
                                Text("Layout successfully saved!")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                                    .shadow(radius: 5)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .padding(.bottom, 32)
                            }
                        }
                        .animation(.spring(), value: showSuccessMessage)
                    )
            }
            .background(Color.white)
            .task {
                if viewModel.zones.isEmpty {
                    await viewModel.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId ?? UUID())
                }
            }
            .navigationDestination(isPresented: $isShowingEdit) {
                if let zone = viewModel.selectedZone {
                    EditLayoutView(viewModel: viewModel, zone: zone)
                }
            }
        }
    }
    
    // MARK: - Layout Map
    private var layoutMap: some View {
        ZStack {
            // Dotted Pattern Background
            Canvas { context, size in
                let spacing: CGFloat = 20
                for x in stride(from: 0, to: size.width, by: spacing) {
                    for y in stride(from: 0, to: size.height, by: spacing) {
                        let rect = CGRect(x: x, y: y, width: 2, height: 2)
                        context.fill(Path(ellipseIn: rect), with: .color(Color.gray.opacity(0.3)))
                    }
                }
            }
            
            // Zones
            ForEach(viewModel.zones) { zone in
                let isSelected = zone.id == viewModel.selectedZone?.id
                
                ZStack {
                    switch zone.type {
                    case .table:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.white : Color(white: 0.98))
                            .shadow(color: .black.opacity(isSelected ? 0.15 : 0), radius: 10, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                            )
                    case .wall:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                            )
                    case .window:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.blue : Color.blue.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                            )
                    case .cashWrap:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.98))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Image(systemName: zoneIcon(for: zone.type))
                            .font(.title)
                            .foregroundColor(zone.type == .window ? .blue : textPrimary)
                        Text(zone.name)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(zone.type == .window ? .blue : textPrimary)
                            .multilineTextAlignment(.center)
                        
                        if isSelected {
                            Text("● ACTIVE")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(badgeBg)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(8)
                }
                .frame(width: zone.frame.width, height: zone.frame.height)
                .overlay(
                    Group {
                        if isEditingLayout {
                            Button(action: {
                                viewModel.zones.removeAll(where: { $0.id == zone.id })
                            }) {
                                Image(systemName: "minus.circle.fill").accessibilityLabel("Remove")
                                    .font(.title)
                                    .foregroundColor(.red)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            .offset(x: -8, y: -8)
                        }
                    },
                    alignment: .topLeading
                )
                .position(x: zone.frame.midX, y: zone.frame.midY)
                .gesture(
                    isEditingLayout ? DragGesture()
                        .onChanged { value in
                            if let idx = viewModel.zones.firstIndex(where: { $0.id == zone.id }) {
                                viewModel.zones[idx].xPosition = value.location.x - (zone.frame.width / 2)
                                viewModel.zones[idx].yPosition = value.location.y - (zone.frame.height / 2)
                            }
                        }
                        .onEnded { value in
                            if let idx = viewModel.zones.firstIndex(where: { $0.id == zone.id }) {
                                let finalX = value.location.x - (zone.frame.width / 2)
                                let finalY = value.location.y - (zone.frame.height / 2)
                                viewModel.zones[idx].xPosition = round(finalX / 20) * 20
                                viewModel.zones[idx].yPosition = round(finalY / 20) * 20
                            }
                        }
                    : nil
                )
                .onTapGesture {
                    if isEditingLayout {
                        zoneToRename = zone
                        newName = zone.name
                        showRenameAlert = true
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectZone(zone)
                            isShowingEdit = true
                        }
                    }
                }
            }
            
            if isEditingLayout {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Menu {
                            Button("Wall Unit") { addZone(type: .wall) }
                            Button("Table") { addZone(type: .table) }
                            Button("Window Display") { addZone(type: .window) }
                            Button("Cash Wrap") { addZone(type: .cashWrap) }
                        } label: {
                            Image(systemName: "plus").accessibilityLabel("Add")
                                .font(.title.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                        }
                        .padding(32)
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 20)
        .alert("Rename Zone", isPresented: $showRenameAlert) {
            TextField("Zone Name", text: $newName)
            Button("Cancel", role: .cancel) {
                zoneToRename = nil
            }
            Button("Save") {
                if let zone = zoneToRename,
                   let idx = viewModel.zones.firstIndex(where: { $0.id == zone.id }) {
                    viewModel.zones[idx].name = newName
                }
                zoneToRename = nil
            }
        }
        .alert("Error Saving Layout", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred.")
        }
    }
    
    // MARK: - Helpers
    private func zoneIcon(for type: ZoneType) -> String {
        switch type {
        case .table: return "table.furniture"
        case .wall: return "cabinet"
        case .window: return "rectangle.split.3x1"
        case .cashWrap: return "creditcard.and.123"
        }
    }
    
    private func addZone(type: ZoneType) {
        let newId = UUID()
        let name: String
        let width: Double
        let height: Double
        let capacity: Int
        
        switch type {
        case .table:
            name = "New Table"
            width = 160; height = 100; capacity = 20
        case .wall:
            name = "New Wall Unit"
            width = 60; height = 180; capacity = 40
        case .window:
            name = "New Window"
            width = 240; height = 80; capacity = 10
        case .cashWrap:
            name = "Cash Wrap"
            width = 200; height = 80; capacity = 0
        }
        
        let newZone = MerchandisingZone(
            id: newId,
            storeId: appVM.currentStoreId ?? UUID(),
            name: name,
            type: type,
            xPosition: 400,
            yPosition: 400,
            width: width,
            height: height,
            totalCapacity: capacity
        )
        
        viewModel.zones.append(newZone)
        zoneToRename = newZone
        newName = newZone.name
        showRenameAlert = true
    }
}
