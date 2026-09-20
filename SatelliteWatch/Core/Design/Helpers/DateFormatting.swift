import Foundation

enum DateFormatting {
    static func display(date: Date, precision: DatePrecision? = nil) -> String {
        switch precision {
        case .hour:
            date.formatted(date: .abbreviated, time: .shortened)
        case .day, nil:
            dayOnly(date)
        case .month:
            date.formatted(.dateTime.month(.abbreviated).year())
        case .quarter, .half, .year:
            date.formatted(.dateTime.year())
        }
    }

    static func dayOnly(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
