import SwiftUI

struct AssignLoanerModalView: View {
    @Bindable var viewModel: LoanerProductManagementViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        customerSection
                        loanerProductSection
                        agreementSection
                    }
                    .padding()
                    .padding(.bottom, 80) // Space for sticky footer
                }
                
                VStack {
                    Spacer()
                    stickyFooter
                }
            }
            .navigationTitle("Assign Loaner Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var customerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CUSTOMER DETAILS")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.textTertiary)
            
            VStack(spacing: 0) {
                formField(title: "Customer Name", placeholder: "e.g. John Doe", text: $viewModel.newCustomerName)
                Divider().background(RSMSTheme.divider).padding(.leading, 16)
                formField(title: "Contact Number", placeholder: "+1 (555) 000-0000", text: $viewModel.newCustomerContact)
                Divider().background(RSMSTheme.divider).padding(.leading, 16)
                formField(title: "Email (Optional)", placeholder: "john@example.com", text: $viewModel.newCustomerEmail)
                Divider().background(RSMSTheme.divider).padding(.leading, 16)
                formField(title: "Repair Request ID", placeholder: "SRX-1234", text: $viewModel.newRepairRequestId)
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(RSMSTheme.divider, lineWidth: 1)
            )
        }
    }
    
    private var loanerProductSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LOANER PRODUCT")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.textTertiary)
            
            VStack(spacing: 0) {
                // Product Search
                HStack(spacing: 12) {
                    Text("Search Inventory")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .frame(width: 120, alignment: .leading)
                    
                    TextField("SKU or Name", text: $viewModel.newLoanerProductSearch)
                        .font(.subheadline)
                    
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                if !viewModel.searchResults.isEmpty && viewModel.selectedProduct == nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.searchResults) { product in
                                Button {
                                    viewModel.selectedProduct = product
                                    viewModel.newLoanerProductSearch = product.name
                                    viewModel.newSku = product.sku
                                    viewModel.newCategory = product.category
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name)
                                            .font(.caption.bold())
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Text(product.sku)
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    .padding(12)
                                    .background(RSMSTheme.surfaceSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                
                Divider().background(RSMSTheme.divider).padding(.leading, 16)
                
                if let product = viewModel.selectedProduct {
                    HStack {
                        Text("Selected")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .frame(width: 120, alignment: .leading)
                        
                        Text(product.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(RSMSTheme.primary)
                        
                        Spacer()
                        
                        Button {
                            viewModel.selectedProduct = nil
                            viewModel.newLoanerProductSearch = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        .accessibilityLabel("Clear Selected Product")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    
                    Divider().background(RSMSTheme.divider).padding(.leading, 16)
                }
                
                formField(title: "Serial Number", placeholder: "Scan or enter SN", text: $viewModel.newSerialNumber)
                
                Divider().background(RSMSTheme.divider).padding(.leading, 16)
                
                // Condition Picker
                HStack {
                    Text("Condition")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .frame(width: 120, alignment: .leading)
                    
                    Picker("Condition", selection: $viewModel.newCondition) {
                        ForEach(LoanerCondition.allCases) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(RSMSTheme.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                

            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(RSMSTheme.divider, lineWidth: 1)
            )
        }
    }
    
    private var agreementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TERMS & LOGISTICS")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(RSMSTheme.textTertiary)
            
            VStack(spacing: 0) {
                // Deposit
                HStack(spacing: 12) {
                    Text("Deposit Held (₹)")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .frame(width: 120, alignment: .leading)
                    
                    TextField("0.00", text: $viewModel.newSecurityDeposit)
                        .keyboardType(.decimalPad)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                Divider().background(RSMSTheme.divider).padding(.leading, 16)
                
                // Return Date
                DatePicker("Expected Return", selection: $viewModel.newExpectedReturnDate, displayedComponents: .date)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .tint(RSMSTheme.primary)
                
                Divider().background(RSMSTheme.divider).padding(.leading, 16)
                
                // Agreement Toggle
                Toggle("Agreement Signed", isOn: $viewModel.newAgreementSigned)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .tint(RSMSTheme.success)
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(RSMSTheme.divider, lineWidth: 1)
            )
            
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Remarks / Notes")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                TextEditor(text: $viewModel.newNotes)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(RSMSTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(RSMSTheme.divider, lineWidth: 1)
                    )
            }
        }
    }
    
    private func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textPrimary)
                .frame(width: 120, alignment: .leading)
            
            TextField(placeholder, text: text)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Sticky Footer
    
    private var stickyFooter: some View {
        VStack {
            Divider().background(RSMSTheme.divider)
            HStack(spacing: 16) {

                Button {
                    if let storeId = appViewModel.currentStoreId {
                        Task {
                            await viewModel.submitNewAssignment(dataStore: appViewModel.dataStore, storeId: storeId)
                        }
                    }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Assign Loaner")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(RSMSTheme.primary)
                .clipShape(Capsule())
                .shadow(color: RSMSTheme.primary.opacity(0.3), radius: 8, y: 4)
                .disabled(viewModel.newCustomerName.isEmpty || viewModel.newCustomerContact.isEmpty || viewModel.isSubmitting)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
}
