//
//  LoginViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class LoginViewModel {

    // MARK: - Types

    struct RoleInfo {
        let icon: String
        let userName: String
        let description: String
    }

    // MARK: - Public

    func roleInfo(for role: UserRole) -> RoleInfo {
        switch role {
        case .boutiqueManager:
            return RoleInfo(
                icon: "building.columns.fill",
                userName: "Sophie Martin",
                description: "Dashboard, staff scheduling & store operations"
            )
        case .salesAssociate:
            return RoleInfo(
                icon: "person.crop.circle.fill",
                userName: "Lucas Dubois",
                description: "Clienteling, appointments & remote selling"
            ) 
        case .inventoryController:
            return RoleInfo(
                icon: "shippingbox.fill",
                userName: "Emma Leroy",
                description: "RFID stock management & tracking"
            )
        }
    }
}
