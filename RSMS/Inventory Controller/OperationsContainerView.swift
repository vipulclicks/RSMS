//
//  OperationsContainerView.swift
//  RSMS
//
//  Segmented container for operational sub-screens.
//  Segments: Loaner Management | Service Center
//

import SwiftUI

struct OperationsContainerView: View {

    @State private var selectedSegment = 0

    private let segments = ["Loaner Mgmt", "Service Center"]

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Segmented Control

            Picker("Operations", selection: $selectedSegment) {
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
                    LoanerProductManagementView()
                default:
                    ServiceCenterTrackingView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: selectedSegment)
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Operations")
        .navigationBarTitleDisplayMode(.large)
    }
}
