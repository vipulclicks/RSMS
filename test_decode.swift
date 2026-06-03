import Foundation

// Copy SupabaseClient subset
// Mock URL & keys
let projectURL = "https://lidoouszbcutddwrxbgy.supabase.co"
let anonKey = "sb_publishable_X11_v94UKdMch6EBFq1eyA_9jGIJuD8"
let restURL = "\(projectURL)/rest/v1"

enum MovementType: String, Codable, CaseIterable {
    case storeTransfer    = "store_transfer"
    case dcReplenishment  = "dc_replenishment"
    case vendorReturn     = "vendor_return"
    case clientTransfer   = "client_transfer"
}

enum MovementStatus: String, Codable, CaseIterable {
    case requested  = "requested"
    case approved   = "approved"
    case inTransit  = "in_transit"
    case received   = "received"
    case completed  = "completed"
    case cancelled  = "cancelled"
    case exception  = "exception"
    case partial    = "partial"
}

struct InventoryMovement: Codable, Identifiable, Hashable {
    let id: UUID
    let type: MovementType
    let sourceId: String
    let destinationId: String
    let status: MovementStatus
    let requestedBy: UUID?
    let approvedBy: UUID?
    let requestedAt: Date?
    let shippedAt: Date?
    let receivedAt: Date?
    let asnNumber: String?
    let itemsExpected: Int?
    let itemsReceived: Int?
    let reason: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, type, status, reason, notes
        case sourceId      = "source_id"
        case destinationId = "destination_id"
        case requestedBy   = "requested_by"
        case approvedBy    = "approved_by"
        case requestedAt   = "requested_at"
        case shippedAt     = "shipped_at"
        case receivedAt    = "received_at"
        case asnNumber     = "asn_number"
        case itemsExpected = "items_expected"
        case itemsReceived = "items_received"
    }
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = iso.date(from: str) { return d }

    iso.formatOptions = [.withInternetDateTime]
    if let d = iso.date(from: str) { return d }

    let dateOnly = DateFormatter()
    dateOnly.dateFormat = "yyyy-MM-dd"
    dateOnly.locale = Locale(identifier: "en_US_POSIX")
    if let d = dateOnly.date(from: str) { return d }

    throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot decode date: \(str)"
    )
}

func test() async {
    let url = URL(string: "\(restURL)/inventory_movements?select=*")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Data string: \(String(data: data, encoding: .utf8) ?? "")")
        let movements = try decoder.decode([InventoryMovement].self, from: data)
        print("Successfully decoded \(movements.count) movements")
    } catch {
        print("Error: \(error)")
    }
}

let group = DispatchGroup()
group.enter()
Task {
    await test()
    group.leave()
}
group.wait()
