import SwiftUI

struct NotificationsSheetView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()
                
                let myNotifications = appViewModel.dataStore.appNotifications
                    .filter { $0.recipientId == appViewModel.currentUser?.id }
                    .sorted(by: { $0.createdAt > $1.createdAt })
                
                if myNotifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
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
            .task {
                // Fetch latest notifications and stock items from Supabase
                try? await appViewModel.dataStore.fetchAppNotifications()
                if let storeId = appViewModel.currentUser?.storeId {
                    try? await appViewModel.dataStore.fetchStockItems(storeId: storeId)
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
                Text(notification.title)
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
