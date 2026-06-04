import SwiftUI

struct AssignCommissionView: View {
    let staffId: UUID
    let staffName: String
    var viewModel: StaffManagementViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    @State private var amount: Double? = nil
    @State private var rate: Double = 5.0
    @State private var status: CommissionStatus = .pending
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var todaysSales: Double? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(Capsule())
                    .disabled(isSubmitting)
                
                Spacer()
                
                Text("Assign Commission")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Spacer()
                
                // Invisible placeholder for balance
                Button("Cancel") {}.opacity(0)
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Form Card
                    VStack(alignment: .leading, spacing: 24) {
                        Label("DAILY PERFORMANCE", systemImage: "chart.bar.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .tracking(1)
                            
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(staffName)
                                    .font(.headline)
                                    .foregroundStyle(RSMSTheme.textPrimary)
                                Text("Today's Total Sales")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            Spacer()
                            if let todaysSales {
                                Text(todaysSales.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(RSMSTheme.gold)
                            } else {
                                ProgressView().tint(RSMSTheme.primaryDark)
                            }
                        }
                        .padding(16)
                        .background(RSMSTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Divider().overlay(RSMSTheme.border)
                        
                        Label("COMMISSION DETAILS", systemImage: "banknote.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .tracking(1)
                            
                        // Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount (₹) *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            TextField("0.00", value: $amount, format: .number)
                                .keyboardType(.decimalPad)
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Rate
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Rate")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                Spacer()
                                Text("\(Int(rate))%")
                                    .foregroundStyle(RSMSTheme.gold)
                                    .fontWeight(.bold)
                            }
                            Slider(value: $rate, in: 1...20, step: 1)
                                .tint(RSMSTheme.gold)
                        }
                        
                        // Status
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                            Menu {
                                ForEach(CommissionStatus.allCases, id: \.self) { s in
                                    Button(s.rawValue.capitalized) { status = s }
                                }
                            } label: {
                                HStack {
                                    Text(status.rawValue.capitalized)
                                        .foregroundStyle(RSMSTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(RSMSTheme.textTertiary)
                                }
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(RSMSTheme.danger)
                                .font(.callout)
                                .padding(.top, 8)
                        }
                    }
                    .padding(24)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    
                    // Save Button
                    Button {
                        Task { await saveCommission() }
                    } label: {
                        HStack {
                            Text(isSubmitting ? "Assigning..." : "Assign Commission")
                            if isSubmitting {
                                ProgressView().tint(.white).padding(.leading, 4)
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            (isSubmitting || amount == nil || amount! <= 0) ? 
                            AnyShapeStyle(RSMSTheme.textTertiary) : 
                            AnyShapeStyle(RSMSTheme.primaryGradient)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: (isSubmitting || amount == nil || amount! <= 0) ? .clear : RSMSTheme.primaryDark.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isSubmitting || amount == nil || amount! <= 0)
                }
                .padding(24)
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .task {
            await loadTodaysSales()
        }
    }
    
    @MainActor
    private func loadTodaysSales() async {
        do {
            if let storeId = appVM.currentStoreId {
                try await appVM.dataStore.fetchTransactions(storeId: storeId)
                let transactions = appVM.dataStore.transactions.filter {
                    $0.status == .completed &&
                    $0.associateId == staffId &&
                    Calendar.current.isDateInToday($0.createdAt)
                }
                todaysSales = transactions.reduce(0.0) { $0 + $1.totalAmount }
            }
        } catch {
            print("Failed to load today's sales: \(error)")
            todaysSales = 0
        }
    }
    
    @MainActor
    private func saveCommission() async {
        guard let amount = amount, amount > 0 else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            // Fetch latest transaction for this user to attach to
            try await appVM.dataStore.fetchTransactions(storeId: appVM.currentStoreId)
            let userTransaction = appVM.dataStore.transactions.first { $0.associateId == staffId }
            
            // Generate a dummy transaction ID if none exist
            let transactionId = userTransaction?.id ?? UUID()
            
            let commission = Commission(
                id: UUID(),
                staffId: staffId,
                transactionId: transactionId,
                amount: amount,
                rate: rate / 100.0,
                status: status,
                createdAt: .now
            )
            
            try await appVM.dataStore.createCommission(commission)
            
            // Reload commissions
            if let storeId = appVM.currentStoreId {
                await viewModel.load(dataStore: appVM.dataStore, storeId: storeId)
            }
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
}
