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
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.surfacePrimary)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Text("New Employee")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Spacer()
                
                // Invisible placeholder to center the title perfectly
                Color.clear.frame(width: 80, height: 1)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 24) {
                    // EMPLOYEE DETAILS SECTION
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.caption.weight(.bold))
                            Text("EMPLOYEE DETAILS")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                        }
                        .foregroundStyle(RSMSTheme.primaryDark)
                        
                        customTextField(title: "Full Name *", placeholder: "Enter employee name", text: $full_name)
                        customTextField(title: "Email *", placeholder: "Enter email address", text: $email, keyboardType: .emailAddress)
                        
                        HStack(spacing: 16) {
                            customTextField(title: "Phone", placeholder: "Phone number", text: $phone, keyboardType: .phonePad)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Role *")
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.textSecondary)
                                
                                Menu {
                                    Picker("Role", selection: $role) {
                                        ForEach([UserRole.salesAssociate, UserRole.inventoryController]) { r in
                                            Text(r.displayName).tag(r)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(role.displayName)
                                            .foregroundStyle(RSMSTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(RSMSTheme.textSecondary)
                                    }
                                    .padding()
                                    .background(RSMSTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        
                        customTextField(title: "Avatar URL", placeholder: "Optional avatar link", text: $avatar_url, keyboardType: .URL)
                    }
                    
                    Divider().overlay(RSMSTheme.border)
                    
                    // AUTHENTICATION SECTION
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield")
                                .font(.caption.weight(.bold))
                            Text("AUTHENTICATION")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                        }
                        .foregroundStyle(RSMSTheme.primaryDark)
                        
                        HStack(spacing: 16) {
                            customSecureField(title: "Password *", placeholder: "Min 6 chars", text: $password)
                            customSecureField(title: "Confirm Password *", placeholder: "Repeat password", text: $confirmPassword)
                        }
                        
                        Toggle("Active Employee", isOn: $is_active)
                            .tint(RSMSTheme.primaryDark)
                            .foregroundStyle(RSMSTheme.textPrimary)
                            .font(.subheadline.weight(.medium))
                            .padding(.top, 8)
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(RSMSTheme.danger)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RSMSTheme.danger.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // SAVE BUTTON
                    Button {
                        Task { await saveAssociate() }
                    } label: {
                        Text("Save Employee")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? RSMSTheme.primaryDark : RSMSTheme.textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isSubmitting || !isValid)
                    .padding(.top, 16)
                }
                .padding(24)
                .background(RSMSTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(RSMSTheme.background.ignoresSafeArea())
        .overlay {
            if isSubmitting {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(RSMSTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - ViewBuilders for Custom Fields
    
    private func customTextField(title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding()
                .background(RSMSTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func customSecureField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
            
            SecureField(placeholder, text: text)
                .textContentType(.newPassword)
                .foregroundStyle(RSMSTheme.textPrimary)
                .padding()
                .background(RSMSTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Logic
    
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
