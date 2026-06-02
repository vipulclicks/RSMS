import SwiftUI

struct EditEventFormView: View {
    let event: ClientEvent
    @Bindable var viewModel: BoutiqueEventsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    
    @State private var title: String
    @State private var date: Date
    @State private var venue: String
    @State private var type: ClientEventType
    @State private var isSubmitting = false
    
    init(event: ClientEvent, viewModel: BoutiqueEventsViewModel) {
        self.event = event
        self.viewModel = viewModel
        _title = State(initialValue: event.title)
        _date = State(initialValue: event.date)
        _venue = State(initialValue: event.location ?? "")
        _type = State(initialValue: event.type)
    }
    
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
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RSMSTheme.danger)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSubmitting = true
                        Task {
                            let updatedEvent = ClientEvent(
                                id: event.id,
                                storeId: event.storeId,
                                title: title,
                                description: event.description,
                                type: type,
                                date: date,
                                endDate: event.endDate,
                                capacity: event.capacity,
                                location: venue,
                                createdBy: event.createdBy,
                                createdAt: event.createdAt
                            )
                            await viewModel.updateEvent(updatedEvent, dataStore: appVM.dataStore)
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
