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
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data) {
                throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: authError.errorDescription])
            }
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication failed. Please check your credentials."])
        }
    }
}
