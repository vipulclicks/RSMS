//
//  MFASettingsViewModel.swift
//  RSMS
//
//  ViewModel for managing MFA enrollment.
//

import SwiftUI

@Observable @MainActor
class MFASettingsViewModel {
    var isEnrolling = false
    var enrollmentData: MFAEnrollResponse?
    var factors: [MFAFactor] = []
    var verificationCode = ""
    var error: String?
    var isLoading = false
    
    var hasVerifiedTOTPFactor: Bool {
        factors.contains { $0.factorType == "totp" && $0.status == "verified" }
    }
    
    func loadFactors() async {
        guard let token = SupabaseClient.shared.accessToken else { return }
        isLoading = true
        error = nil
        do {
            let fetchedFactors = try await SupabaseMFA.shared.listFactors(accessToken: token)
            // Filter to only TOTP factors, and only keep verified ones, plus any currently enrolling factor
            self.factors = fetchedFactors.filter { $0.factorType == "totp" }
        } catch {
            self.error = "Failed to load MFA settings: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func beginEnrollment() async {
        guard let token = SupabaseClient.shared.accessToken else { return }
        isLoading = true
        error = nil
        isEnrolling = true
        do {
            let response = try await SupabaseMFA.shared.enrollTOTP(friendlyName: "Microsoft Authenticator", accessToken: token)
            self.enrollmentData = response
        } catch {
            self.error = "Failed to begin enrollment: \(error.localizedDescription)"
            self.isEnrolling = false
        }
        isLoading = false
    }
    
    func confirmEnrollment() async {
        guard let token = SupabaseClient.shared.accessToken,
              let enrollData = enrollmentData,
              !verificationCode.isEmpty else { return }
        
        isLoading = true
        error = nil
        do {
            // 1. Challenge
            let challenge = try await SupabaseMFA.shared.challenge(factorId: enrollData.id, accessToken: token)
            
            // 2. Verify
            let session = try await SupabaseMFA.shared.verify(factorId: enrollData.id, challengeId: challenge.id, code: verificationCode, accessToken: token)
            
            // 3. Update global token to AAL2
            if let session = session {
                SupabaseClient.shared.accessToken = session.accessToken
            }
            
            // 4. Refresh factors
            self.isEnrolling = false
            self.enrollmentData = nil
            self.verificationCode = ""
            await loadFactors()
        } catch {
            self.error = "Verification failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func cancelEnrollment() async {
        // If we created an unverified factor, try to clean it up
        if let enrollData = enrollmentData, let token = SupabaseClient.shared.accessToken {
            try? await SupabaseMFA.shared.unenroll(factorId: enrollData.id, accessToken: token)
        }
        isEnrolling = false
        enrollmentData = nil
        verificationCode = ""
        error = nil
    }
    
    func removeFactor(_ factor: MFAFactor) async {
        guard let token = SupabaseClient.shared.accessToken else { return }
        isLoading = true
        error = nil
        do {
            try await SupabaseMFA.shared.unenroll(factorId: factor.id, accessToken: token)
            await loadFactors()
        } catch {
            self.error = "Failed to remove factor: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
