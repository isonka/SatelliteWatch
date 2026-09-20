import Foundation

enum DateFormatting {
    static func display(
        date: Date,
        precision: DatePrecision? = nil,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        switch precision {
        case .hour:
            date.formatted(
                Date.FormatStyle(
                    date: .abbreviated,
                    time: .shortened,
                    locale: locale,
                    timeZone: timeZone
                )
            )
        case .day, nil:
            dayOnly(date, locale: locale, timeZone: timeZone)
        case .month:
            date.formatted(
                Date.FormatStyle(locale: locale, timeZone: timeZone)
                    .month(.abbreviated)
                    .year()
            )
        case .quarter, .half, .year:
            date.formatted(
                Date.FormatStyle(locale: locale, timeZone: timeZone).year()
            )
        }
    }

    static func dayOnly(
        _ date: Date,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        date.formatted(
            Date.FormatStyle(
                date: .abbreviated,
                time: .omitted,
                locale: locale,
                timeZone: timeZone
            )
        )
    }
}
