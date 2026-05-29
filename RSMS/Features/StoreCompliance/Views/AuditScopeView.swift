//
//  AuditScopeView.swift
//  RSMS
//

import SwiftUI

struct AuditScopeView: View {
    let template: AuditTemplate
    
    @Environment(AppViewModel.self) private var appViewModel
    @State private var storeZones: [MerchandisingZone] = []
    @State private var selectedZoneIds: Set<UUID> = []
    @State private var isLoading = false
    
    @State private var startAudit = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading Store Layout...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Select the areas you wish to audit for the **\(template.name)**.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                List {
                    ForEach(storeZones) { zone in
                        Button(action: {
                            if selectedZoneIds.contains(zone.id) {
                                selectedZoneIds.remove(zone.id)
                            } else {
                                selectedZoneIds.insert(zone.id)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(zone.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(zone.type.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedZoneIds.contains(zone.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(RSMSTheme.primary)
                                        .font(.title2)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                VStack {
                    Divider()
                    Button(action: {
                        startAudit = true
                    }) {
                        Text("Begin Inspection (\(selectedZoneIds.count) Areas)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedZoneIds.isEmpty ? Color.gray.opacity(0.3) : RSMSTheme.primary)
                            .foregroundColor(selectedZoneIds.isEmpty ? .gray : .white)
                            .cornerRadius(12)
                    }
                    .disabled(selectedZoneIds.isEmpty)
                    .padding()
                }
                .background(Color.white)
            }
        }
        .navigationTitle("Audit Scope")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let storeId = appViewModel.currentStoreId {
                Task {
                    isLoading = true
                    do {
                        // Reusing existing PlanogramService for zones
                        storeZones = try await PlanogramService.shared.fetchZones(for: storeId)
                    } catch {
                        print("Error fetching zones: \(error)")
                    }
                    isLoading = false
                }
            }
        }
        .navigationDestination(isPresented: $startAudit) {
            ComplianceInspectionSplitView(
                template: template,
                targetZones: Array(selectedZoneIds)
            )
        }
    }
}
