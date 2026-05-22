//
//  PasswordResetService.swift
//  RSMS
//
//  Production-ready network client for handling password resets.
//

import Foundation
import SwiftUI
import Observation

/// Defines domain-specific errors for the password reset flow.
enum PasswordResetError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError(Error)
    case serverError(statusCode: Int)
    case unauthorized // 401 or 403
    case badRequest(message: String) // 400
    case invalidResponse
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server URL is invalid."
        case .networkError(let error):
            return "Network connection failed: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server encountered an error (Code: \(statusCode)). Please try again later."
        case .unauthorized:
            return "Unauthorized access. Your session may have expired."
        case .badRequest(let message):
            return "Invalid request: \(message)"
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .decodingError(let error):
            return "Data processing failed: \(error.localizedDescription)"
        }
    }
}

/// A response model to handle server errors gracefully.
struct APIErrorResponse: Decodable, Sendable {
    let message: String
}

@Observable
@MainActor
final class PasswordResetService {
    
    // States for UI binding
    var isLoading = false
    var errorMessage: String?
    var isSuccess = false
    
    /// Executes the password reset network request safely.
    func resetPassword(email: String, code: String, newPassword: String) async {
        // Reset state before starting
        self.isLoading = true
        self.errorMessage = nil
        self.isSuccess = false
        
        // Ensure state is updated on MainActor after task completes
        defer { self.isLoading = false }
        
        do {
            try await performResetRequest(email: email, code: code, newPassword: newPassword)
            self.isSuccess = true
        } catch let error as PasswordResetError {
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    /// The core networking engine for the reset request.
    /// Runs off the main thread to prevent UI blocking.
    private nonisolated func performResetRequest(email: String, code: String, newPassword: String) async throws {
        // 1. URL Construction
        guard let url = URL(string: "https://api.maisonlumiere.com/v1/auth/reset-password") else {
            throw PasswordResetError.invalidURL
        }
        
        // 2. Request Configuration
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 3. Payload Serialization
        let payload = [
            "email": email,
            "resetToken": code,
            "newPassword": newPassword
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw PasswordResetError.decodingError(error)
        }
        
        // 4. Network Execution
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PasswordResetError.networkError(error)
        }
        
        // 5. Response Validation
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PasswordResetError.invalidResponse
        }
        
        // 6. Status Code Handling
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            return
            
        case 400:
            // Bad Request - Attempt to decode specific server message
            if let errorPayload = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw PasswordResetError.badRequest(message: errorPayload.message)
            }
            throw PasswordResetError.badRequest(message: "Invalid input provided.")
            
        case 401, 403:
            // Unauthorized or Forbidden
            throw PasswordResetError.unauthorized
            
        case 500...599:
            // Server Error
            throw PasswordResetError.serverError(statusCode: httpResponse.statusCode)
            
        default:
            throw PasswordResetError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
