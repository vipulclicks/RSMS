//
//  StoreLayoutOverviewView.swift
//  RSMS
//

import SwiftUI

struct StoreLayoutOverviewView: View {
    @State private var viewModel = PlanogramViewModel()
    @State private var isShowingEdit = false
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
                        Text("Select a merchandising zone to view capacity and stock health.")
                            .font(.system(size: 15))
                            .foregroundColor(textSecondary)
                    }
                    Spacer()
                    

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
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectZone(zone)
                        isShowingEdit = true
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
        }
    }
}
