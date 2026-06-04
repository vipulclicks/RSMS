import SwiftUI

struct AppointmentsInventoryView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var dashboardVM = BoutiqueDashboardViewModel()
    @State private var hasAppeared = false

    var body: some View {
        Group {
            if dashboardVM.isLoading {
                ProgressView("Loading Inventory...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = dashboardVM.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        inventorySection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.1), value: hasAppeared)
                    }
                    .padding(32)
                }
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .navigationTitle("Inventory")
        .task {
            if let storeId = appVM.currentStoreId {
                await dashboardVM.load(dataStore: appVM.dataStore, storeId: storeId)
                withAnimation(reduceMotion ? nil : .default) {
                    hasAppeared = true
                }
            }
        }
    }

    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventory Operations")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Receive inbound stock and monitor low inventory.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()

                if !dashboardVM.lowStockAlerts.isEmpty {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(RSMSTheme.danger)
                            .frame(width: 8, height: 8)
                        Text("\(dashboardVM.lowStockAlerts.count) Critical")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RSMSTheme.danger)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(RSMSTheme.danger.opacity(RSMSTheme.bgOpacity(for: contrast, base: 0.1))))
                }
            }

            receivingEntryCard

            if dashboardVM.lowStockAlerts.isEmpty {
                emptyInventoryState
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)],
                    spacing: 20
                ) {
                    ForEach(dashboardVM.lowStockAlerts) { alert in
                        inventoryCard(for: alert)
                    }
                }
            }
        }
    }

    private var receivingEntryCard: some View {
        NavigationLink {
            InventoryReceivingView()
        } label: {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(RSMSTheme.primary.opacity(RSMSTheme.bgOpacity(for: contrast, base: 0.12)))
                        .frame(width: 68, height: 68)
                    Image(systemName: "barcode.viewfinder")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(RSMSTheme.primary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Inventory Receiving & Put-Away")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text("Scan inbound stock, assign storage locations, and post updated quantities.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(RSMSTheme.primary)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(RSMSTheme.surfacePrimary)
                    .shadow(color: Color.black.opacity(RSMSTheme.bgOpacity(for: contrast, base: 0.04)), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Inventory Receiving & Put-Away")
            .accessibilityHint("Scan inbound stock, assign storage locations, and post updated quantities.")
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var emptyInventoryState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [RSMSTheme.success.opacity(RSMSTheme.bgOpacity(for: contrast, base: 0.1)), RSMSTheme.success.opacity(RSMSTheme.bgOpacity(for: contrast, base: 0.05))],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.shield.fill")
                    .font(.title)
                    .foregroundStyle(RSMSTheme.success)
            }
            Text("Inventory Healthy")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            Text("All products are currently well-stocked.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(RSMSTheme.surfacePrimary.opacity(0.5))
                .stroke(RSMSTheme.border.opacity(0.5), lineWidth: 1)
        )
    }

    private func inventoryCard(for alert: LowStockAlert) -> some View {
        let isCritical = alert.stockItem.quantity == 0
        let accentColor = isCritical ? RSMSTheme.danger : RSMSTheme.warning

        return Button {
            // Reserved for future inventory actions.
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.surfaceTertiary)
                            .frame(width: 48, height: 48)

                        Image(systemName: alert.product.category.lowercased() == "watches" ? "applewatch" : "sparkles")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(alert.stockItem.quantity) left")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(accentColor)
                        Text("Low Stock")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accentColor.opacity(0.8))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.product.name)
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text("SKU:")
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text(alert.product.sku)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                    .font(.caption)
                }

                Spacer()

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(RSMSTheme.surfaceTertiary)
                            .frame(height: 6)
                        Capsule()
                            .fill(accentColor)
                            .frame(
                                width: geo.size.width * CGFloat(max(0.1, Double(alert.stockItem.quantity) / 10.0)),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(RSMSTheme.surfacePrimary)
                    .shadow(color: Color.black.opacity(RSMSTheme.bgOpacity(for: contrast, base: 0.04)), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Low stock alert for \(alert.product.name), SKU \(alert.product.sku).")
            .accessibilityValue("Quantity: \(alert.stockItem.quantity)")
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
