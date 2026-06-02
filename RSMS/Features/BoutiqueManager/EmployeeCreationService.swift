import Foundation
import SwiftUI

enum EmployeeCreationError: LocalizedError {
    case missingFields
    case missingStoreId
    case authSignupFailed(String)
    case profileCreationFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingFields:
            return "Please fill in all required fields (Name, Email, Password, Role)."
        case .missingStoreId:
            return "Internal error: No active store identified for this session."
        case .authSignupFailed(let reason):
            return "Failed to create user login: \(reason)"
        case .profileCreationFailed(let reason):
            return "User login was created, but we couldn't save their profile. You may need to manually add them or contact support. Details: \(reason)"
        case .networkError(let reason):
            return "Network connection issue: \(reason)"
        }
    }
}

@MainActor
final class EmployeeCreationService {
    
    static let shared = EmployeeCreationService()
    
    private init() {}
    
    func createEmployee(
        fullName: String,
        email: String,
        phone: String,
        role: UserRole,
        avatarURL: String,
        isActive: Bool,
        password: String,
        dataStore: DataStore,
        currentStoreId: UUID?
    ) async throws {
        
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAvatar = avatarURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty || trimmedEmail.isEmpty || password.isEmpty {
            throw EmployeeCreationError.missingFields
        }
        
        guard let storeId = currentStoreId else {
            throw EmployeeCreationError.missingStoreId
        }
        
        // 1. Create the Auth User with metadata so the backend trigger can automatically assign store_id and role
        let userData: [String: String] = [
            "full_name": trimmedName,
            "store_id": storeId.uuidString,
            "role": role.rawValue,
            "phone": trimmedPhone,
            "avatar_url": trimmedAvatar,
            "is_active": isActive ? "true" : "false"
        ]
        
        let newAuthUser: AuthUser
        do {
            newAuthUser = try await SupabaseAuth.shared.signUp(email: trimmedEmail, password: password, userData: userData)
        } catch let nsError as NSError where nsError.domain == "SupabaseAuth" {
            throw EmployeeCreationError.authSignupFailed(nsError.localizedDescription)
        } catch {
            throw EmployeeCreationError.networkError(error.localizedDescription)
        }
        
        // 3. The backend trigger `handle_new_user` automatically creates the fully-populated Profile in `public.user_profiles`
        // by reading the `raw_user_meta_data` we just sent. We do NOT need a post-signup UPDATE.
        
        // 4. Authoritative Refresh: We just need to trigger a re-fetch in the UI.
        // We can optionally fetch the created user to cache it immediately, or let the UI handle it.
    }
}
