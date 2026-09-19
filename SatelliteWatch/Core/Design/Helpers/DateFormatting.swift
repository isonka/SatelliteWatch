import Foundation

enum DateFormatting {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        return formatter
    }()

    static func display(date: Date, precision: DatePrecision? = nil) -> String {
        switch precision {
        case .hour, .day, .none:
            return displayFormatter.string(from: date)
        case .month:
            return monthFormatter.string(from: date)
        case .quarter, .half, .year:
            return yearFormatter.string(from: date)
        }
    }

    static func dayOnly(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }
}
