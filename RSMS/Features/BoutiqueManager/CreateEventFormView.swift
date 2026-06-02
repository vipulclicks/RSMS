import SwiftUI

struct CreateEventFormView: View {
    @Bindable var viewModel: BoutiqueEventsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    @State private var title = ""
    @State private var date = Date()
    @State private var venue = ""
    @State private var type: ClientEventType = .trunkShow
    @State private var isSubmitting = false
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !venue.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isSubmitting
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Event Title", text: $title)
                    
                    Picker("Event Type", selection: $type) {
                        ForEach(ClientEventType.allCases, id: \.self) { eventType in
                            Text(eventType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized).tag(eventType)
                        }
                    }
                } header: {
                    Text("Basic Info")
                }
                
                Section {
                    DatePicker("Date & Time", selection: $date)
                        .datePickerStyle(.compact)
                    
                    TextField("Venue / Location", text: $venue)
                } header: {
                    Text("Scheduling & Location")
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RSMSTheme.danger)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        isSubmitting = true
                        Task {
                            if let storeId = appVM.currentStoreId {
                                await viewModel.addEvent(
                                    title: title,
                                    date: date,
                                    venue: venue,
                                    type: type,
                                    storeId: storeId,
                                    dataStore: appVM.dataStore,
                                    createdBy: appVM.currentUser?.id
                                )
                            }
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(!isFormValid)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .padding()
                        .background(Material.ultraThin)
                        .cornerRadius(8)
                }
            }
        }
    }
}
