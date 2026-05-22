// CuratedCart.swift
import Foundation

struct CuratedCart: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let items: [UniversalCartItem]
}
