//
//  ResendEmailService.swift
//  RSMS
//
//  Sends transactional emails via the Resend REST API.
//  Used to email login credentials to newly onboarded staff.
//

import Foundation

/// Result of an email send attempt.
enum EmailSendResult {
    case success
    case failed(String)
}

class ResendEmailService {
    static let shared = ResendEmailService()

    private init() {}

    /// Send onboarding credentials email to a new employee.
    ///
    /// On the free tier, the `to` address is overridden to `ResendConfig.testRecipientOverride`.
    /// The email contains the employee's name, login email, temporary password, and assigned role.
    func sendOnboardingEmail(
        toEmail: String,
        fullName: String,
        password: String,
        role: String,
        storeName: String
    ) async -> EmailSendResult {
        guard let url = URL(string: ResendConfig.apiURL) else {
            return .failed("Invalid Resend API URL")
        }

        // On free tier, override recipient to the test email
        let recipient = ResendConfig.testRecipientOverride ?? toEmail

        let htmlBody = buildOnboardingHTML(
            fullName: fullName,
            email: toEmail,
            password: password,
            role: role,
            storeName: storeName
        )

        let body: [String: Any] = [
            "from": ResendConfig.fromAddress,
            "to": [recipient],
            "subject": "Welcome to Luxora — Your Login Credentials",
            "html": htmlBody
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(ResendConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .failed("Failed to encode email body: \(error.localizedDescription)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failed("Invalid response from Resend API")
            }

            if (200...299).contains(httpResponse.statusCode) {
                print("[ResendEmail] ✅ Onboarding email sent to \(recipient)")
                return .success
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("[ResendEmail] ❌ HTTP \(httpResponse.statusCode): \(responseString)")
                return .failed("Email send failed (HTTP \(httpResponse.statusCode))")
            }
        } catch {
            print("[ResendEmail] ❌ Network error: \(error.localizedDescription)")
            return .failed("Network error: \(error.localizedDescription)")
        }
    }

    // MARK: - HTML Template

    private func buildOnboardingHTML(
        fullName: String,
        email: String,
        password: String,
        role: String,
        storeName: String
    ) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Welcome to Luxora</title>
        </head>
        <body style="margin:0;padding:0;background-color:#f4f1ec;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
            <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f1ec;padding:40px 20px;">
                <tr>
                    <td align="center">
                        <table width="560" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
                            <!-- Header -->
                            <tr>
                                <td style="background:linear-gradient(135deg,#1a1a2e,#2d2d44);padding:32px 40px;text-align:center;">
                                    <h1 style="margin:0;color:#d4af37;font-size:28px;font-weight:700;letter-spacing:2px;">LUXORA</h1>
                                    <p style="margin:8px 0 0;color:#c8bfa9;font-size:13px;letter-spacing:1px;">RETAIL STORE MANAGEMENT SYSTEM</p>
                                </td>
                            </tr>
                            <!-- Body -->
                            <tr>
                                <td style="padding:40px;">
                                    <h2 style="margin:0 0 8px;color:#1a1a2e;font-size:22px;font-weight:700;">Welcome, \(fullName)!</h2>
                                    <p style="margin:0 0 24px;color:#6b6b7b;font-size:15px;line-height:1.6;">
                                        Your account has been created by your store manager. Below are your login credentials to access the Luxora app.
                                    </p>

                                    <!-- Credentials Card -->
                                    <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f6f2;border-radius:12px;border:1px solid #e8e4dd;margin-bottom:24px;">
                                        <tr>
                                            <td style="padding:24px;">
                                                <table width="100%" cellpadding="0" cellspacing="0">
                                                    <tr>
                                                        <td style="padding:8px 0;">
                                                            <span style="color:#8a8a9a;font-size:12px;text-transform:uppercase;letter-spacing:1px;">Email</span><br>
                                                            <span style="color:#1a1a2e;font-size:16px;font-weight:600;">\(email)</span>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td style="padding:8px 0;border-top:1px solid #e8e4dd;">
                                                            <span style="color:#8a8a9a;font-size:12px;text-transform:uppercase;letter-spacing:1px;">Temporary Password</span><br>
                                                            <span style="color:#1a1a2e;font-size:16px;font-weight:600;font-family:monospace;background:#fff3cd;padding:2px 8px;border-radius:4px;">\(password)</span>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td style="padding:8px 0;border-top:1px solid #e8e4dd;">
                                                            <span style="color:#8a8a9a;font-size:12px;text-transform:uppercase;letter-spacing:1px;">Role</span><br>
                                                            <span style="color:#1a1a2e;font-size:16px;font-weight:600;">\(role)</span>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td style="padding:8px 0;border-top:1px solid #e8e4dd;">
                                                            <span style="color:#8a8a9a;font-size:12px;text-transform:uppercase;letter-spacing:1px;">Store</span><br>
                                                            <span style="color:#1a1a2e;font-size:16px;font-weight:600;">\(storeName)</span>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                    </table>

                                    <!-- Warning -->
                                    <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#fff3cd;border-radius:8px;border-left:4px solid #d4af37;margin-bottom:24px;">
                                        <tr>
                                            <td style="padding:16px;">
                                                <p style="margin:0;color:#856404;font-size:14px;font-weight:600;">⚠️ Important</p>
                                                <p style="margin:4px 0 0;color:#856404;font-size:13px;line-height:1.5;">
                                                    Please change your password after your first login for security purposes. You can do this from your Profile &gt; Change Password.
                                                </p>
                                            </td>
                                        </tr>
                                    </table>

                                    <p style="margin:0;color:#8a8a9a;font-size:13px;line-height:1.5;">
                                        If you have any questions, please contact your store manager.
                                    </p>
                                </td>
                            </tr>
                            <!-- Footer -->
                            <tr>
                                <td style="background-color:#f8f6f2;padding:20px 40px;text-align:center;border-top:1px solid #e8e4dd;">
                                    <p style="margin:0;color:#8a8a9a;font-size:12px;">
                                        This is an automated message from Luxora. Please do not reply.
                                    </p>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """
    }
}
