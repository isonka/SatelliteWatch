import Foundation

enum LaunchDateRangeEncoder {
    static func queryBounds(
        start: Date?,
        end: Date?,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> (startUTC: String?, endUTC: String?) {
        var cal = calendar
        cal.timeZone = timeZone

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let startUTC: String?
        if let start {
            startUTC = formatter.string(from: cal.startOfDay(for: start))
        } else {
            startUTC = nil
        }

        let endUTC: String?
        if let end {
            let startOfEnd = cal.startOfDay(for: end)
            guard let nextDay = cal.date(byAdding: .day, value: 1, to: startOfEnd) else {
                return (startUTC, nil)
            }
            endUTC = formatter.string(from: nextDay.addingTimeInterval(-0.001))
        } else {
            endUTC = nil
        }

        return (startUTC, endUTC)
    }
    
    static func isWithinLocalDays(
        _ date: Date,
        start: Date?,
        end: Date?,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> Bool {
        var cal = calendar
        cal.timeZone = timeZone

        if let start, date < cal.startOfDay(for: start) {
            return false
        }

        if let end {
            let startOfEnd = cal.startOfDay(for: end)
            guard let endExclusive = cal.date(byAdding: .day, value: 1, to: startOfEnd) else {
                return true
            }
            if date >= endExclusive {
                return false
            }
        }

        return true
    }
}
