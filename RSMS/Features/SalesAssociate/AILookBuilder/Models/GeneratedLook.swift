//
//  GeneratedLook.swift
//  RSMS
//

import Foundation

enum Occasion: String, CaseIterable, Identifiable {
    case wedding = "Wedding"
    case formal = "Formal"
    case casual = "Casual"
    case party = "Party"
    
    var id: String { rawValue }
}

struct GeneratedLook: Identifiable, Hashable {
    let id: UUID
    let occasion: Occasion
    let products: [Product]
    let name: String
    
    var totalPrice: Double {
        products.reduce(0) { $0 + $1.price }
    }
    
    init(id: UUID = UUID(), occasion: Occasion, products: [Product], name: String) {
        self.id = id
        self.occasion = occasion
        self.products = products
        self.name = name
    }
}
