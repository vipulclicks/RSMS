//
//  PlanogramModels.swift
//  RSMS
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import CoreGraphics

// MARK: - Planogram
struct Planogram: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var storeId: UUID
    var name: String
    var section: String
    var imageUrl: String?
    var isCompliant: Bool
    var lastCheckedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var campaignId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case name
        case section
        case imageUrl = "image_url"
        case isCompliant = "is_compliant"
        case lastCheckedAt = "last_checked_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case campaignId = "campaign_id"
    }
}

// MARK: - Planogram Item
struct PlanogramItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var planogramId: UUID
    var productId: UUID
    var xPosition: Double
    var yPosition: Double
    var width: Double
    var height: Double
    var shelfZoneId: UUID?
    var skuLimit: Int
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case planogramId = "planogram_id"
        case productId = "product_id"
        case xPosition = "x_position"
        case yPosition = "y_position"
        case width
        case height
        case shelfZoneId = "shelf_zone_id"
        case skuLimit = "sku_limit"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Planogram Version
enum PlanogramStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case draft = "Draft"
    case published = "Published"
    case archived = "Archived"
}

struct PlanogramVersion: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var planogramId: UUID
    var status: PlanogramStatus
    var publishedAt: Date?
    var createdBy: UUID?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case planogramId = "planogram_id"
        case status
        case publishedAt = "published_at"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

// MARK: - Mock Models for UI
struct StoreProduct: Identifiable, Codable, Hashable, Transferable, Sendable {
    let id: UUID
    let name: String
    let sku: String
    let imageName: String
    let stockCount: Int
    let lowStockThreshold: Int
    
    init(id: UUID, name: String, sku: String, imageName: String, stockCount: Int, lowStockThreshold: Int = 5) {
        self.id = id
        self.name = name
        self.sku = sku
        self.imageName = imageName
        self.stockCount = stockCount
        self.lowStockThreshold = lowStockThreshold
    }
    
    init(product: Product, stockCount: Int) {
        self.id = product.id
        self.name = product.name
        self.sku = product.sku
        self.imageName = product.imageURL ?? "tshirt"
        self.stockCount = stockCount
        self.lowStockThreshold = 5
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
    
    var isLowStock: Bool { stockCount <= lowStockThreshold }
}

enum ZoneType: String, Codable, Hashable, Sendable {
    case table
    case wall
    case window
}

struct MerchandisingZone: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var storeId: UUID
    var name: String
    var type: ZoneType
    var xPosition: Double
    var yPosition: Double
    var width: Double
    var height: Double
    var totalCapacity: Int
    
    // UI Only
    var items: [StoreProduct] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case name
        case type
        case xPosition = "x_position"
        case yPosition = "y_position"
        case width
        case height
        case totalCapacity = "total_capacity"
    }
    
    var frame: CGRect {
        CGRect(x: xPosition, y: yPosition, width: width, height: height)
    }
    
    var fillPercentage: Int {
        if totalCapacity == 0 { return 0 }
        return Int((Double(items.count) / Double(totalCapacity)) * 100)
    }
    
    init(id: UUID, storeId: UUID, name: String, type: ZoneType, xPosition: Double, yPosition: Double, width: Double, height: Double, totalCapacity: Int, items: [StoreProduct] = []) {
        self.id = id
        self.storeId = storeId
        self.name = name
        self.type = type
        self.xPosition = xPosition
        self.yPosition = yPosition
        self.width = width
        self.height = height
        self.totalCapacity = totalCapacity
        self.items = items
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        storeId = try container.decode(UUID.self, forKey: .storeId)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ZoneType.self, forKey: .type)
        xPosition = try container.decode(Double.self, forKey: .xPosition)
        yPosition = try container.decode(Double.self, forKey: .yPosition)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
        totalCapacity = try container.decode(Int.self, forKey: .totalCapacity)
        items = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(storeId, forKey: .storeId)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(xPosition, forKey: .xPosition)
        try container.encode(yPosition, forKey: .yPosition)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(totalCapacity, forKey: .totalCapacity)
    }
}
