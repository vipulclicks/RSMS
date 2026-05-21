//
//  ClientelingViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class ClientelingViewModel {

    // MARK: - Data
    // TODO: Replace mock data with Supabase fetch
    private(set) var client: ClientProfile = .preview
    private(set) var anniversary: ClientAnniversary = .preview
    private(set) var wishlist: WishlistItem = .preview
    private(set) var products: [Product] = Product.all

    // MARK: - Computed

    var wishlistProduct: Product? {
        products.first(where: { $0.id == wishlist.productId })
    }

    // MARK: - Formatting

    func formattedDate(_ date: Date) -> String {
        RSMSDateFormatter.dayMonth.string(from: date)
    }

    func tierColor(_ tier: VIPTier) -> Color {
        switch tier {
        case .standard: return RSMSTheme.textSecondary
        case .silver:   return Color(red: 192/255, green: 192/255, blue: 192/255)
        case .gold:     return RSMSTheme.primary
        case .platinum: return Color(red: 176/255, green: 196/255, blue: 222/255)
        case .prive:    return RSMSTheme.danger
        }
    }
}
