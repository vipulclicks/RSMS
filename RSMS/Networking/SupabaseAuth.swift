//
//  SupabaseAuth.swift
//  RSMS
//
//  Lightweight GoTrue client for Supabase Authentication over URLSession.
//

import Foundation

/// Defines the Supabase Auth Session structure returned by GoTrue.
struct AuthSession: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

/// Defines the user object inside the AuthSession.
struct AuthUser: Codable {
    let id: UUID
    let email: String
    let role: String?
}

/// Simple error for Authentication failures.
struct AuthError: Decodable, LocalizedError {
    let error: String
    let errorDescription: String

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }

    var errorDescriptionString: String? { errorDescription }
}

/// A lightweight Auth client for logging in, out, and password resets.
class SupabaseAuth {
    static let shared = SupabaseAuth()
    
    private init() {}
    
    /// The base URL for Supabase GoTrue Auth API
    private var authURL: String { "\(SupabaseConfig.projectURL)/auth/v1" }
    
    /// Authenticate a user with Email and Password.
    /// - Returns: A valid AuthSession containing the JWT and user ID.
    func signIn(email: String, password: String) async throws -> AuthSession {
        guard let url = URL(string: "\(authURL)/token?grant_type=password") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 200 {
            let session = try JSONDecoder().decode(AuthSession.self, from: data)
            return session
        } else {
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data) {
                throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: authError.errorDescription])
            }
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication failed. Please check your credentials."])
        }
    }

    // MARK: - Password Reset (Step 1: Request Reset Email)

    /// Sends a password-reset email to the given address via Supabase GoTrue `/recover`.
    /// The email contains a link that, when clicked, grants the user a short-lived session
    /// they can use to call `updatePassword`.
    ///
    /// - Parameter email: The user's registered email address.
    /// - Parameter redirectTo: Optional deep-link URL the reset link should redirect to
    ///   (e.g. your app's custom URL scheme like `rsms://reset-callback`).
    /// - Throws: On network or server errors.
    func requestPasswordReset(email: String, redirectTo: String? = nil) async throws {
        guard let url = URL(string: "\(authURL)/recover") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        var body: [String: String] = ["email": email]
        if let redirectTo {
            body["redirect_to"] = redirectTo
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // GoTrue returns 200 on success (even if email doesn't exist, for security)
        guard (200...299).contains(httpResponse.statusCode) else {
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data) {
                throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: authError.errorDescription])
            }
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Password reset request failed: \(body)"])
        }
    }

    // MARK: - Password Reset (Step 2: Verify OTP Code)

    /// Verifies the 6-digit OTP code sent to the user's email via GoTrue `/verify`.
    /// On success, returns an `AuthSession` whose `accessToken` can be used to update the password.
    ///
    /// - Parameters:
    ///   - email: The email address that received the OTP.
    ///   - otpCode: The 6-digit code from the email.
    /// - Returns: A valid `AuthSession` containing a JWT for the password update.
    /// - Throws: On invalid code, expired code, or network errors.
    func verifyOTP(email: String, otpCode: String) async throws -> AuthSession {
        guard let url = URL(string: "\(authURL)/verify") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "type": "recovery",
            "token": otpCode,
            "email": email
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data) {
                throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: authError.errorDescription])
            }
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "OTP verification failed: \(body)"])
        }

        do {
            return try JSONDecoder().decode(AuthSession.self, from: data)
        } catch {
            throw NSError(domain: "SupabaseAuth", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to decode session after OTP verification."])
        }
    }


    // MARK: - Password Reset (Step 2: Update Password)

    /// Updates the password for the currently authenticated user via GoTrue `/user`.
    /// Call this after the user clicks the reset link and obtains a valid session token.
    ///
    /// - Parameters:
    ///   - newPassword: The new password (minimum 6 characters per Supabase default).
    ///   - accessToken: The JWT access token from the reset-link session.
    /// - Throws: On network, validation, or server errors.
    func updatePassword(newPassword: String, accessToken: String) async throws {
        guard newPassword.count >= 6 else {
            throw NSError(domain: "SupabaseAuth", code: 422,
                          userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters."])
        }

        guard let url = URL(string: "\(authURL)/user") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = ["password": newPassword]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data) {
                throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: authError.errorDescription])
            }
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Password update failed: \(body)"])
        }
    }

    // MARK: - Sign Out

    /// Signs out the current user by invalidating the session on the server.
    ///
    /// - Parameter accessToken: The JWT to invalidate.
    func signOut(accessToken: String) async throws {
        guard let url = URL(string: "\(authURL)/logout") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Sign out failed: \(body)"])
        }
    }

    // MARK: - Sign Up

    /// Create a new user with Email and Password.
    func signUp(email: String, password: String) async throws -> AuthSession {
        guard let url = URL(string: "\(authURL)/signup") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            do {
                let session = try JSONDecoder().decode(AuthSession.self, from: data)
                return session
            } catch {
                if let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
                    return AuthSession(accessToken: "", tokenType: "", expiresIn: 0, refreshToken: "", user: user)
                }
                throw error
            }
        } else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unknown response"
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data), let desc = authError.errorDescriptionString {
                throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
            }
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Sign up failed: \(responseString)"])
        }
    }

}
