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
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let segments = ["Transfers", "Sourcing", "Vendor Returns", "Returns & Exchanges"]

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Segmented Control

            if sizeClass == .compact {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(segments.indices, id: \.self) { index in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedSegment = index
                                }
                            } label: {
                                Text(segments[index])
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(selectedSegment == index ? RSMSTheme.background : RSMSTheme.textSecondary)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedSegment == index
                                            ? RSMSTheme.gold
                                            : RSMSTheme.surfacePrimary
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedSegment == index ? Color.clear : RSMSTheme.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(RSMSTheme.background)
            } else {
                Picker("Movements", selection: $selectedSegment) {
                    ForEach(segments.indices, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(RSMSTheme.background)
            }

            Divider()
                .foregroundStyle(RSMSTheme.divider)

            // MARK: - Content

            Group {
                switch selectedSegment {
                case 0:
                    InventoryTransferView()
                case 1:
                    InventorySourcingRequestListView()
                case 2:
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
