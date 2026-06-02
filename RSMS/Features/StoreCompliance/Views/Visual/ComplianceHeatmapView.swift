//
//  ComplianceHeatmapView.swift
//  RSMS
//

import SwiftUI

struct ComplianceHeatmapView: View {
    @Bindable var complianceVM: ComplianceViewModel
    @State private var planogramVM = PlanogramViewModel()
    @Environment(AppViewModel.self) private var appVM
    
    let onSelectZone: (MerchandisingZone, ComplianceCheck?) -> Void
    
    var body: some View {
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
            
            if planogramVM.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
            
            // Zones Overlay
            ForEach(planogramVM.zones) { zone in
                let latestCheck = getLatestCheck(for: zone)
                let statusColor = color(for: latestCheck?.status)
                
                ZStack {
                    // Base shape based on type
                    switch zone.type {
                    case .table:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.98))
                            .shadow(color: statusColor.opacity(0.3), radius: 10, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(statusColor, lineWidth: 3)
                            )
                    case .wall:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(statusColor, lineWidth: 3)
                            )
                    case .window:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(statusColor, lineWidth: 3)
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Image(systemName: zoneIcon(for: zone.type))
                            .font(.system(size: 24))
                            .foregroundColor(RSMSTheme.textPrimary)
                        Text(zone.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        if let check = latestCheck {
                            HStack(spacing: 4) {
                                Circle().fill(statusColor).frame(width: 8, height: 8)
                                Text(check.status.displayName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(statusColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                        } else {
                            Text("Unchecked")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(8)
                }
                .frame(width: zone.frame.width, height: zone.frame.height)
                .position(x: zone.frame.midX, y: zone.frame.midY)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onSelectZone(zone, latestCheck)
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 20)
        .task {
            await planogramVM.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId ?? UUID())
        }
    }
    
    // MARK: - Helpers
    
    private func getLatestCheck(for zone: MerchandisingZone) -> ComplianceCheck? {
        // Find the corresponding planogram for this zone.
        // Actually, in the current DB, compliance_checks point to a Planogram ID.
        // Wait, earlier I found out planograms actually match the merchandising zones 1:1 in the user's DB.
        // The compliance check is tied to planogramId. The zone.id is technically the shelf_zone_id.
        // The Planogram name is typically matching the zone name.
        let matchingPlanogram = complianceVM.availablePlanograms.first(where: { $0.name == zone.name })
        
        guard let pId = matchingPlanogram?.id else { return nil }
        
        return complianceVM.complianceChecks
            .filter { $0.planogramId == pId }
            .sorted { $0.checkedAt > $1.checkedAt }
            .first
    }
    
    private func color(for status: ComplianceStatus?) -> Color {
        guard let status = status else { return .gray }
        return status.color
    }
    
    private func zoneIcon(for type: ZoneType) -> String {
        switch type {
        case .table: return "table.furniture"
        case .wall: return "cabinet"
        case .window: return "rectangle.split.3x1"
        }
    }
}
