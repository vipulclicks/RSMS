//
//  SupabaseClient.swift
//  RSMS
//
//  A native URLSession client for Supabase PostgREST CRUD operations.
//  No external dependencies — uses Foundation networking only.
//

import Foundation

// MARK: - Errors

enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Supabase URL."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        case .decodingFailed(let err):
            return "Decoding failed: \(err.localizedDescription)"
        }
    }
}

// MARK: - Client

/// A lightweight, generic REST client for Supabase PostgREST endpoints.
///
/// Supports full CRUD:
/// - `fetch` — GET all rows (with optional PostgREST filters)
/// - `fetchById` — GET single row by primary key
/// - `insert` — POST a new row (returns the created row)
/// - `update` — PATCH an existing row by ID
/// - `delete` — DELETE a row by ID
///
/// All methods are async/throwing and use `Codable` for serialization.
final class SupabaseClient: Sendable {
    static let shared = SupabaseClient()

    /// Global session token for authenticated requests (JWT)
    var accessToken: String?

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)

        // ── Decoder ──────────────────────────────────────────
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // ISO 8601 with fractional seconds (Supabase default for timestamptz)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = iso.date(from: str) { return d }

            // ISO 8601 without fractional seconds
            iso.formatOptions = [.withInternetDateTime]
            if let d = iso.date(from: str) { return d }

            // Date-only (for `date` columns like shift_date, scheduled_date)
            let dateOnly = DateFormatter()
            dateOnly.dateFormat = "yyyy-MM-dd"
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            if let d = dateOnly.date(from: str) { return d }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(str)"
            )
        }
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder

        // ── Encoder ──────────────────────────────────────────
        let encoder = JSONEncoder()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        encoder.dateEncodingStrategy = .custom { date, enc in
            var container = enc.singleValueContainer()
            try container.encode(isoFormatter.string(from: date))
        }
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - READ
    // ══════════════════════════════════════════════════════════

    /// Fetch all rows from a table, with optional PostgREST query parameters.
    func fetch<T: Decodable>(
        _ table: String,
        query: [String: String] = [:],
        select: String = "*"
    ) async throws -> [T] {
        var components = URLComponents(string: "\(SupabaseConfig.restURL)/\(table)")!
        var items = [URLQueryItem(name: "select", value: select)]
        for (key, value) in query {
            items.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = items

        guard let url = components.url else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode([T].self, from: data)
        } catch {
            throw SupabaseError.decodingFailed(underlying: error)
        }
    }

    /// Fetch a single row by its UUID primary key.
    func fetchById<T: Decodable>(_ table: String, id: UUID) async throws -> T {
        let results: [T] = try await fetch(table, query: ["id": "eq.\(id.uuidString)"])
        guard let first = results.first else {
            throw SupabaseError.httpError(statusCode: 404, body: "No \(table) row with id \(id)")
        }
        return first
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - CREATE
    // ══════════════════════════════════════════════════════════

    /// Insert a new row and return the created record.
    @discardableResult
    func insert<T: Codable>(_ table: String, record: T) async throws -> T {
        guard let url = URL(string: "\(SupabaseConfig.restURL)/\(table)") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(record)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        let rows = try decoder.decode([T].self, from: data)
        guard let created = rows.first else {
            throw SupabaseError.invalidResponse
        }
        return created
    }

    /// Insert multiple rows and return the created records.
    @discardableResult
    func insertMany<T: Codable>(_ table: String, records: [T]) async throws -> [T] {
        guard !records.isEmpty else { return [] }
        guard let url = URL(string: "\(SupabaseConfig.restURL)/\(table)") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(records)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode([T].self, from: data)
        } catch {
            throw SupabaseError.decodingFailed(underlying: error)
        }
    }
    
    /// Insert or Update a row.
    func upsert<T: Decodable, U: Encodable>(_ table: String, record: U) async throws -> T {
        guard let url = URL(string: "\(SupabaseConfig.restURL)/\(table)") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(record)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        let rows = try decoder.decode([T].self, from: data)
        guard let upserted = rows.first else {
            throw SupabaseError.invalidResponse
        }
        return upserted
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - UPDATE
    // ══════════════════════════════════════════════════════════

    @discardableResult
    func update<T: Codable>(_ table: String, id: UUID, record: T) async throws -> T {
        guard let url = URL(string: "\(SupabaseConfig.restURL)/\(table)?id=eq.\(id.uuidString)") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        applyHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(record)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let rows = try decoder.decode([T].self, from: data)
        guard let updated = rows.first else {
            throw NSError(domain: "SupabaseClient", code: 403, userInfo: [NSLocalizedDescriptionKey: "Update failed. You may not have permission to modify this record, or it does not exist."])
        }
        return updated
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - DELETE
    // ══════════════════════════════════════════════════════════

    /// Delete a row by its UUID primary key.
    func delete(_ table: String, id: UUID) async throws {
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)?id=eq.\(id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyHeaders(&request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - FUNCTIONS
    // ══════════════════════════════════════════════════════════

    /// Invoke a Supabase Edge Function
    func invokeFunction<T: Encodable>(_ functionName: String, body: T) async throws {
        let url = URL(string: "\(SupabaseConfig.projectURL)/functions/v1/\(functionName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - Helpers
    // ══════════════════════════════════════════════════════════

    private func applyHeaders(_ request: inout URLRequest) {
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        // Inject JWT Bearer token if logged in, otherwise default to anonKey
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.httpError(statusCode: http.statusCode, body: body)
        }
    }
    
    // ══════════════════════════════════════════════════════════
    // MARK: - STORAGE
    // ══════════════════════════════════════════════════════════
    
    /// Upload a file to a Supabase Storage bucket.
    /// Returns the path string.
    func uploadStorage(bucket: String, path: String, data: Data, contentType: String) async throws -> String {
        let storageEndpoint = SupabaseConfig.restURL.replacingOccurrences(of: "/rest/v1", with: "/storage/v1")
        guard let url = URL(string: "\(storageEndpoint)/object/\(bucket)/\(path)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        // Allow overwriting an existing file (upsert). Without this,
        // re-uploading the same avatar path returns a 409 Conflict and
        // the app silently falls back to a device-local file:// URL.
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.httpBody = data
        
        let (responseData, response) = try await session.data(for: request)
        try validateResponse(response, data: responseData)
        
        return "\(bucket)/\(path)"
    }
}
