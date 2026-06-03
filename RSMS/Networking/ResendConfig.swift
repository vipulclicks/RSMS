//
//  ResendConfig.swift
//  RSMS
//
//  Configuration for the Resend email service.
//

import Foundation

/// Connection parameters for the Resend email API.
enum ResendConfig {
    /// Your Resend API key (starts with "re_")
    static let apiKey = "re_ZjjLcNn9_79p97YmrZCUxo7nYmL5wEanG"

    /// Sender address — must be `onboarding@resend.dev` on the free tier
    static let fromAddress = "Luxora <onboarding@resend.dev>"

    /// Override recipient for free-tier testing.
    /// Set to `nil` in production to send to the actual employee email.
    static let testRecipientOverride: String? = "premkur5555@gmail.com"

    /// Resend API endpoint
    static let apiURL = "https://api.resend.com/emails"
}
