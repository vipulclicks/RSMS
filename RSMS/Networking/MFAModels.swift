//
//  MFAModels.swift
//  RSMS
//
//  Models for Supabase GoTrue MFA REST endpoints.
//

import Foundation

struct MFAFactor: Codable, Identifiable {
    let id: String
    let friendlyName: String?
    let factorType: String
    let status: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case friendlyName = "friendly_name"
        case factorType = "factor_type"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MFAEnrollResponse: Codable {
    let id: String
    let type: String
    let totp: TOTPData

    struct TOTPData: Codable {
        let qrCode: String
        let secret: String
        let uri: String

        enum CodingKeys: String, CodingKey {
            case qrCode = "qr_code"
            case secret
            case uri
        }
    }
}

struct MFAChallengeResponse: Codable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id
    }
}
