//
//  ZoneReferenceView.swift
//  RSMS
//

import SwiftUI

struct ZoneReferenceView: View {
    @Bindable var viewModel: ComplianceViewModel
    let zone: MerchandisingZone
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: zoneIcon)
                                .font(.system(size: 32))
                                .foregroundColor(RSMSTheme.primary)
                            Text(zone.name)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(RSMSTheme.textPrimary)
                        }
                        
                        Text("Area Type: \(zone.type.rawValue.capitalized)")
                            .font(.title3)
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                    Spacer()
                }
                
                Divider()
                
                // Products / Visuals List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Expected Products")
                        .font(.title2.bold())
                        .foregroundColor(RSMSTheme.textPrimary)
                    
                    if zone.items.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "cube.box")
                                .font(.system(size: 48))
                                .foregroundColor(RSMSTheme.textTertiary)
                            Text("No specific products mapped to this zone.")
                                .font(.headline)
                                .foregroundColor(RSMSTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 64)
                        .background(RSMSTheme.surfaceSecondary)
                        .cornerRadius(16)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 24)], spacing: 24) {
                            ForEach(zone.items) { item in
                                HStack(alignment: .top, spacing: 16) {
                                    if item.imageName.hasPrefix("http"), let url = URL(string: item.imageName) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image.resizable().aspectRatio(contentMode: .fit)
                                            } else {
                                                Color.gray.opacity(0.2)
                                            }
                                        }
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                    } else {
                                        Image(item.imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.headline)
                                            .foregroundColor(RSMSTheme.textPrimary)
                                            .lineLimit(2)
                                        Text("SKU: \(item.sku)")
                                            .font(.subheadline)
                                            .foregroundColor(RSMSTheme.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .frame(height: 112, alignment: .top)
                                .background(RSMSTheme.surfacePrimary)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                // Proceed Button
                NavigationLink(value: ComplianceRoute.inspectionForm(zone)) {
                    Text("Proceed to Check")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RSMSTheme.primaryDark)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
            .padding(40)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Zone Reference")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var zoneIcon: String {
        switch zone.type {
        case .table: return "table.furniture"
        case .wall: return "cabinet"
        case .window: return "rectangle.split.3x1"
        }
    }
}
