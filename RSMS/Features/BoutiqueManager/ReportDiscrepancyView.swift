//
//  ReportDiscrepancyView.swift
//  RSMS
//
//  Boutique Manager stock discrepancy reporting sheet.
//  Two-tab layout: New Report (form) and Report History.
//

import SwiftUI

struct ReportDiscrepancyView: View {
    @Bindable var viewModel: DiscrepancyReportViewModel
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showProductPicker = false
    @State private var showSuccessBanner = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Picker
                Picker("", selection: $selectedTab) {
                    Text("New Report").tag(0)
                    Text("History").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Content
                if selectedTab == 0 {
                    newReportTab
                } else {
                    historyTab
                }
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mismatch")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay(alignment: .top) {
                if showSuccessBanner {
                    successBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onChange(of: viewModel.didSubmitSuccessfully) { _, success in
                if success {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4)) {
                        showSuccessBanner = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.4)) {
                            showSuccessBanner = false
                            viewModel.didSubmitSuccessfully = false
                        }
                    }
                }
            }
            .task {
                await viewModel.load(dataStore: appVM.dataStore, storeId: appVM.currentStoreId)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - New Report Tab
    // ═══════════════════════════════════════════════════════════

    private var newReportTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Step 1: Product Search
                formCard {
                    VStack(alignment: .leading, spacing: 14) {
                        stepHeader(step: 1, title: "Select Product", icon: "magnifyingglass")

                        // Search field
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textTertiary)
                            TextField("Search by name, SKU, or category…", text: $viewModel.searchText)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .autocorrectionDisabled()
                                .onChange(of: viewModel.searchText) { _, newValue in
                                    if viewModel.selectedProduct != nil &&
                                       newValue != viewModel.selectedProduct?.name {
                                        viewModel.selectedProduct = nil
                                        viewModel.expectedQty = ""
                                        viewModel.actualQty = ""
                                    }
                                    showProductPicker = !newValue.isEmpty && viewModel.selectedProduct == nil
                                }

                            if !viewModel.searchText.isEmpty {
                                Button {
                                    viewModel.resetForm()
                                    showProductPicker = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.headline)
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                            }
                        }
                        .padding(12)
                        .background(RSMSTheme.surfaceTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Dropdown results
                        if showProductPicker && !viewModel.filteredProducts.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(Array(viewModel.filteredProducts.prefix(5).enumerated()), id: \.element.id) { index, product in
                                    Button {
                                        viewModel.selectProduct(product, dataStore: appVM.dataStore)
                                        showProductPicker = false
                                    } label: {
                                        productRow(product)
                                    }
                                    .buttonStyle(.plain)

                                    if index < min(viewModel.filteredProducts.count, 5) - 1 {
                                        Divider().padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(RSMSTheme.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(RSMSTheme.border, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                        }

                        // Selected product chip
                        if let product = viewModel.selectedProduct {
                            selectedProductCard(product)
                        }
                    }
                }

                // Step 2: Quantity (only after product selected)
                if viewModel.selectedProduct != nil {
                    formCard {
                        VStack(alignment: .leading, spacing: 14) {
                            stepHeader(step: 2, title: "Enter Quantities", icon: "number")

                            VStack(spacing: 0) {
                                quantityRow(
                                    label: "System Qty",
                                    sublabel: "Expected",
                                    text: $viewModel.expectedQty,
                                    color: RSMSTheme.textPrimary
                                )

                                Divider().padding(.horizontal, 16)

                                quantityRow(
                                    label: "Actual Count",
                                    sublabel: "Physical",
                                    text: $viewModel.actualQty,
                                    color: RSMSTheme.primary
                                )
                            }
                            .background(RSMSTheme.surfaceTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Variance preview inline
                            if let variance = viewModel.computedVariance {
                                variancePreview(variance)
                            }
                        }
                    }
                }

                // Step 3: Issue Type & Notes (only after product selected)
                if viewModel.selectedProduct != nil {
                    formCard {
                        VStack(alignment: .leading, spacing: 14) {
                            stepHeader(step: 3, title: "Classify Issue", icon: "tag.fill")

                            // Issue type chips
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 10) {
                                ForEach(DiscrepancyReportViewModel.IssueType.allCases) { type in
                                    Button {
                                        withAnimation(reduceMotion ? nil : .spring(response: 0.25)) {
                                            viewModel.issueType = type
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: type.icon)
                                                .font(.subheadline)
                                            Text(type.rawValue)
                                                .font(.caption.weight(.semibold))
                                        }
                                        .foregroundStyle(viewModel.issueType == type ? .white : type.color)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            viewModel.issueType == type
                                                ? AnyShapeStyle(type.color)
                                                : AnyShapeStyle(type.color.opacity(0.08))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    viewModel.issueType == type ? type.color : type.color.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // Notes
                            TextField("Additional notes (optional)…", text: $viewModel.notes, axis: .vertical)
                                .lineLimit(2...4)
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.textPrimary)
                                .padding(12)
                                .background(RSMSTheme.surfaceTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                // Submit
                if viewModel.selectedProduct != nil {
                    submitButton
                }
            }
            .padding(20)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.selectedProduct != nil)
        }
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - History Tab
    // ═══════════════════════════════════════════════════════════

    private var historyTab: some View {
        ScrollView {
            if viewModel.submittedReports.isEmpty {
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(RSMSTheme.textTertiary.opacity(0.5))
                    Text("No Reports Yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    Text("Discrepancy reports you submit will appear here for tracking and audit.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    // Summary row
                    HStack(spacing: 16) {
                        historyStat(
                            value: "\(viewModel.submittedReports.filter { $0.status == .open }.count)",
                            label: "Open",
                            color: RSMSTheme.warning
                        )
                        historyStat(
                            value: "\(viewModel.submittedReports.filter { $0.status == .investigating }.count)",
                            label: "Investigating",
                            color: RSMSTheme.primary
                        )
                        historyStat(
                            value: "\(viewModel.submittedReports.filter { $0.status == .resolved || $0.status == .writeOff }.count)",
                            label: "Closed",
                            color: RSMSTheme.success
                        )
                    }
                    .padding(.bottom, 4)

                    ForEach(viewModel.submittedReports) { report in
                        reportCard(report)
                    }
                }
                .padding(20)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - Reusable Components
    // ═══════════════════════════════════════════════════════════

    // MARK: Form Card Container
    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 12, y: 4)
    }

    // MARK: Step Header
    private func stepHeader(step: Int, title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("\(step)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RSMSTheme.gold)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Spacer()
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
    }

    // MARK: Quantity Row
    private func quantityRow(label: String, sublabel: String, text: Binding<String>, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(sublabel)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 80)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Product Row
    private func productRow(_ product: Product) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "shippingbox.fill")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(product.sku)
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.gold)
                    Text("·")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text(product.category)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(product.name), SKU \(product.sku).")
        .accessibilityValue("Category: \(product.category)")
    }

    // MARK: Selected Product Card
    private func selectedProductCard(_ product: Product) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.success.opacity(0.1))
                    .frame(width: 42, height: 42)
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(RSMSTheme.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                Text(product.sku)
                    .font(.caption.monospaced())
                    .foregroundStyle(RSMSTheme.gold)
            }

            Spacer()

            Button {
                viewModel.resetForm()
                showProductPicker = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            .accessibilityLabel("Remove Selected Product")
        }
        .padding(12)
        .background(RSMSTheme.success.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.success.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: Variance Preview
    private func variancePreview(_ variance: Int) -> some View {
        let isExcess = variance > 0
        let color = isExcess ? RSMSTheme.warning : RSMSTheme.danger
        let label = isExcess ? "Excess of \(abs(variance))" : "Shortage of \(abs(variance))"
        let icon = isExcess ? "arrow.up.circle.fill" : "arrow.down.circle.fill"

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Spacer()
            Text("Will be logged")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Submit Button
    private var submitButton: some View {
        VStack(spacing: 8) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.danger)
                    .multilineTextAlignment(.center)
            }

            Button {
                guard let user = appVM.currentUser else { return }
                Task {
                    await viewModel.submitReport(dataStore: appVM.dataStore, user: user)
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(RSMSTheme.background)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Submit Report")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(RSMSTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.canSubmit
                        ? AnyShapeStyle(RSMSTheme.primaryGradient)
                        : AnyShapeStyle(RSMSTheme.textTertiary.opacity(0.3))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!viewModel.canSubmit)
        }
    }

    // MARK: Success Banner
    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white)
            Text("Report submitted successfully!")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(RSMSTheme.success)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: RSMSTheme.success.opacity(0.3), radius: 12, y: 6)
        .padding(.top, 8)
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - History Components
    // ═══════════════════════════════════════════════════════════

    private func historyStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func reportCard(_ report: InventoryVariance) -> some View {
        HStack(spacing: 14) {
            // Status icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor(report.status).opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon(report.status))
                    .font(.headline)
                    .foregroundStyle(statusColor(report.status))
            }

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.productName(for: report.productId))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(viewModel.productSKU(for: report.productId))
                        .font(.caption.monospaced())
                        .foregroundStyle(RSMSTheme.gold)
                    Text("·")
                        .foregroundStyle(RSMSTheme.textTertiary)
                    Text("Variance: \(report.variance > 0 ? "+" : "")\(report.variance)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(report.variance > 0 ? RSMSTheme.warning : RSMSTheme.danger)
                }
            }

            Spacer()

            // Status + Date
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge(report.status)
                Text(viewModel.formattedDate(report.reportedAt))
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding(14)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.productName(for: report.productId)), SKU \(viewModel.productSKU(for: report.productId)).")
        .accessibilityValue("Variance: \(report.variance > 0 ? "+" : "")\(report.variance). Status: \(report.status.rawValue). \(viewModel.formattedDate(report.reportedAt))")
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - Helpers
    // ═══════════════════════════════════════════════════════════

    private func statusColor(_ status: VarianceStatus) -> Color {
        switch status {
        case .open:          return RSMSTheme.warning
        case .investigating: return RSMSTheme.primary
        case .resolved:      return RSMSTheme.success
        case .writeOff:      return RSMSTheme.textSecondary
        }
    }

    private func statusIcon(_ status: VarianceStatus) -> String {
        switch status {
        case .open:          return "clock.fill"
        case .investigating: return "magnifyingglass"
        case .resolved:      return "checkmark.circle.fill"
        case .writeOff:      return "trash.fill"
        }
    }

    private func statusBadge(_ status: VarianceStatus) -> some View {
        Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.1))
            .clipShape(Capsule())
    }
}

#Preview {
    ReportDiscrepancyView(viewModel: DiscrepancyReportViewModel())
        .environment(AppViewModel())
}
