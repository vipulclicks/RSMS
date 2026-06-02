import SwiftUI

struct StaffPickerView: View {
    @Bindable var viewModel: SalesGoalViewModel
    @Binding var navPath: [StaffRoute]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.availableStaff) { staff in
                    Button {
                        // 1. Set the staff
                        viewModel.draftSelectedStaff = staff
                        
                        // 2. Trigger the search for previous goals
                        viewModel.loadPreviousGoal()
                        
                        // 3. Pop back
                        if !navPath.isEmpty {
                            navPath.removeLast()
                        }
                    } label: {
                        staffRow(staff)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Select Associate")
    }
    
    private func staffRow(_ staff: UserProfile) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.gold.opacity(0.1))
                    .frame(width: 50, height: 50)
                Text(String(staff.fullName.prefix(1)))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RSMSTheme.gold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(staff.fullName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text(staff.role.displayName)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
            }
            Spacer()
            
            if viewModel.draftSelectedStaff?.id == staff.id {
                Image(systemName: "checkmark")
                    .foregroundStyle(RSMSTheme.success)
                    .font(.title3.weight(.bold))
            }
        }
        .rsmsCard(padding: 16)
    }
}

#Preview("Staff Picker") {
    NavigationStack {
        StaffPickerView(
            viewModel: SalesGoalViewModel(),
            navPath: .constant([])
        )
    }
}
