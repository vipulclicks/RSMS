//
//  DateFormatters.swift
//  RSMS
//

import Foundation

enum RSMSDateFormatter {
    static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        return f
    }()

    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()
    
    static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        return f
    }()

    static func timeAgo(from date: Date) -> String {
        let mins = Int(-date.timeIntervalSinceNow / 60)
        if mins < 60 { return "\(mins)m ago" }
        return "\(mins / 60)h ago"
    }
}
