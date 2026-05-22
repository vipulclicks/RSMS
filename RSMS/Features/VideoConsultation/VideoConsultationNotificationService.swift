import Foundation
import UserNotifications

enum ConsultationNotificationEvent {
    case scheduled(Appointment, clientName: String)
    case updated(Appointment, clientName: String)
    case cancelled(Appointment, clientName: String)
    case reminder(Appointment, clientName: String)

    var title: String {
        switch self {
        case .scheduled: return "Video Consultation Scheduled"
        case .updated: return "Video Consultation Rescheduled"
        case .cancelled: return "Video Consultation Cancelled"
        case .reminder: return "Video Consultation Reminder"
        }
    }

    var body: String {
        switch self {
        case .scheduled(let appt, let name):
            return "Scheduled with \(name) on \(appt.dateTime.formatted())."
        case .updated(let appt, let name):
            return "Rescheduled with \(name) to \(appt.dateTime.formatted())."
        case .cancelled(_, let name):
            return "Consultation with \(name) was cancelled."
        case .reminder(let appt, let name):
            return "Your consultation with \(name) starts soon at \(appt.dateTime.formatted(date: .omitted, time: .shortened))."
        }
    }

    var identifier: String {
        switch self {
        case .scheduled(let appt, _): return "consultation-scheduled-\(appt.id)"
        case .updated(let appt, _): return "consultation-updated-\(appt.id)"
        case .cancelled(let appt, _): return "consultation-cancelled-\(appt.id)"
        case .reminder(let appt, _): return "consultation-reminder-\(appt.id)"
        }
    }
}

final class VideoConsultationNotificationService {
    static let shared = VideoConsultationNotificationService()
    private init() {}

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        do {
            let granted = try await center.requestAuthorization(options: options)
            print("[NotificationService] Permission granted: \(granted)")
        } catch {
            print("[NotificationService] Error requesting permission: \(error)")
        }
    }

    func handleEvent(_ event: ConsultationNotificationEvent) async {
        await scheduleLocalNotification(event: event)
        await simulateCustomerNotification(event: event)
        postInAppBanner(event: event)
    }

    func cancelReminders(for appointment: Appointment) {
        let identifiers = [
            "consultation-reminder-\(appointment.id)-local",
            "consultation-scheduled-\(appointment.id)-local",
            "consultation-updated-\(appointment.id)-local"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("[NotificationService] 🗑 Cancelled pending notifications for appointment \(appointment.id)")
    }

    private func scheduleLocalNotification(event: ConsultationNotificationEvent) async {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = .default

        let trigger: UNNotificationTrigger
        switch event {
        case .reminder(let appt, _):
            let calendar = Calendar.current
            let hours = appt.reminderTimingHours
            if let reminderDate = calendar.date(byAdding: .hour, value: -hours, to: appt.dateTime),
               reminderDate > Date() {
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            } else {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            }
        default:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: event.identifier + "-local",
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func simulateCustomerNotification(event: ConsultationNotificationEvent) async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        switch event {
        case .scheduled(let appt, let name):
            print("[NotificationService] 📧 Email sent to customer: '\(name)' — Consultation scheduled on \(appt.dateTime.formatted()). Video link: \(appt.videoLink ?? "To be shared")")
        case .updated(let appt, let name):
            print("[NotificationService] 📧 Email sent to customer: '\(name)' — Consultation rescheduled to \(appt.dateTime.formatted()).")
        case .cancelled(_, let name):
            print("[NotificationService] 📧 Email sent to customer: '\(name)' — Consultation cancelled.")
        case .reminder(let appt, let name):
            print("[NotificationService] 📱 SMS sent to customer: '\(name)' — Reminder: your consultation starts at \(appt.dateTime.formatted(date: .omitted, time: .shortened)). Link: \(appt.videoLink ?? "")")
        }
    }

    private func postInAppBanner(event: ConsultationNotificationEvent) {
        NotificationCenter.default.post(
            name: Notification.Name("VideoConsultationNotification"),
            object: nil,
            userInfo: [
                "title": event.title,
                "message": event.body
            ]
        )
    }
}
