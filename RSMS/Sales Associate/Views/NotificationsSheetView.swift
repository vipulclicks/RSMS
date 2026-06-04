import SwiftUI

struct NotificationsSheetView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                let myNotifications = appViewModel.dataStore.appNotifications
                    .filter { $0.recipientId == appViewModel.currentUser?.id && !$0.isRead }
                    .sorted(by: { $0.createdAt > $1.createdAt })
                
                if myNotifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.largeTitle)
                            .foregroundStyle(RSMSTheme.textTertiary)
                        Text("No Notifications")
                            .font(.headline)
                            .foregroundStyle(RSMSTheme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(myNotifications) { notification in
                            NotificationRow(notification: notification)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let notification = myNotifications[index]
                                appViewModel.dataStore.appNotifications.removeAll(where: { $0.id == notification.id })
                                Task {
                                    try? await appViewModel.dataStore.deleteNotification(id: notification.id)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.primary)
                }
            }
            .onDisappear {
                if let currentUser = appViewModel.currentUser {
                    let unreadNotifications = appViewModel.dataStore.appNotifications
                        .filter { $0.recipientId == currentUser.id && !$0.isRead }
                    for notif in unreadNotifications {
                        Task {
                            try? await appViewModel.dataStore.markNotificationAsRead(id: notif.id)
                        }
                    }
                }
            }
            .task {
                // Fetch latest notifications, sourcing requests, and stock items from Supabase
                try? await appViewModel.dataStore.fetchAppNotifications()
                try? await appViewModel.dataStore.fetchInventorySourcingRequests()
                if let storeId = appViewModel.currentUser?.storeId {
                    try? await appViewModel.dataStore.fetchStockItems(storeId: storeId)
                }
                
                // Synthesize local notifications from the fetched sourcing requests
                if let currentUser = appViewModel.currentUser {
                    let sourcingRequests = appViewModel.dataStore.inventorySourcingRequests
                        .filter { $0.salesAssociateId == currentUser.id }
                    
                    for req in sourcingRequests {
                        let title: String
                        let message: String
                        
                        switch req.status {
                        case .stockFound:
                            title = "Stock Located"
                            message = "Stock for '\(req.productName)' has been located at another store."
                        case .transferInitiated:
                            title = "Transfer Initiated"
                            message = "A transfer for '\(req.productName)' has been initiated."
                        case .inTransit:
                            title = "Item In Transit"
                            message = "'\(req.productName)' is now in transit to your store."
                        case .received:
                            title = "Item Received at Store"
                            message = "'\(req.productName)' has been received at your store."
                        case .available:
                            title = "Item Available in Catalog"
                            message = "Requested item '\(req.productName)' is now available in inventory. You can add it to client carts."
                        case .cancelled:
                            title = "Sourcing Request Cancelled"
                            message = "The sourcing request for '\(req.productName)' has been cancelled."
                        default:
                            continue
                        }
                        
                        // Check if this specific notification already exists locally or remotely
                        let exists = appViewModel.dataStore.appNotifications.contains { notification in
                            notification.recipientId == currentUser.id &&
                            notification.relatedEntityId == req.id &&
                            notification.title == title
                        }
                        
                        if !exists {
                            let synthesized = AppNotification(
                                id: UUID(),
                                recipientId: currentUser.id,
                                title: title,
                                message: message,
                                type: .sourcingRequest,
                                relatedEntityId: req.id,
                                isRead: false,
                                createdAt: req.createdAt // backdate or use current
                            )
                            appViewModel.dataStore.appNotifications.append(synthesized)
                        }
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    @Environment(AppViewModel.self) private var appViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(notification.isRead ? RSMSTheme.surfaceSecondary : RSMSTheme.primary)
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(notification.title).accessibilityAddTraits(.isHeader)
                    .font(.subheadline.weight(notification.isRead ? .regular : .semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                
                Text(notification.message)
                    .font(.footnote)
                    .foregroundStyle(RSMSTheme.textSecondary)
                
                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
        }
        .padding(.vertical, 8)
        .onTapGesture {
            if !notification.isRead {
                Task {
                    try? await appViewModel.dataStore.markNotificationAsRead(id: notification.id)
                }
            }
        }
    }
}
