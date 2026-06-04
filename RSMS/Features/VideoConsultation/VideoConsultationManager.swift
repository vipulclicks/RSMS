import SwiftUI
import Observation

@Observable
final class VideoConsultationManager {
    var showFaceTimeCompanion: Bool = false
    var activeAppointment: Appointment?
    var showFaceTimeError: Bool = false
    var errorMessage: String = ""

    func startVideoConsultation(for appointment: Appointment) {
        guard appointment.type == .video else {
            showError("This appointment is not a video consultation.")
            return
        }
        
        guard let config = appointment.decodedFaceTimeConfig else {
            showError("No FaceTime configuration found for this appointment.")
            return
        }
        
        let contact = config.contact.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !contact.isEmpty else {
            showError("FaceTime contact is empty.")
            return
        }
        
        // Build FaceTime URL
        let urlString: String
        if contact.contains("@") {
            urlString = "facetime://\(contact)"
        } else {
            // Strip non-digits for phone numbers
            let digits = contact.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            urlString = "facetime://\(digits)"
        }
        
        guard let url = URL(string: urlString) else {
            showError("Invalid FaceTime contact format.")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { [weak self] success in
                if success {
                    DispatchQueue.main.async {
                        self?.activeAppointment = appointment
                        self?.showFaceTimeCompanion = true
                    }
                } else {
                    self?.showError("Failed to open FaceTime. Ensure FaceTime is set up on this device.")
                }
            }
        } else {
            showError("FaceTime is not available on this device.")
        }
    }
    
    static func generateFaceTimeLink(for appointmentId: UUID) -> String {
        return "facetime://RSMS_\(appointmentId.uuidString.prefix(8))"
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showFaceTimeError = true
        }
    }
}

// MARK: - View Extension for Error Alert
extension View {
    func videoConsultationAlert(manager: Bindable<VideoConsultationManager>) -> some View {
        self.alert("FaceTime Error", isPresented: manager.showFaceTimeError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(manager.wrappedValue.errorMessage)
        }
    }
}
