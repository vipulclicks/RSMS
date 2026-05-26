import SwiftUI

struct AssignGoalFormView: View {
    @Bindable var viewModel: SalesGoalViewModel
    @Binding var navPath: [SalesGoalRoute]
    @Environment(AppViewModel.self) private var appViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // MARK: - Step 1: Select Staff
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "1. Assign To")
                    
                    Button {
                        navPath.append(.staffPicker)
                    } label: {
                        HStack {
                            if let staff = viewModel.draftSelectedStaff {
                                ZStack {
                                    Circle().fill(RSMSTheme.gold.opacity(0.1)).frame(width: 40, height: 40)
                                    Text(String(staff.fullName.prefix(1)))
                                        .font(.headline).foregroundStyle(RSMSTheme.gold)
                                }
                                Text(staff.fullName)
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(RSMSTheme.textPrimary)
                            } else {
                                Text("Select Sales Associate...")
                                    .font(.title3)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(RSMSTheme.textTertiary)
                        }
                        .padding(16)
                        .background(RSMSTheme.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
                    }
                }
                .rsmsCard(padding: 24)
                
                // MARK: - Step 2: Target Parameters
                VStack(alignment: .leading, spacing: 24) {
                    SectionHeader(title: "2. Goal Parameters")
                    
                    // Period Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Goal Period")
                            .font(.caption.weight(.bold)).tracking(1)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        
                        Picker("Period", selection: $viewModel.draftPeriod) {
                            ForEach(GoalPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue.capitalized).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .colorMultiply(RSMSTheme.surfaceTertiary)
                        .onChange(of: viewModel.draftPeriod) { _, _ in
                            viewModel.loadPreviousGoal()
                        }
                    }
                    
                    Divider().overlay(RSMSTheme.divider)
                    
                    // Stepper for Amount
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Amount")
                            .font(.caption.weight(.bold)).tracking(1)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        
                        HStack(spacing: 20) {
                            Button {
                                if viewModel.draftAmount >= 1000 { viewModel.draftAmount -= 1000 }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(RSMSTheme.gold)
                                    .frame(width: 60, height: 60)
                                    .background(RSMSTheme.surfaceTertiary)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Updated to use the Rupee symbol and commas!
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("₹")
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(RSMSTheme.gold)
                                Text(viewModel.draftAmount.formatted(.number.precision(.fractionLength(0))))
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundStyle(RSMSTheme.gold)
                                    .contentTransition(.numericText())
                                    .animation(.snappy, value: viewModel.draftAmount)
                            }
                            
                            Spacer()
                            
                            Button {
                                viewModel.draftAmount += 1000
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(RSMSTheme.gold)
                                    .frame(width: 60, height: 60)
                                    .background(RSMSTheme.surfaceTertiary)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Divider().overlay(RSMSTheme.divider)
                    
                    // Dates
                    HStack(spacing: 24) {
                        DatePicker("Start Date", selection: $viewModel.draftStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $viewModel.draftEndDate, displayedComponents: .date)
                    }
                    .foregroundStyle(RSMSTheme.textPrimary)
                }
                .rsmsCard(padding: 24)
                
                // MARK: - Save Button
                Button {
                    let storeId = appViewModel.currentStoreId ?? UUID()
                    Task {
                        await viewModel.saveNewGoal(dataStore: appViewModel.dataStore, storeId: storeId)
                        navPath.removeAll()
                    }
                } label: {
                    Text(viewModel.isUpdating ? "UPDATE GOAL" : "SAVE NEW GOAL")
                        .font(.headline.weight(.bold))
                        .tracking(1)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: viewModel.isUpdating)
                        .foregroundStyle(RSMSTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            (viewModel.draftSelectedStaff == nil || viewModel.draftAmount <= 0) ? RSMSTheme.surfaceTertiary : RSMSTheme.gold
                        )
                        .clipShape(Capsule())
                        .shadow(color: (viewModel.draftSelectedStaff == nil || viewModel.draftAmount <= 0) ? .clear : RSMSTheme.gold.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .disabled(viewModel.draftSelectedStaff == nil || viewModel.draftAmount <= 0)
            }
            .padding(32)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Assign Sales Goal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Assign Goal Form") {
    NavigationStack {
        AssignGoalFormView(
            viewModel: SalesGoalViewModel(),
            navPath: .constant([])
        )
    }
    .environment(AppViewModel())
}
