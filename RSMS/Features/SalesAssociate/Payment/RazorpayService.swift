//
//  RazorpayService.swift
//  RSMS
//

import Foundation

// SANDBOX TEST CARDS:
// Success:  4111 1111 1111 1111 | Any future date | Any CVV
// Declined: 4000 0000 0000 0002
// UPI Success: success@razorpay
// UPI Failure: failure@razorpay

struct RazorpayOrder: Codable {
    let id: String
    let entity: String
    let amount: Int
    let currency: String
    let receipt: String
    let status: String
}

final class RazorpayService {
    // Sandbox credentials — replace with real keys from Razorpay Test Mode dashboard
    static let sandboxKeyId = "rzp_test_Sv7udg2RZ8M3K0"
    private static let sandboxSecret = "FF46OwYLcNiX7pO5aUHmR33t"

    static func createOrder(amount: Double, receipt: String) async throws -> RazorpayOrder {
        let url = URL(string: "https://api.razorpay.com/v1/orders")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let authString = "\(sandboxKeyId):\(sandboxSecret)"
        let authData = authString.data(using: .utf8)!
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")

        // Amount in paise
        let amountInPaise = Int(amount * 100)
        let body: [String: Any] = [
            "amount": amountInPaise,
            "currency": "INR",
            "receipt": receipt
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                throw NSError(domain: "Razorpay", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(errorJson)"])
            }
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(RazorpayOrder.self, from: data)
    }
}
