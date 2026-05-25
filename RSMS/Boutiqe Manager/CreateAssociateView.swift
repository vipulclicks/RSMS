import SwiftUI

struct CreateAssociateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    @State private var full_name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var avatar_url: String = ""
    @State private var is_active: Bool = true
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var role: UserRole = .salesAssociate
    
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var onCreated: (() -> Void)?
    
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
                
                Text("Add Employee")
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
                        Label("EMPLOYEE IDENTITY", systemImage: "person.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .tracking(1)
                        
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            TextField("", text: $full_name)
                                .textContentType(.name)
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            TextField("", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .textContentType(.emailAddress)
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Phone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            TextField("", text: $phone)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Avatar URL
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avatar URL")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            TextField("", text: $avatar_url)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .textContentType(.URL)
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Divider().overlay(RSMSTheme.border)
                        
                        Label("AUTHENTICATION", systemImage: "lock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .tracking(1)
                            
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password (min 6 characters) *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            SecureField("", text: $password)
                                .textContentType(.newPassword)
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            SecureField("", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding(16)
                                .background(RSMSTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Divider().overlay(RSMSTheme.border)
                        
                        Label("EMPLOYMENT", systemImage: "briefcase.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .tracking(1)
                            
                        // Role
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role *")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                            
                            Menu {
                                ForEach([UserRole.salesAssociate, UserRole.inventoryController]) { r in
                                    Button(r.displayName) { role = r }
                                }
                            } label: {
                                HStack {
                                    Text(role.displayName)
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
                        
                        // Is Active
                        Toggle("Is Active", isOn: $is_active)
                            .tint(RSMSTheme.primaryDark)
                            .padding(.top, 8)
                            
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
                        Task { await saveAssociate() }
                    } label: {
                        HStack {
                            Text(isSubmitting ? "Saving..." : "Add Employee")
                            if isSubmitting {
                                ProgressView().tint(.white).padding(.leading, 4)
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            (isSubmitting || !isValid) ? 
                            AnyShapeStyle(RSMSTheme.textTertiary) : 
                            AnyShapeStyle(RSMSTheme.primaryGradient)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: (isSubmitting || !isValid) ? .clear : RSMSTheme.primaryDark.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isSubmitting || !isValid)
                }
                .padding(24)
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
    }
    
    private var isValid: Bool {
        !full_name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    @MainActor
    private func saveAssociate() async {
        guard let storeId = appVM.currentStoreId else {
            errorMessage = "No active store found."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            // 1. Create Auth User silently with the provided password
            let session = try await SupabaseAuth.shared.signUp(email: email, password: password)
            let newAuthId = session.user.id
            
            // 2. Create Profile
            let newProfile = UserProfile(
                id: newAuthId,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                fullName: full_name.trimmingCharacters(in: .whitespacesAndNewlines),
                role: role,
                storeId: storeId,
                avatarURL: avatar_url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : avatar_url.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
                isActive: is_active,
                createdAt: .now,
                updatedAt: .now
            )
            
            do {
                // The DB has a trigger that automatically creates a placeholder "New User" profile upon sign up.
                // To avoid duplicate key errors, we update that existing profile instead of creating a new one.
                try await appVM.dataStore.updateUser(newProfile)
                
                // Ensure the local data store has the new user since updateUser might not append it if it wasn't fetched yet.
                if !appVM.dataStore.users.contains(where: { $0.id == newProfile.id }) {
                    appVM.dataStore.users.append(newProfile)
                }
            } catch {
                throw error
            }
            
            onCreated?()
            dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
}
