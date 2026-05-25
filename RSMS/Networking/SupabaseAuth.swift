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

struct AuthError: Decodable, LocalizedError {
    let error: String?
    let errorDescription: String?
    let msg: String?
    let code: Int?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg
        case code
    }

    var errorDescriptionString: String? { errorDescription ?? msg ?? error ?? "Unknown authentication error" }
}

/// A lightweight Auth client for logging in and out.
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
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data), let desc = authError.errorDescriptionString {
                throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
            }
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication failed. Please check your credentials."])
        }
    }
    
    struct SignupRequest: Encodable {
        let email: String
        let password: String
        let data: [String: String]?
    }
    
    /// Create a new user with Email and Password.
    /// Note: Metadata is passed here so the backend trigger can read `raw_user_meta_data` to set `store_id` and `role` if configured to do so.
    /// - Returns: The AuthUser containing the generated ID.
    func signUp(email: String, password: String, userData: [String: String]? = nil) async throws -> AuthUser {
        guard let url = URL(string: "\(authURL)/signup") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let body = SignupRequest(email: email, password: password, data: userData)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            do {
                // Try to decode as full session (if auto-confirm is enabled)
                let session = try JSONDecoder().decode(AuthSession.self, from: data)
                return session.user
            } catch {
                do {
                    // Try to decode as AuthUser directly (if email confirmation is required)
                    let user = try JSONDecoder().decode(AuthUser.self, from: data)
                    return user
                } catch {
                    throw NSError(domain: "SupabaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode signup response: \(error.localizedDescription)"])
                }
            }
        } else {
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data), let desc = authError.errorDescriptionString {
                throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
            }
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Sign up failed with status \(httpResponse.statusCode)"])
        }
    }
}
