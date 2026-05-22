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
        NavigationStack {
            Form {
                Section("Daily Performance") {
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
                            ProgressView()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Commission Details") {
                    HStack {
                        Text("Amount (₹)")
                        Spacer()
                        TextField("0.00", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Rate")
                            Spacer()
                            Text("\(Int(rate))%")
                                .foregroundStyle(RSMSTheme.gold)
                                .fontWeight(.medium)
                        }
                        Slider(value: $rate, in: 1...20, step: 1)
                            .tint(RSMSTheme.gold)
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(CommissionStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(RSMSTheme.danger)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Assign Commission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        Task { await saveCommission() }
                    }
                    .disabled(isSubmitting || amount == nil || amount! <= 0)
                }
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .padding()
                            .background(RSMSTheme.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .task {
                await loadTodaysSales()
            }
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
