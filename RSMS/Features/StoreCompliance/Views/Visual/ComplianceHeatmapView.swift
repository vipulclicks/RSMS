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
                let isChecked = latestCheck != nil
                
                ZStack {
                    // Base shape based on type
                    switch zone.type {
                    case .table:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.surfaceSecondary)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(RSMSTheme.border, lineWidth: 1)
                            )
                    case .wall:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(RSMSTheme.surfaceSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(RSMSTheme.border, lineWidth: 1)
                            )
                    case .window:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    case .cashWrap:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.surfaceSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(RSMSTheme.border, lineWidth: 1)
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Image(systemName: zoneIcon(for: zone.type))
                            .font(.title)
                            .foregroundColor(RSMSTheme.textPrimary)
                        Text(zone.name)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(RSMSTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        if isChecked {
                            HStack(spacing: 4) {
                                Circle().fill(RSMSTheme.success).frame(width: 8, height: 8)
                                Text("Checked")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(RSMSTheme.success)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RSMSTheme.surfacePrimary.opacity(0.9))
                            .clipShape(Capsule())
                        } else {
                            Text("Unchecked")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RSMSTheme.surfacePrimary.opacity(0.9))
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
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 20)
        .task {
            await planogramVM.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId ?? UUID())
        }
    }
    
    // MARK: - Helpers
    
    private func getLatestCheck(for zone: MerchandisingZone) -> ComplianceCheck? {
        let zoneTag = "[Zone: \(zone.name)]"
        
        return complianceVM.complianceChecks
            .filter { check in
                guard let notes = check.notes else { return false }
                return notes.contains(zoneTag)
            }
            .sorted { a, b in
                // If they were created at the exact same time (like in our split report logic),
                // prioritize showing the more severe status on the heatmap.
                if abs(a.checkedAt.timeIntervalSince(b.checkedAt)) < 1.0 {
                    if a.status == .nonCompliant { return true }
                    if b.status == .nonCompliant { return false }
                    if a.status == .needsReview { return true }
                    if b.status == .needsReview { return false }
                    return true
                }
                return a.checkedAt > b.checkedAt
            }
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
        case .cashWrap: return "creditcard.and.123"
        }
    }
}
