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
        NavigationStack {
            Form {
                Section("Personal Details") {
                    TextField("Full Name (full_name)", text: $full_name)
                        .textContentType(.name)
                    
                    TextField("Email (email)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                    
                    TextField("Phone (phone)", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        
                    TextField("Avatar URL (avatar_url)", text: $avatar_url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .textContentType(.URL)
                }
                
                Section("Authentication") {
                    SecureField("Password (min 6 characters)", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                Section("Employment") {
                    Picker("Role (role)", selection: $role) {
                        ForEach([UserRole.salesAssociate, UserRole.inventoryController]) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                    
                    Toggle("Is Active (is_active)", isOn: $is_active)
                        .tint(RSMSTheme.primaryDark)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(RSMSTheme.danger)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Add Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Employee") {
                        Task { await saveAssociate() }
                    }
                    .disabled(isSubmitting || !isValid)
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
        }
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
