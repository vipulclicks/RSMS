import SwiftUI

struct VisualMerchandisingView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("Visual Merchandising", selection: $selectedTab) {
                Text("Layout & Planning").tag(0)
                Text("Issue Board").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(RSMSTheme.background)
            
            // Content
            if selectedTab == 0 {
                StoreLayoutOverviewView()
            } else {
                ComplianceDashboardView()
            }
        }
    }
}
