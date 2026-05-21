//
//  AppointmentRemoteSellingViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class AppointmentRemoteSellingViewModel {
    
    // MARK: - Data
    // TODO: Replace mock data with Supabase fetch
    private(set) var appointment: Appointment = .preview
    private(set) var curatedCart: UniversalCart = .previewCurated
    private(set) var curatedItem: UniversalCartItem = .previewCuratedItem
    private(set) var client: ClientProfile = .preview
    private(set) var products: [Product] = Product.all

    // MARK: - Computed
    var cartProduct: Product? {
        products.first(where: { $0.id == curatedItem.productId })
    }

    // MARK: - Formatting
    func formattedDate(_ date: Date) -> String {
        return RSMSDateFormatter.dateTime.string(from: date)
    }

    func appointmentStatusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled:  return RSMSTheme.info
        case .confirmed:  return RSMSTheme.success
        case .inProgress: return RSMSTheme.warning
        case .completed:  return RSMSTheme.textSecondary
        case .cancelled:  return RSMSTheme.danger
        case .noShow:     return RSMSTheme.danger
        }
    }

    func cartStatusColor(_ status: CartStatus) -> Color {
        switch status {
        case .draft:     return RSMSTheme.textSecondary
        case .shared:    return RSMSTheme.info
        case .viewed:    return RSMSTheme.warning
        case .converted: return RSMSTheme.success
        case .expired:   return RSMSTheme.danger
        case .active, .completed, .abandoned: return RSMSTheme.textSecondary
        }
    }
}
