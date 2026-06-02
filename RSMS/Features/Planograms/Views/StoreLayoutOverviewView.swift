//
//  StoreLayoutOverviewView.swift
//  RSMS
//

import SwiftUI

struct StoreLayoutOverviewView: View {
    @State private var viewModel = PlanogramViewModel()
    @State private var isShowingEdit = false
    @State private var isEditingLayout = false
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
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(textPrimary)
                        Text(isEditingLayout ? "Drag items to position them, or add new fixtures." : "Select a merchandising zone to view capacity and stock health.")
                            .font(.system(size: 15))
                            .foregroundColor(textSecondary)
                    }
                    Spacer()
                    
                    if isEditingLayout {
                        Button("Cancel") {
                            Task {
                                viewModel.zones.removeAll()
                                await viewModel.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId ?? UUID())
                            }
                            isEditingLayout = false
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.trailing, 16)
                        
                        Button("Save Layout") {
                            Task {
                                try? await viewModel.saveZonesLayout(storeId: appVM.currentStoreId ?? UUID())
                                isEditingLayout = false
                            }
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .clipShape(Capsule())
                    } else {
                        Button("Edit Layout") {
                            isEditingLayout = true
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black)
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
            }
            .background(Color.white)
            .task {
                await viewModel.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId ?? UUID())
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
                            // A thick strip on one side
                            .overlay(
                                Rectangle()
                                    .fill(isSelected ? Color.red : Color.gray.opacity(0.5))
                                    .frame(width: 4),
                                alignment: .top
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
                            .font(.system(size: 24))
                            .foregroundColor(zone.type == .window ? .blue : textPrimary)
                        Text(zone.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(zone.type == .window ? .blue : textPrimary)
                            .multilineTextAlignment(.center)
                        
                        if isSelected {
                            Text("● ACTIVE")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(badgeBg)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(8)
                }
                .frame(width: zone.frame.width, height: zone.frame.height)
                .position(x: zone.frame.midX, y: zone.frame.midY)
                .gesture(
                    isEditingLayout ? DragGesture()
                        .onChanged { value in
                            if let idx = viewModel.zones.firstIndex(where: { $0.id == zone.id }) {
                                viewModel.zones[idx].xPosition = value.location.x
                                viewModel.zones[idx].yPosition = value.location.y
                            }
                        }
                        .onEnded { value in
                            if let idx = viewModel.zones.firstIndex(where: { $0.id == zone.id }) {
                                let snapX = round(value.location.x / 20) * 20
                                let snapY = round(value.location.y / 20) * 20
                                viewModel.zones[idx].xPosition = snapX
                                viewModel.zones[idx].yPosition = snapY
                            }
                        }
                    : nil
                )
                .onTapGesture {
                    if isEditingLayout {
                        viewModel.selectZone(zone)
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectZone(zone)
                            isShowingEdit = true
                        }
                    }
                }
                .overlay(
                    Group {
                        if isEditingLayout && isSelected {
                            Button(action: {
                                viewModel.zones.removeAll(where: { $0.id == zone.id })
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            .offset(x: (zone.width / 2) - 8, y: -(zone.height / 2) + 8)
                        }
                    }
                )
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
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
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
        viewModel.selectZone(newZone)
    }
}
