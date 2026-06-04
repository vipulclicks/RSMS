//
//  AuditsContainerView.swift
//  RSMS
//
//  Segmented container for all audit sub-screens.
//  Segments: Cycle Counts | Reconcile | Audit Trail
//

import SwiftUI

struct AuditsContainerView: View {

    @AppStorage("inventoryAuditSelectedSegment") private var selectedSegment = 0

    private let segments = ["Cycle Counts", "Reconcile", "Audit Trail"]

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Segmented Control

            Picker("Audits", selection: $selectedSegment) {
                ForEach(segments.indices, id: \.self) { index in
                    Text(segments[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(RSMSTheme.background)

            Divider()
                .foregroundStyle(RSMSTheme.divider)

            // MARK: - Content

            Group {
                switch selectedSegment {
                case 0:
                    CycleCountView()
                case 1:
                    StockReconciliationView()
                default:
                    AuditTrailView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: selectedSegment)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Audits & Counts")
        .navigationBarTitleDisplayMode(.large)
    }
}
