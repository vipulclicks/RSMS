import SwiftUI
import Combine

struct FaceTimeVideoConsultationSheet: View {
    let appointment: Appointment
    let client: ClientProfile?
    let viewModel: AppointmentViewModel
    var consultationManager: VideoConsultationManager
    let onDismiss: () -> Void

    @Environment(DataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var callDurationSeconds = 0
    @State private var consultationNotes = ""
    @State private var showEndConfirmation = false
    @State private var showNotesEditor = false
    @State private var appeared = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var formattedDuration: String {
        let mins = callDurationSeconds / 60
        let secs = callDurationSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        ZStack {
            // Dark elegant background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FaceTime Companion")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(client?.fullName ?? "Client")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Text(formattedDuration)
                        .font(.system(.title3).weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding()
                .background(.ultraThinMaterial)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Client Info Card
                        if let client = client {
                            clientInfoCard(client)
                        }
                        
                        // FaceTime Return Button
                        Button {
                            // Try to reopen FaceTime via URL scheme or standard switch
                            if let url = URL(string: "facetime://") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "video.fill")
                                Text("Return to FaceTime")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Notes Section
                        notesSection
                    }
                    .padding(.vertical, 24)
                }
                
                // Bottom Controls
                HStack(spacing: 40) {
                    Spacer()
                    
                    VStack {
                        Button {
                            showNotesEditor.toggle()
                        } label: {
                            Image(systemName: "square.and.pencil").accessibilityLabel("Edit")
                                .font(.title)
                                .frame(width: 64, height: 64)
                                .background(Color.white.opacity(0.2))
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                        }
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    VStack {
                        Button {
                            showEndConfirmation = true
                        } label: {
                            Image(systemName: "phone.down.fill").accessibilityLabel("End Call")
                                .font(.title)
                                .frame(width: 72, height: 72)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                        }
                        Text("End Consult")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 20)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
            }
        }
        .onReceive(timer) { _ in
            callDurationSeconds += 1
        }
        .onAppear {
            if !appeared {
                appeared = true
                if let existingNotes = appointment.notes {
                    consultationNotes = existingNotes
                }
            }
        }
        .sheet(isPresented: $showNotesEditor) {
            NavigationStack {
                TextEditor(text: $consultationNotes)
                    .padding()
                    .navigationTitle("Consultation Notes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showNotesEditor = false
                                Task { await saveNotes() }
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("End Consultation?", isPresented: $showEndConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("End", role: .destructive) {
                Task {
                    await endConsultation()
                }
            }
        } message: {
            Text("This will mark the appointment as completed and close the companion overlay.")
        }
    }
    
    @ViewBuilder
    private func clientInfoCard(_ client: ClientProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.white.opacity(0.8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.fullName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Tier: \(client.vipTier.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            }
            
            Divider().background(.white.opacity(0.2))
            
            if let config = appointment.decodedFaceTimeConfig {
                HStack {
                    Image(systemName: "video")
                        .foregroundStyle(.gray)
                    Text("FaceTime: \(config.contact)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                
                if let notes = config.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meeting Notes:")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Notes")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button("Edit") {
                    showNotesEditor = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.blue)
            }
            
            Text(consultationNotes.isEmpty ? "No notes yet..." : consultationNotes)
                .font(.subheadline)
                .foregroundStyle(consultationNotes.isEmpty ? .white.opacity(0.5) : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func saveNotes() async {
        let updated = Appointment(
            id: appointment.id,
            clientId: appointment.clientId,
            associateId: appointment.associateId,
            storeId: appointment.storeId,
            dateTime: appointment.dateTime,
            durationMinutes: appointment.durationMinutes,
            type: appointment.type,
            status: appointment.status,
            reminderSentAt: appointment.reminderSentAt,
            videoLink: appointment.videoLink,
            notes: consultationNotes.isEmpty ? nil : consultationNotes,
            createdAt: appointment.createdAt,
            reminderTimingHours: appointment.reminderTimingHours,
            reminderChannel: appointment.reminderChannel,
            reminderStatus: appointment.reminderStatus,
            reminderError: appointment.reminderError
        )
        try? await viewModel.updateAppointment(updated)
    }
    
    private func endConsultation() async {
        let updated = Appointment(
            id: appointment.id,
            clientId: appointment.clientId,
            associateId: appointment.associateId,
            storeId: appointment.storeId,
            dateTime: appointment.dateTime,
            durationMinutes: appointment.durationMinutes,
            type: appointment.type,
            status: .completed,
            reminderSentAt: appointment.reminderSentAt,
            videoLink: appointment.videoLink,
            notes: consultationNotes.isEmpty ? nil : consultationNotes,
            createdAt: appointment.createdAt,
            reminderTimingHours: appointment.reminderTimingHours,
            reminderChannel: appointment.reminderChannel,
            reminderStatus: appointment.reminderStatus,
            reminderError: appointment.reminderError
        )
        try? await viewModel.updateAppointment(updated)
        
        consultationManager.activeAppointment = nil
        consultationManager.showFaceTimeCompanion = false
        dismiss()
        onDismiss()
    }
}
