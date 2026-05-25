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
                    TextField("Full Name", text: $full_name)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        
                    TextField("Avatar URL", text: $avatar_url)
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
                    Picker("Role", selection: $role) {
                        ForEach([UserRole.salesAssociate, UserRole.inventoryController]) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                    
                    Toggle("Is Active", isOn: $is_active)
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
            .scrollContentBackground(.hidden)
            .background(RSMSTheme.background.ignoresSafeArea())
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
        isSubmitting = true
        errorMessage = nil
        
        do {
            try await EmployeeCreationService.shared.createEmployee(
                fullName: full_name,
                email: email,
                phone: phone,
                role: role,
                avatarURL: avatar_url,
                isActive: is_active,
                password: password,
                dataStore: appVM.dataStore,
                currentStoreId: appVM.currentStoreId
            )
            
            onCreated?()
            dismiss()
        } catch let error as EmployeeCreationError {
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isSubmitting = false
    }
}
