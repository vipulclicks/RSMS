//
//  SupabaseMFA.swift
//  RSMS
//
//  MFA GoTrue REST endpoints.
//

import Foundation

class SupabaseMFA {
    static let shared = SupabaseMFA()
    
    private init() {}
    
    private var authURL: String { "\(SupabaseConfig.projectURL)/auth/v1" }
    
    /// Enroll a new TOTP factor
    func enrollTOTP(friendlyName: String, accessToken: String) async throws -> MFAEnrollResponse {
        guard let url = URL(string: "\(authURL)/factors") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: String] = [
            "factor_type": "totp",
            "friendly_name": friendlyName
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(MFAEnrollResponse.self, from: data)
    }
    
    /// Create a challenge for an enrolled factor
    func challenge(factorId: String, accessToken: String) async throws -> MFAChallengeResponse {
        guard let url = URL(string: "\(authURL)/factors/\(factorId)/challenge") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(MFAChallengeResponse.self, from: data)
    }
    
    /// Verify a challenge with the user's TOTP code
    func verify(factorId: String, challengeId: String, code: String, accessToken: String) async throws -> AuthSession? {
        guard let url = URL(string: "\(authURL)/factors/\(factorId)/verify") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: String] = [
            "challenge_id": challengeId,
            "code": code
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        do {
            return try JSONDecoder().decode(AuthSession.self, from: data)
        } catch {
            print("Decoding AuthSession failed: \(error)")
            if let string = String(data: data, encoding: .utf8) {
                print("Response data (returning nil): \(string)")
            }
            return nil
        }
    }
    
    /// Remove an enrolled factor
    func unenroll(factorId: String, accessToken: String) async throws {
        guard let url = URL(string: "\(authURL)/factors/\(factorId)") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
    }
    
    /// List all factors for the current user
    func listFactors(accessToken: String) async throws -> [MFAFactor] {
        // Fetch user object which contains factors
        guard let url = URL(string: "\(authURL)/user") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let user = try JSONDecoder().decode(AuthUser.self, from: data)
        return user.factors ?? []
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let string = String(data: data, encoding: .utf8) {
                print("SupabaseMFA API Error [\(httpResponse.statusCode)]: \(string)")
            }
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data), let desc = authError.errorDescriptionString {
                throw NSError(domain: "SupabaseMFA", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
            }
            throw NSError(domain: "SupabaseMFA", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "MFA operation failed. HTTP \(httpResponse.statusCode)"])
        }
    }
}
