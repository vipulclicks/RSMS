//
//  MovementsContainerView.swift
//  RSMS
//
//  Segmented container for all inventory movement sub-screens.
//  Segments: Store Transfers | Vendor Returns | Returns & Exchanges
//

import SwiftUI

struct MovementsContainerView: View {

    @State private var selectedSegment = 0

    private let segments = ["Transfers", "Vendor Returns", "Returns & Exch."]

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Segmented Control

            Picker("Movements", selection: $selectedSegment) {
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
                    InventoryTransferView()
                case 1:
                    VendorReturnView()
                default:
                    InspectionQueueView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: selectedSegment)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Movements")
        .navigationBarTitleDisplayMode(.large)
    }
}
